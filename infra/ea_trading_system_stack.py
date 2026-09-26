import re
from pathlib import Path

import aws_cdk as cdk
from aws_cdk import (
    Duration,
    RemovalPolicy,
    Stack,
    aws_apigatewayv2 as apigwv2,
    aws_cloudwatch as cloudwatch,
    aws_cloudwatch_actions as cloudwatch_actions,
    aws_dynamodb as dynamodb,
    aws_iam as iam,
    aws_lambda as lambda_,
    aws_logs as logs,
    aws_s3 as s3,
    aws_sns as sns,
    aws_sns_subscriptions as sns_subscriptions,
)
from constructs import Construct

from config import EnvironmentConfig, validate_timeout_budget

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
SAFE_EA_ID_RE = re.compile(r"^[A-Za-z0-9._-]{1,64}$")


def _context_bool(value: object, default: bool, name: str) -> bool:
    if value is None:
        return default
    text = str(value).lower()
    if text not in {"true", "false"}:
        raise ValueError(f"{name} is invalid")
    return text == "true"


def _context_int(value: object, default: int, name: str, minimum: int, maximum: int) -> int:
    if value is None:
        return default
    try:
        number = int(str(value))
    except ValueError as exc:
        raise ValueError(f"{name} is invalid") from exc
    if not minimum <= number <= maximum:
        raise ValueError(f"{name} must be between {minimum} and {maximum}")
    return number


class EaTradingSystemStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, *, config: EnvironmentConfig, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        prefix = f"ea-trading-system-{config.name}"
        validate_timeout_budget(config)
        removal = RemovalPolicy.RETAIN if config.retain_data else RemovalPolicy.DESTROY

        table = dynamodb.Table(
            self, "DecisionTable",
            table_name=f"{prefix}-decisions",
            partition_key=dynamodb.Attribute(name="pk", type=dynamodb.AttributeType.STRING),
            sort_key=dynamodb.Attribute(name="sk", type=dynamodb.AttributeType.STRING),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            encryption=dynamodb.TableEncryption.AWS_MANAGED,
            time_to_live_attribute="ttl",
            point_in_time_recovery_specification=dynamodb.PointInTimeRecoverySpecification(
                point_in_time_recovery_enabled=config.point_in_time_recovery,
            ),
            removal_policy=removal,
        )
        table.add_global_secondary_index(
            index_name="candidate-index",
            partition_key=dynamodb.Attribute(name="gsi1pk", type=dynamodb.AttributeType.STRING),
            sort_key=dynamodb.Attribute(name="gsi1sk", type=dynamodb.AttributeType.STRING),
            projection_type=dynamodb.ProjectionType.ALL,
        )

        artifact_bucket = s3.Bucket(
            self, "ArtifactBucket",
            bucket_name=None,
            encryption=s3.BucketEncryption.S3_MANAGED,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            enforce_ssl=True,
            versioned=True,
            lifecycle_rules=[s3.LifecycleRule(noncurrent_version_expiration=Duration.days(90))],
            removal_policy=removal,
            auto_delete_objects=not config.retain_data,
        )

        source_path = str(Path(__file__).resolve().parents[1] / "services" / "decision_api" / "src")
        model_key = self.node.try_get_context("ml_model_key") or "models/USDJPY/H1/baseline-v1/model.json"
        model_sha256 = self.node.try_get_context("ml_model_sha256") or ""
        llm_provider = self.node.try_get_context("llm_provider") or ""
        llm_model = self.node.try_get_context("llm_model") or ""
        metric_namespace = "EaTradingSystem"
        metrics_enabled = str(self.node.try_get_context("metrics_enabled") or "true").lower() == "true"
        enable_dashboard = str(self.node.try_get_context("enable_dashboard") or "false").lower() == "true"
        log_level = str(self.node.try_get_context("log_level") or config.log_level).upper()
        llm_shadow_mode = str(self.node.try_get_context("llm_shadow_mode") or "true").lower()
        if llm_shadow_mode not in {"true", "false"}:
            raise ValueError("llm_shadow_mode is invalid")
        if log_level not in {"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"}:
            raise ValueError("log_level is invalid")
        secret_cache_ttl_seconds = _context_int(
            self.node.try_get_context("secret_cache_ttl_seconds"), config.secret_cache_ttl_seconds,
            "secret_cache_ttl_seconds", 0, 3_600,
        )
        heartbeat_alarm_enabled = _context_bool(
            self.node.try_get_context("heartbeat_alarm_enabled"), config.heartbeat_alarm_enabled,
            "heartbeat_alarm_enabled",
        )
        if config.require_alarm_email and not heartbeat_alarm_enabled:
            raise ValueError(f"heartbeat_alarm_enabled cannot be disabled in {config.name}")
        heartbeat_stale_minutes = _context_int(
            self.node.try_get_context("heartbeat_stale_minutes"), config.heartbeat_stale_minutes,
            "heartbeat_stale_minutes", 2, 60,
        )
        heartbeat_ea_ids = [
            value.strip() for value in str(self.node.try_get_context("heartbeat_ea_ids") or "trend-ea-v1").split(",")
            if value.strip()
        ]
        if not 1 <= len(heartbeat_ea_ids) <= 10 or len(set(heartbeat_ea_ids)) != len(heartbeat_ea_ids) \
                or any(not SAFE_EA_ID_RE.fullmatch(value) for value in heartbeat_ea_ids):
            raise ValueError("heartbeat_ea_ids is invalid")
        alarm_email = str(self.node.try_get_context("alarm_email") or "").strip()
        if alarm_email and not EMAIL_RE.fullmatch(alarm_email):
            raise ValueError("alarm_email is invalid")
        if config.require_alarm_email and not alarm_email:
            raise ValueError(f"alarm_email is required for {config.name}")
        decision_function = lambda_.Function(
            self, "DecisionFunction",
            function_name=f"{prefix}-decision-api",
            runtime=lambda_.Runtime.PYTHON_3_12,
            architecture=lambda_.Architecture.ARM_64,
            handler="decision_api.handler.lambda_handler",
            code=lambda_.Code.from_asset(source_path),
            memory_size=config.lambda_memory_mb,
            timeout=Duration.seconds(config.lambda_timeout_seconds),
            tracing=lambda_.Tracing.ACTIVE,
            environment={
                "ENVIRONMENT": config.name,
                "TABLE_NAME": table.table_name,
                "ARTIFACT_BUCKET": artifact_bucket.bucket_name,
                "MAX_CLOCK_SKEW_SECONDS": "60",
                "RESPONSE_TTL_SECONDS": "30",
                "DECISION_DEADLINE_SECONDS": str(config.decision_deadline_seconds),
                "SECRET_CACHE_TTL_SECONDS": str(secret_cache_ttl_seconds),
                "LOG_LEVEL": log_level,
                "METRICS_ENABLED": str(metrics_enabled).lower(),
                "METRIC_NAMESPACE": metric_namespace,
                "ML_MODEL_KEY": model_key,
                "ML_MODEL_SHA256": model_sha256,
                "ML_MIN_WIN_PROBABILITY": "0.60",
                "ML_MIN_EXPECTED_RETURN": "0.0",
                "LLM_PROVIDER": llm_provider,
                "LLM_MODEL": llm_model,
                "LLM_PROMPT_VERSION": "trade-filter-v1",
                "LLM_TIMEOUT_SECONDS": str(config.llm_timeout_seconds),
                "LLM_DEADLINE_RESERVE_SECONDS": str(config.llm_deadline_reserve_seconds),
                "LLM_TEMPERATURE": "0",
                "LLM_SHADOW_MODE": llm_shadow_mode,
            },
        )
        table.grant_read_write_data(decision_function)
        artifact_bucket.grant_read(decision_function)
        decision_function.add_to_role_policy(iam.PolicyStatement(
            actions=["ssm:GetParameter"],
            resources=[f"arn:{self.partition}:ssm:{self.region}:{self.account}:parameter/ea-trading-system/{config.name}/credentials/*"],
        ))

        telemetry_function = lambda_.Function(
            self, "TelemetryFunction",
            function_name=f"{prefix}-trade-events",
            runtime=lambda_.Runtime.PYTHON_3_12,
            architecture=lambda_.Architecture.ARM_64,
            handler="decision_api.telemetry_handler.lambda_handler",
            code=lambda_.Code.from_asset(source_path),
            memory_size=128,
            timeout=Duration.seconds(3),
            tracing=lambda_.Tracing.ACTIVE,
            environment={
                "ENVIRONMENT": config.name,
                "TABLE_NAME": table.table_name,
                "MAX_CLOCK_SKEW_SECONDS": "60",
                "SECRET_CACHE_TTL_SECONDS": str(secret_cache_ttl_seconds),
                "LOG_LEVEL": log_level,
                "METRICS_ENABLED": str(metrics_enabled).lower(),
                "METRIC_NAMESPACE": metric_namespace,
            },
        )
        table.grant_read_write_data(telemetry_function)
        telemetry_function.add_to_role_policy(iam.PolicyStatement(
            actions=["ssm:GetParameter"],
            resources=[f"arn:{self.partition}:ssm:{self.region}:{self.account}:parameter/ea-trading-system/{config.name}/credentials/*"],
        ))
        decision_function.add_to_role_policy(iam.PolicyStatement(
            actions=["ssm:GetParameter"],
            resources=[f"arn:{self.partition}:ssm:{self.region}:{self.account}:parameter/ea-trading-system/{config.name}/providers/*"],
        ))

        # EA稼働監視専用。取引判断・Telemetryと分離し、nonce保存と最終Heartbeat更新だけを行う。
        heartbeat_function = lambda_.Function(
            self, "HeartbeatFunction",
            function_name=f"{prefix}-heartbeats",
            runtime=lambda_.Runtime.PYTHON_3_12,
            architecture=lambda_.Architecture.ARM_64,
            handler="decision_api.heartbeat_handler.lambda_handler",
            code=lambda_.Code.from_asset(source_path),
            memory_size=128,
            timeout=Duration.seconds(3),
            tracing=lambda_.Tracing.ACTIVE,
            environment={
                "ENVIRONMENT": config.name,
                "TABLE_NAME": table.table_name,
                "MAX_CLOCK_SKEW_SECONDS": "60",
                "SECRET_CACHE_TTL_SECONDS": str(secret_cache_ttl_seconds),
                "HEARTBEAT_MONITORED_EA_IDS": ",".join(heartbeat_ea_ids),
                "LOG_LEVEL": log_level,
                "METRICS_ENABLED": str(metrics_enabled).lower(),
                "METRIC_NAMESPACE": metric_namespace,
            },
        )
        table.grant_write_data(heartbeat_function)
        heartbeat_function.add_to_role_policy(iam.PolicyStatement(
            actions=["ssm:GetParameter"],
            resources=[f"arn:{self.partition}:ssm:{self.region}:{self.account}:parameter/ea-trading-system/{config.name}/credentials/*"],
        ))

        retention = {
            14: logs.RetentionDays.TWO_WEEKS,
            30: logs.RetentionDays.ONE_MONTH,
            90: logs.RetentionDays.THREE_MONTHS,
        }[config.log_retention_days]
        lambda_log_group = logs.LogGroup(
            self, "DecisionFunctionLogs",
            log_group_name=f"/aws/lambda/{decision_function.function_name}",
            retention=retention,
            removal_policy=removal,
        )
        telemetry_log_group = logs.LogGroup(
            self, "TelemetryFunctionLogs",
            log_group_name=f"/aws/lambda/{telemetry_function.function_name}",
            retention=retention,
            removal_policy=removal,
        )
        logs.LogGroup(
            self, "HeartbeatFunctionLogs",
            log_group_name=f"/aws/lambda/{heartbeat_function.function_name}",
            retention=retention,
            removal_policy=removal,
        )
        api_log_group = logs.LogGroup(
            self, "HttpApiAccessLogs",
            log_group_name=f"/aws/http-api/{prefix}",
            retention=retention,
            removal_policy=removal,
        )

        api = apigwv2.CfnApi(
            self, "DecisionHttpApi",
            name=f"{prefix}-http-api",
            protocol_type="HTTP",
            disable_execute_api_endpoint=False,
        )
        integration = apigwv2.CfnIntegration(
            self, "DecisionIntegration",
            api_id=api.ref,
            integration_type="AWS_PROXY",
            integration_uri=decision_function.function_arn,
            integration_method="POST",
            payload_format_version="2.0",
            timeout_in_millis=config.decision_integration_timeout_ms,
        )
        route = apigwv2.CfnRoute(
            self, "DecisionRoute",
            api_id=api.ref,
            route_key="POST /v1/trade-decisions",
            target=cdk.Fn.join("/", ["integrations", integration.ref]),
        )
        telemetry_integration = apigwv2.CfnIntegration(
            self, "TelemetryIntegration",
            api_id=api.ref,
            integration_type="AWS_PROXY",
            integration_uri=telemetry_function.function_arn,
            integration_method="POST",
            payload_format_version="2.0",
            timeout_in_millis=3_000,
        )
        telemetry_route = apigwv2.CfnRoute(
            self, "TelemetryRoute",
            api_id=api.ref,
            route_key="POST /v1/trade-events",
            target=cdk.Fn.join("/", ["integrations", telemetry_integration.ref]),
        )
        heartbeat_integration = apigwv2.CfnIntegration(
            self, "HeartbeatIntegration",
            api_id=api.ref,
            integration_type="AWS_PROXY",
            integration_uri=heartbeat_function.function_arn,
            integration_method="POST",
            payload_format_version="2.0",
            timeout_in_millis=3_000,
        )
        heartbeat_route = apigwv2.CfnRoute(
            self, "HeartbeatRoute",
            api_id=api.ref,
            route_key="POST /v1/heartbeats",
            target=cdk.Fn.join("/", ["integrations", heartbeat_integration.ref]),
        )
        stage = apigwv2.CfnStage(
            self, "DefaultStage",
            api_id=api.ref,
            stage_name="$default",
            auto_deploy=True,
            access_log_settings=apigwv2.CfnStage.AccessLogSettingsProperty(
                destination_arn=api_log_group.log_group_arn,
                format='{"requestId":"$context.requestId","routeKey":"$context.routeKey","status":"$context.status","responseLatency":"$context.responseLatency","integrationError":"$context.integrationErrorMessage"}',
            ),
            default_route_settings=apigwv2.CfnStage.RouteSettingsProperty(
                throttling_burst_limit=5,
                throttling_rate_limit=2,
            ),
        )
        stage.add_dependency(route)
        stage.add_dependency(telemetry_route)
        stage.add_dependency(heartbeat_route)
        decision_function.add_permission(
            "AllowHttpApiInvoke",
            principal=iam.ServicePrincipal("apigateway.amazonaws.com"),
            source_arn=f"arn:{self.partition}:execute-api:{self.region}:{self.account}:{api.ref}/*/*",
        )
        telemetry_function.add_permission(
            "AllowHttpApiInvoke",
            principal=iam.ServicePrincipal("apigateway.amazonaws.com"),
            source_arn=f"arn:{self.partition}:execute-api:{self.region}:{self.account}:{api.ref}/*/*",
        )
        heartbeat_function.add_permission(
            "AllowHttpApiInvoke",
            principal=iam.ServicePrincipal("apigateway.amazonaws.com"),
            source_arn=f"arn:{self.partition}:execute-api:{self.region}:{self.account}:{api.ref}/*/*",
        )

        alert_topic = sns.Topic(
            self, "OperationsAlertTopic",
            topic_name=f"{prefix}-operations-alerts",
            display_name=f"EA Trading System {config.name} alerts",
        )
        if alarm_email:
            alert_topic.add_subscription(sns_subscriptions.EmailSubscription(alarm_email))
        else:
            cdk.Annotations.of(self).add_warning_v2(
                "EaTradingSystem:AlarmEmailMissing",
                f"alarm_email is not set for {config.name}; alarms publish to SNS but no subscriber is notified.",
            )

        def custom_metric(name: str, service: str, statistic: str = "Sum") -> cloudwatch.Metric:
            return cloudwatch.Metric(
                namespace=metric_namespace,
                metric_name=name,
                dimensions_map={"Environment": config.name, "Service": service},
                statistic=statistic,
                period=Duration.minutes(5),
            )

        alarms: list[cloudwatch.Alarm] = []

        error_alarm = cloudwatch.Alarm(
            self, "LambdaErrorAlarm",
            alarm_name=f"{prefix}-lambda-errors",
            metric=decision_function.metric_errors(period=Duration.minutes(5)),
            threshold=1,
            evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        )
        alarms.append(error_alarm)
        alarms.append(cloudwatch.Alarm(
            self, "LambdaDurationAlarm",
            alarm_name=f"{prefix}-lambda-duration",
            metric=decision_function.metric_duration(period=Duration.minutes(5), statistic="p99"),
            threshold=int(config.decision_deadline_seconds * 1000),
            evaluation_periods=1,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        ))
        alarms.append(cloudwatch.Alarm(
            self, "TelemetryErrorAlarm",
            alarm_name=f"{prefix}-telemetry-errors",
            metric=telemetry_function.metric_errors(period=Duration.minutes(5)),
            threshold=1,
            evaluation_periods=1,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        ))
        alarms.append(cloudwatch.Alarm(
            self, "DecisionInternalErrorAlarm",
            alarm_name=f"{prefix}-decision-internal-errors",
            metric=custom_metric("DecisionInternalErrorCount", "DecisionApi"),
            threshold=1, evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        ))
        for metric_name, construct_name, alarm_suffix in (
            ("MlErrorCount", "MlErrorAlarm", "ml-errors"),
            ("LlmErrorCount", "LlmErrorAlarm", "llm-errors"),
        ):
            alarms.append(cloudwatch.Alarm(
                self, construct_name, alarm_name=f"{prefix}-{alarm_suffix}",
                metric=custom_metric(metric_name, "DecisionApi"), threshold=1,
                evaluation_periods=1,
                comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
                treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
            ))
        dynamo_errors = cloudwatch.MathExpression(
            expression="FILL(reads, 0) + FILL(writes, 0)", label="DynamoDB system errors",
            using_metrics={
                "reads": cloudwatch.Metric(
                    namespace="AWS/DynamoDB", metric_name="SystemErrors", statistic="Sum",
                    dimensions_map={"TableName": table.table_name, "Operation": "GetItem"},
                    period=Duration.minutes(5),
                ),
                "writes": cloudwatch.Metric(
                    namespace="AWS/DynamoDB", metric_name="SystemErrors", statistic="Sum",
                    dimensions_map={"TableName": table.table_name, "Operation": "PutItem"},
                    period=Duration.minutes(5),
                ),
            }, period=Duration.minutes(5),
        )
        alarms.append(cloudwatch.Alarm(
            self, "DynamoDbErrorAlarm", alarm_name=f"{prefix}-dynamodb-errors",
            metric=dynamo_errors, threshold=1, evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        ))
        alarms.append(cloudwatch.Alarm(
            self, "HeartbeatErrorAlarm",
            alarm_name=f"{prefix}-heartbeat-errors",
            metric=heartbeat_function.metric_errors(period=Duration.minutes(5)),
            threshold=1,
            evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        ))
        alarms.append(cloudwatch.Alarm(
            self, "HeartbeatInternalErrorAlarm",
            alarm_name=f"{prefix}-heartbeat-internal-errors",
            metric=custom_metric("HeartbeatInternalErrorCount", "HeartbeatApi"),
            threshold=1, evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        ))
        alarms.append(cloudwatch.Alarm(
            self, "TelemetryInternalErrorAlarm",
            alarm_name=f"{prefix}-telemetry-internal-errors",
            metric=custom_metric("TelemetryInternalErrorCount", "TelemetryApi"),
            threshold=1, evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        ))
        replay_expression = cloudwatch.MathExpression(
            expression="FILL(decision, 0) + FILL(telemetry, 0) + FILL(heartbeat, 0)", label="Replay rejected",
            using_metrics={
                "decision": custom_metric("SecurityReplayRejectedCount", "DecisionApi"),
                "telemetry": custom_metric("SecurityReplayRejectedCount", "TelemetryApi"),
                "heartbeat": custom_metric("SecurityReplayRejectedCount", "HeartbeatApi"),
            }, period=Duration.minutes(5),
        )
        alarms.append(cloudwatch.Alarm(
            self, "ReplayRejectedAlarm",
            alarm_name=f"{prefix}-replay-rejected",
            metric=replay_expression, threshold=config.replay_alarm_count,
            evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        ))
        api_5xx = cloudwatch.Metric(
            namespace="AWS/ApiGateway", metric_name="5xx", statistic="Sum",
            dimensions_map={"ApiId": api.ref, "Stage": "$default"}, period=Duration.minutes(5),
        )
        api_4xx = cloudwatch.Metric(
            namespace="AWS/ApiGateway", metric_name="4xx", statistic="Sum",
            dimensions_map={"ApiId": api.ref, "Stage": "$default"}, period=Duration.minutes(5),
        )
        alarms.append(cloudwatch.Alarm(
            self, "HttpApi5xxAlarm", alarm_name=f"{prefix}-http-5xx",
            metric=api_5xx, threshold=1, evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        ))
        throttles = cloudwatch.MathExpression(
            expression="FILL(decision, 0) + FILL(telemetry, 0) + FILL(heartbeat, 0)", label="Lambda throttles",
            using_metrics={
                "decision": decision_function.metric_throttles(period=Duration.minutes(5)),
                "telemetry": telemetry_function.metric_throttles(period=Duration.minutes(5)),
                "heartbeat": heartbeat_function.metric_throttles(period=Duration.minutes(5)),
            }, period=Duration.minutes(5),
        )
        alarms.append(cloudwatch.Alarm(
            self, "LambdaThrottleAlarm", alarm_name=f"{prefix}-lambda-throttles",
            metric=throttles, threshold=1, evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        ))
        for alarm in alarms:
            alarm.add_alarm_action(cloudwatch_actions.SnsAction(alert_topic))

        if heartbeat_alarm_enabled:
            for index, ea_id in enumerate(heartbeat_ea_ids):
                # 受信件数の欠損をBREACHINGとし、EA停止・ハング・通信断をstale_minutes分の連続欠損で検知する。
                heartbeat_alarm = cloudwatch.Alarm(
                    self, f"HeartbeatMissingAlarm{index}",
                    alarm_name=f"{prefix}-heartbeat-missing-{ea_id}",
                    alarm_description=f"No EA heartbeat for {heartbeat_stale_minutes} minutes (ea_id={ea_id}).",
                    metric=cloudwatch.Metric(
                        namespace=metric_namespace, metric_name="HeartbeatReceivedCount", statistic="Sum",
                        dimensions_map={"Environment": config.name, "Service": "HeartbeatApi", "EaId": ea_id},
                        period=Duration.minutes(1),
                    ),
                    threshold=1,
                    evaluation_periods=heartbeat_stale_minutes,
                    datapoints_to_alarm=heartbeat_stale_minutes,
                    comparison_operator=cloudwatch.ComparisonOperator.LESS_THAN_THRESHOLD,
                    treat_missing_data=cloudwatch.TreatMissingData.BREACHING,
                )
                heartbeat_alarm.add_alarm_action(cloudwatch_actions.SnsAction(alert_topic))
                heartbeat_alarm.add_ok_action(cloudwatch_actions.SnsAction(alert_topic))

        if enable_dashboard:
            dashboard = cloudwatch.Dashboard(
                self, "OperationsDashboard", dashboard_name=f"{prefix}-operations",
            )
            dashboard.add_widgets(
                cloudwatch.GraphWidget(
                    title="Decision outcomes", width=12,
                    left=[custom_metric("DecisionRequestCount", "DecisionApi"),
                          custom_metric("DecisionAllowCount", "DecisionApi"),
                          custom_metric("DecisionVetoCount", "DecisionApi")],
                ),
                cloudwatch.GraphWidget(
                    title="API latency", width=12,
                    left=[custom_metric("DecisionLatencyMs", "DecisionApi", "p99"),
                          custom_metric("TelemetryLatencyMs", "TelemetryApi", "p99")],
                ),
                cloudwatch.GraphWidget(
                    title="AWS service health", width=12,
                    left=[decision_function.metric_errors(), telemetry_function.metric_errors(), api_4xx, api_5xx],
                    right=[decision_function.metric_throttles(), telemetry_function.metric_throttles()],
                ),
                cloudwatch.LogQueryWidget(
                    title="ML / LLM outcomes", width=12,
                    log_group_names=[lambda_log_group.log_group_name],
                    query_string="fields outcome, ml_status, llm_status, reason_code | filter ispresent(outcome) | stats count() by outcome, ml_status, llm_status, reason_code",
                ),
                cloudwatch.GraphWidget(
                    title="EA heartbeats", width=12,
                    left=[custom_metric("HeartbeatReceivedCount", "HeartbeatApi"),
                          custom_metric("HeartbeatInternalErrorCount", "HeartbeatApi")],
                ),
                cloudwatch.LogQueryWidget(
                    title="Telemetry event outcomes", width=12,
                    log_group_names=[telemetry_log_group.log_group_name],
                    query_string="fields outcome, event_type, reason_code | filter ispresent(outcome) | stats count() by outcome, event_type, reason_code",
                ),
            )

        cdk.CfnOutput(self, "DecisionApiUrl", value=f"https://{api.ref}.execute-api.{self.region}.{self.url_suffix}/v1/trade-decisions")
        cdk.CfnOutput(self, "TelemetryApiUrl", value=f"https://{api.ref}.execute-api.{self.region}.{self.url_suffix}/v1/trade-events")
        cdk.CfnOutput(self, "HeartbeatApiUrl", value=f"https://{api.ref}.execute-api.{self.region}.{self.url_suffix}/v1/heartbeats")
        cdk.CfnOutput(self, "DecisionTableName", value=table.table_name)
        cdk.CfnOutput(self, "ArtifactBucketName", value=artifact_bucket.bucket_name)
        cdk.CfnOutput(self, "ErrorAlarmName", value=error_alarm.alarm_name)
        cdk.CfnOutput(self, "OperationsAlertTopicArn", value=alert_topic.topic_arn)
        # 通知先アドレス自体は出力せず、購読の有無だけを記録する。
        cdk.CfnOutput(self, "AlarmEmailSubscriptionConfigured", value=str(bool(alarm_email)).lower())
        cdk.CfnOutput(self, "HeartbeatAlarmEnabled", value=str(heartbeat_alarm_enabled).lower())
        cdk.CfnOutput(self, "CredentialParameterPrefix", value=f"/ea-trading-system/{config.name}/credentials/")
