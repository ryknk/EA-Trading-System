import unittest

import aws_cdk as cdk
from aws_cdk.assertions import Match, Template

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
        self.template.resource_count_is("AWS::CloudWatch::Alarm", 11)
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

    def test_dashboard_is_opt_in_to_avoid_fixed_cost(self) -> None:
        self.template.resource_count_is("AWS::CloudWatch::Dashboard", 0)
        app = cdk.App(context={"enable_dashboard": "true"})
        stack = EaTradingSystemStack(app, "dashboard-stack", config=environment_config("dev"))
        Template.from_stack(stack).resource_count_is("AWS::CloudWatch::Dashboard", 1)


if __name__ == "__main__":
    unittest.main()
