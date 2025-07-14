from logging import Logger

from pydantic import BaseModel, ConfigDict
from vy_lambda_tools.instrumentation import JsonLogger


class LoggingInstrumentation(BaseModel):
    model_config = ConfigDict(arbitrary_types_allowed=True)

    logger: JsonLogger | Logger

    def failing_domain_name(self, domain: str, pr_id: str) -> None:
        self.logger.error(
            f"Invalid domain name: {domain} or PR ID {pr_id} format. Does not start with 'pr-'"
        )

    def does_not_exist(self, domain: str, pr_id: str) -> None:
        self.logger.error(
            f"Preview URL with {domain} does not exist for PR ID: {pr_id}"
        )
