import logging

from preview_url_mapper.adapters.dynamodb_adapter import DynamoDBPreviewUrlAdapter
from preview_url_mapper.core.usecases.api import HandleApiRequest
from preview_url_mapper.core.usecases.get_preview_url_by_domain import GetPreviewUrlByDomain
from preview_url_mapper.instrumentation import LoggingInstrumentation
from pythonjsonlogger import jsonlogger

# Configure a standard Python logger
logger = logging.getLogger(__name__)
handler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter()
handler.setFormatter(formatter)
logger.addHandler(handler)
logger.setLevel(logging.INFO)

# The rest of your code remains the same
logging_instrumentation = LoggingInstrumentation(logger=logger)

# Lambda@Edge functions for Cloudfront does not support environment variables,
preview_url_repository = DynamoDBPreviewUrlAdapter(table_name="platform-preview-url-mapper")
get_preview_url_by_domain = HandleApiRequest(
    get_preview_url_by_domain=GetPreviewUrlByDomain(preview_url_mapper=preview_url_repository, instrumentation=logging_instrumentation),
)

preview_url_handler = get_preview_url_by_domain.handler

