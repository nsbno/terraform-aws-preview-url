from pydantic import ConfigDict, BaseModel

from preview_url_mapper.instrumentation import LoggingInstrumentation
from preview_url_mapper.ports.preview_url_repository import PreviewUrlRepository


class GetPreviewUrlByDomain(BaseModel):
    model_config = ConfigDict(arbitrary_types_allowed=True)

    preview_url_mapper: PreviewUrlRepository
    instrumentation: LoggingInstrumentation

    def execute(self, domain: str, pr_id: str) -> str:
        if not pr_id.startswith("pr-"):
            self.instrumentation.failing_domain_name(domain=domain, pr_id=pr_id)
            raise ValueError("Domain must start with 'pr-'.")

        preview_url_host = self.preview_url_repository.get_preview_url(domain=domain, pr_id=pr_id)
        if not preview_url_host:
            self.instrumentation.does_not_exist(domain=domain, pr_id=pr_id)
            raise ValueError(f"No preview URL found for domain: {domain}")

        return preview_url_host
