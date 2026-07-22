#!/usr/bin/env python3
import aws_cdk as cdk

from config import environment_config
from ea_trading_system_stack import EaTradingSystemStack

app = cdk.App(outdir="cdk.out")
environment_name = app.node.try_get_context("environment") or "dev"
config = environment_config(environment_name)

EaTradingSystemStack(
    app,
    f"ea-trading-system-{environment_name}",
    config=config,
    description=f"EA trading system serverless decision API ({environment_name})",
)
app.synth()
