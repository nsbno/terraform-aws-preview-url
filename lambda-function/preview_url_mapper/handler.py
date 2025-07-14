from vy_lambda_tools.instrumentation import JsonLogger

from preview_url_mapper.adapters.dynamodb_adapter import DynamoDBPreviewUrlAdapter
from preview_url_mapper.core.usecases.api import HandleApiRequest
from preview_url_mapper.core.usecases.get_preview_url_by_domain import GetPreviewUrlByDomain
from preview_url_mapper.instrumentation import LoggingInstrumentation

try:
    logger = JsonLogger()
    logging_instrumentation = LoggingInstrumentation(logger=logger)
except Exception as e:
    # Fallback to a basic logger if JsonLogger fails to initialize
    import logging
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)
    logging_instrumentation = LoggingInstrumentation(logger=logger)

# Lambda@Edge functions for Cloudfront does not support environment variables,
preview_url_repository = DynamoDBPreviewUrlAdapter(table_name="preview-url-mapper")
get_preview_url_by_domain = HandleApiRequest(
    get_preview_url_by_domain=GetPreviewUrlByDomain(preview_url_mapper=preview_url_repository, instrumentation=logging_instrumentation),
)

preview_url_handler = get_preview_url_by_domain.handler

