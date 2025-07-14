from pydantic import BaseModel
from vy_lambda_tools.instrumentation import JsonLogger


class LoggingInstrumentation(BaseModel):
    logger: JsonLogger

    def failing_domain_name(self, domain: str, pr_id: str) -> None:
        self.logger.error(
            "Invalid domain name or PR ID format. Does not start with 'pr-'",
            extra={"domain": domain, "pr_id": pr_id},
        )

    def does_not_exist(self, domain: str, pr_id: str) -> None:
        self.logger.error(
            "Preview URL does not exist for the given domain and PR ID",
            extra={"domain": domain, "pr_id": pr_id},
        )
