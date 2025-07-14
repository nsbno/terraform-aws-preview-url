import os

from vy_lambda_tools.instrumentation import JsonLogger

from preview_url_mapper.adapters.dynamodb_adapter import DynamoDBPreviewUrlAdapter
from preview_url_mapper.core.usecases.api import HandleApiRequest
from preview_url_mapper.core.usecases.get_preview_url_by_domain import GetPreviewUrlByDomain
from preview_url_mapper.instrumentation import LoggingInstrumentation

instrumentation = LoggingInstrumentation(logger=JsonLogger())

# Lambda@Edge functions for Cloudfront does not support environment variables,
preview_url_repository = DynamoDBPreviewUrlAdapter(table_name="preview-url-mapper")
get_preview_url_by_domain = HandleApiRequest(
    get_preview_url_by_domain=GetPreviewUrlByDomain(preview_url_mapper=preview_url_repository, instrumentation=instrumentation),
)

preview_url_handler = get_preview_url_by_domain.handler

