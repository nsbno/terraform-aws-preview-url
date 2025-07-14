from pydantic import ConfigDict, BaseModel

from preview_url_mapper.instrumentation import LoggingInstrumentation
from preview_url_mapper.ports.preview_url_repository import PreviewUrlRepository


class GetPreviewUrlByDomain(BaseModel):
    model_config = ConfigDict(arbitrary_types_allowed=True)

    preview_url_mapper: PreviewUrlRepository
    instrumentation: LoggingInstrumentation

    def execute(self, domain: str, pr_id: str) -> str:
        try:
            preview_url_host = self.preview_url_repository.get_preview_url(domain=domain, pr_id=pr_id)
        except Exception as e:
            self.instrumentation.does_not_exist(domain=domain, pr_id=pr_id, exception=e)
            raise ValueError(f"No preview URL found for domain: {domain}")

        return preview_url_host
