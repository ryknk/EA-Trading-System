import unittest

import aws_cdk as cdk
from aws_cdk.assertions import Annotations, Match, Template

from config import environment_config
from ea_trading_system_stack import EaTradingSystemStack


class StackTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        app = cdk.App()
        stack = EaTradingSystemStack(app, "test-stack", config=environment_config("dev"))
        cls.template = Template.from_stack(stack)

    def test_serverless_resources_and_exact_route(self) -> None:
        self.template.resource_count_is("AWS::ApiGatewayV2::Api", 1)
        self.template.resource_count_is("AWS::DynamoDB::Table", 1)
        self.template.resource_count_is("AWS::S3::Bucket", 1)
        self.template.resource_count_is("AWS::SNS::Topic", 1)
        self.template.has_resource_properties("AWS::ApiGatewayV2::Route", {
            "RouteKey": "POST /v1/trade-decisions",
        })
        self.template.has_resource_properties("AWS::ApiGatewayV2::Route", {
            "RouteKey": "POST /v1/trade-events",
        })
        self.template.has_resource_properties("AWS::DynamoDB::Table", {
            "BillingMode": "PAY_PER_REQUEST",
            "TimeToLiveSpecification": {"AttributeName": "ttl", "Enabled": True},
            "GlobalSecondaryIndexes": Match.array_with([Match.object_like({
                "IndexName": "candidate-index",
                "Projection": {"ProjectionType": "ALL"},
            })]),
        })

    def test_lambda_is_short_lived_arm_python_and_fail_safe_configured(self) -> None:
        self.template.has_resource_properties("AWS::Lambda::Function", {
            "Runtime": "python3.12",
            "Architectures": ["arm64"],
            "Timeout": 5,
            "MemorySize": 256,
            "Environment": {"Variables": Match.object_like({
                "ENVIRONMENT": "dev", "MAX_CLOCK_SKEW_SECONDS": "60",
                "RESPONSE_TTL_SECONDS": "30",
                "ML_MODEL_KEY": "models/USDJPY/H1/baseline-v1/model.json",
                "ML_MODEL_SHA256": "", "ML_MIN_WIN_PROBABILITY": "0.60",
                "ML_MIN_EXPECTED_RETURN": "0.0",
                "LLM_PROVIDER": "", "LLM_MODEL": "",
                "LLM_PROMPT_VERSION": "trade-filter-v1",
                "LLM_TIMEOUT_SECONDS": "3.0",
                "LLM_TEMPERATURE": "0",
                "METRICS_ENABLED": "true", "METRIC_NAMESPACE": "EaTradingSystem",
            })},
        })

    def test_telemetry_lambda_is_small_and_time_bounded(self) -> None:
        self.template.has_resource_properties("AWS::Lambda::Function", {
            "Runtime": "python3.12",
            "Architectures": ["arm64"],
            "Timeout": 3,
            "MemorySize": 128,
            "Environment": {"Variables": Match.object_like({
                "ENVIRONMENT": "dev",
            })},
        })

    def test_api_is_throttled_and_logs_are_bounded(self) -> None:
        self.template.has_resource_properties("AWS::ApiGatewayV2::Stage", {
            "StageName": "$default",
            "DefaultRouteSettings": {
                "ThrottlingBurstLimit": 5,
                "ThrottlingRateLimit": 2,
            },
        })
        self.template.has_resource_properties("AWS::Logs::LogGroup", {"RetentionInDays": 14})

    def test_caught_errors_security_and_throttles_have_notifying_alarms(self) -> None:
        # devはHeartbeat欠損Alarmを既定無効とするため、常設Alarmだけを数える。
        self.template.resource_count_is("AWS::CloudWatch::Alarm", 13)
        self.template.has_resource_properties("AWS::CloudWatch::Alarm", {
            "AlarmName": "ea-trading-system-dev-decision-internal-errors",
            "Threshold": 1,
            "TreatMissingData": "notBreaching",
            "Namespace": "EaTradingSystem",
            "MetricName": "DecisionInternalErrorCount",
            "Dimensions": Match.array_with([
                {"Name": "Environment", "Value": "dev"},
                {"Name": "Service", "Value": "DecisionApi"},
            ]),
            "AlarmActions": Match.any_value(),
        })
        self.template.has_resource_properties("AWS::CloudWatch::Alarm", {
            "AlarmName": "ea-trading-system-dev-replay-rejected", "Threshold": 3,
        })
        for suffix in ("ml-errors", "llm-errors", "dynamodb-errors"):
            self.template.has_resource_properties("AWS::CloudWatch::Alarm", {
                "AlarmName": f"ea-trading-system-dev-{suffix}", "Threshold": 1,
                "AlarmActions": Match.any_value(),
            })

    def test_every_alarm_notifies_the_operations_topic(self) -> None:
        topics = self.template.find_resources("AWS::SNS::Topic")
        self.assertEqual(1, len(topics))
        topic_id = next(iter(topics))
        alarms = self.template.find_resources("AWS::CloudWatch::Alarm")
        self.assertTrue(alarms)
        for name, alarm in alarms.items():
            self.assertEqual([{"Ref": topic_id}], alarm["Properties"].get("AlarmActions"), name)

    def test_heartbeat_route_lambda_and_alarms_are_separate_from_trading(self) -> None:
        self.template.has_resource_properties("AWS::ApiGatewayV2::Route", {"RouteKey": "POST /v1/heartbeats"})
        self.template.has_resource_properties("AWS::Lambda::Function", {
            "FunctionName": "ea-trading-system-dev-heartbeats",
            "Handler": "decision_api.heartbeat_handler.lambda_handler",
            "Timeout": 3, "MemorySize": 128,
            "Environment": {"Variables": Match.object_like({
                "HEARTBEAT_MONITORED_EA_IDS": "trend-ea-v1", "SECRET_CACHE_TTL_SECONDS": "300",
            })},
        })
        for suffix in ("heartbeat-errors", "heartbeat-internal-errors"):
            self.template.has_resource_properties("AWS::CloudWatch::Alarm", {
                "AlarmName": f"ea-trading-system-dev-{suffix}", "AlarmActions": Match.any_value(),
            })
        self.template.has_output("HeartbeatApiUrl", {})
        self.template.has_output("AlarmEmailSubscriptionConfigured", {"Value": "false"})

    def test_timeouts_leave_llm_room_before_ea_and_gateway_timeouts(self) -> None:
        self.template.has_resource_properties("AWS::Lambda::Function", {
            "FunctionName": "ea-trading-system-dev-decision-api",
            "Environment": {"Variables": Match.object_like({
                "DECISION_DEADLINE_SECONDS": "4.0", "LLM_TIMEOUT_SECONDS": "3.0",
                "LLM_DEADLINE_RESERVE_SECONDS": "0.5", "LLM_SHADOW_MODE": "true",
            })},
        })
        self.template.has_resource_properties("AWS::ApiGatewayV2::Integration", {
            "IntegrationUri": Match.any_value(), "TimeoutInMillis": 5000,
        })
        self.template.has_resource_properties("AWS::CloudWatch::Alarm", {
            "AlarmName": "ea-trading-system-dev-lambda-duration", "Threshold": 4000,
        })

    def test_dev_without_alarm_email_warns(self) -> None:
        app = cdk.App()
        stack = EaTradingSystemStack(app, "warn-stack", config=environment_config("dev"))
        warnings = Annotations.from_stack(stack).find_warning("*", Match.string_like_regexp("alarm_email is not set"))
        self.assertEqual(1, len(warnings))
        Template.from_stack(stack).resource_count_is("AWS::SNS::Subscription", 0)

    def test_production_requires_alarm_email_and_heartbeat_alarm(self) -> None:
        with self.assertRaisesRegex(ValueError, "alarm_email is required"):
            EaTradingSystemStack(cdk.App(), "prod-no-email", config=environment_config("production"))
        with self.assertRaisesRegex(ValueError, "heartbeat_alarm_enabled cannot be disabled"):
            EaTradingSystemStack(
                cdk.App(context={"alarm_email": "ops@example.invalid", "heartbeat_alarm_enabled": "false"}),
                "prod-no-heartbeat", config=environment_config("production"),
            )
        with self.assertRaisesRegex(ValueError, "alarm_email is invalid"):
            EaTradingSystemStack(cdk.App(context={"alarm_email": "not-an-email"}),
                                 "bad-email", config=environment_config("dev"))
        app = cdk.App(context={"alarm_email": "ops@example.invalid"})
        template = Template.from_stack(EaTradingSystemStack(app, "prod", config=environment_config("production")))
        template.has_resource_properties("AWS::SNS::Subscription", {"Protocol": "email"})
        template.has_output("AlarmEmailSubscriptionConfigured", {"Value": "true"})
        template.has_resource_properties("AWS::CloudWatch::Alarm", {
            "AlarmName": "ea-trading-system-production-heartbeat-missing-trend-ea-v1",
            "MetricName": "HeartbeatReceivedCount", "Namespace": "EaTradingSystem",
            "Dimensions": Match.array_with([{"Name": "EaId", "Value": "trend-ea-v1"}]),
            "Period": 60, "EvaluationPeriods": 5, "DatapointsToAlarm": 5, "Threshold": 1,
            "ComparisonOperator": "LessThanThreshold", "TreatMissingData": "breaching",
            "AlarmActions": Match.any_value(), "OKActions": Match.any_value(),
        })

    def test_heartbeat_alarm_threshold_and_targets_are_configurable(self) -> None:
        app = cdk.App(context={
            "heartbeat_alarm_enabled": "true", "heartbeat_stale_minutes": "10",
            "heartbeat_ea_ids": "trend-ea-v1,range-ea-v1",
        })
        template = Template.from_stack(EaTradingSystemStack(app, "hb", config=environment_config("dev")))
        template.resource_count_is("AWS::CloudWatch::Alarm", 15)
        template.has_resource_properties("AWS::CloudWatch::Alarm", {
            "AlarmName": "ea-trading-system-dev-heartbeat-missing-range-ea-v1", "EvaluationPeriods": 10,
        })
        for context in ({"heartbeat_stale_minutes": "1"}, {"heartbeat_ea_ids": "bad id"},
                        {"secret_cache_ttl_seconds": "3601"}, {"heartbeat_alarm_enabled": "yes"}):
            with self.assertRaises(ValueError):
                EaTradingSystemStack(cdk.App(context=context), "invalid", config=environment_config("dev"))

    def test_dashboard_is_opt_in_to_avoid_fixed_cost(self) -> None:
        self.template.resource_count_is("AWS::CloudWatch::Dashboard", 0)
        app = cdk.App(context={"enable_dashboard": "true"})
        stack = EaTradingSystemStack(app, "dashboard-stack", config=environment_config("dev"))
        Template.from_stack(stack).resource_count_is("AWS::CloudWatch::Dashboard", 1)


if __name__ == "__main__":
    unittest.main()
