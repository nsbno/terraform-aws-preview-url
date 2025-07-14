from datetime import datetime, timedelta

from pynamodb.attributes import UnicodeAttribute, UTCDateTimeAttribute
from pynamodb.models import Model

from preview_url_mapper.ports.preview_url_repository import PreviewUrlRepository


class DynamoDBPreviewUrlAdapter(PreviewUrlRepository):
    # us-east-1 for the same region as Lambda@Edge function
    def __init__(self, table_name: str, region='us-east-1') -> None:
        self.table_name = table_name
        self.region = region

        class PreviewUrlModel(Model):
            class Meta:
                table_name = self.table_name
                region = self.region

            domain = UnicodeAttribute(hash_key=True)
            pr_number = UnicodeAttribute()
            apprunner_host = UnicodeAttribute()
            timestamp = UTCDateTimeAttribute(default=datetime.now() + timedelta(days=7))

        self.PreviewUrlModel = PreviewUrlModel

    def get_preview_url(self, pr_number: str, domain: str) -> str:
        try:
            apprunner_host = self.PreviewUrlModel.get(hash_key=domain).apprunner_host
            return apprunner_host
        except self.PreviewUrlModel.DoesNotExist:
            print("Preview URL not found in DynamoDB for domain:", domain)
            raise ValueError(f"No preview URL found for domain: {domain}")
        except Exception as e:
            raise ValueError(f"Error: {str(e)}") from e
