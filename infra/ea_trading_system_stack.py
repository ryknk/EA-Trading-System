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

from config import EnvironmentConfig


class EaTradingSystemStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, *, config: EnvironmentConfig, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        prefix = f"ea-trading-system-{config.name}"
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
                "LLM_TIMEOUT_SECONDS": "3.0",
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
            timeout_in_millis=5_000,
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

        alert_topic = sns.Topic(
            self, "OperationsAlertTopic",
            topic_name=f"{prefix}-operations-alerts",
            display_name=f"EA Trading System {config.name} alerts",
        )
        alarm_email = self.node.try_get_context("alarm_email")
        if alarm_email:
            alert_topic.add_subscription(sns_subscriptions.EmailSubscription(str(alarm_email)))

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
            threshold=4_000,
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
            self, "TelemetryInternalErrorAlarm",
            alarm_name=f"{prefix}-telemetry-internal-errors",
            metric=custom_metric("TelemetryInternalErrorCount", "TelemetryApi"),
            threshold=1, evaluation_periods=1,
            comparison_operator=cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
            treat_missing_data=cloudwatch.TreatMissingData.NOT_BREACHING,
        ))
        replay_expression = cloudwatch.MathExpression(
            expression="FILL(decision, 0) + FILL(telemetry, 0)", label="Replay rejected",
            using_metrics={
                "decision": custom_metric("SecurityReplayRejectedCount", "DecisionApi"),
                "telemetry": custom_metric("SecurityReplayRejectedCount", "TelemetryApi"),
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
            expression="FILL(decision, 0) + FILL(telemetry, 0)", label="Lambda throttles",
            using_metrics={
                "decision": decision_function.metric_throttles(period=Duration.minutes(5)),
                "telemetry": telemetry_function.metric_throttles(period=Duration.minutes(5)),
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
                cloudwatch.LogQueryWidget(
                    title="Telemetry event outcomes", width=12,
                    log_group_names=[telemetry_log_group.log_group_name],
                    query_string="fields outcome, event_type, reason_code | filter ispresent(outcome) | stats count() by outcome, event_type, reason_code",
                ),
            )

        cdk.CfnOutput(self, "DecisionApiUrl", value=f"https://{api.ref}.execute-api.{self.region}.{self.url_suffix}/v1/trade-decisions")
        cdk.CfnOutput(self, "TelemetryApiUrl", value=f"https://{api.ref}.execute-api.{self.region}.{self.url_suffix}/v1/trade-events")
        cdk.CfnOutput(self, "DecisionTableName", value=table.table_name)
        cdk.CfnOutput(self, "ArtifactBucketName", value=artifact_bucket.bucket_name)
        cdk.CfnOutput(self, "ErrorAlarmName", value=error_alarm.alarm_name)
        cdk.CfnOutput(self, "OperationsAlertTopicArn", value=alert_topic.topic_arn)
        cdk.CfnOutput(self, "CredentialParameterPrefix", value=f"/ea-trading-system/{config.name}/credentials/")
