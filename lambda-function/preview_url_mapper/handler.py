import os

from preview_url_mapper.adapters.dynamodb_adapter import DynamoDBPreviewUrlAdapter
from preview_url_mapper.core.usecases.api import HandleApiRequest
from preview_url_mapper.core.usecases.get_preview_url_by_domain import GetPreviewUrlByDomain

preview_url_repository = DynamoDBPreviewUrlAdapter(table_name=os.environ.get("PREVIEW_URL_MAPPER_TABLE_NAME"))
get_preview_url_by_domain = HandleApiRequest(
    get_preview_url_by_domain=GetPreviewUrlByDomain(preview_url_mapper=preview_url_repository)
)

