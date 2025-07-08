from pydantic import BaseModel


class PreviewUrl(BaseModel):
    domain_name: str
    pr_id: str  # prefixed with 'pr-', e.g., 'pr-123'
    app_runner_domain: str
