import boto3

from preview_url_mapper.ports.preview_url_repository import PreviewUrlRepository


class DynamoDBPreviewUrlAdapter(PreviewUrlRepository):
    def __init__(
            self,
            table_name: str,
            region: str = 'us-east-1'
    ) -> None:
        self.dynamodb = boto3.resource('dynamodb', region_name=region)
        # SSM parameter is in the eu-west-1 region
        self.ssm_client = boto3.client('ssm', region_name="eu-west-1")
        self.response = self.ssm_client.get_parameter(
            Name=f"/__deployment__/applications/lambda-at-edge/preview-url-mapper/environment-account-id"
        )
        account_id = self.response['Parameter']['Value']

        self.table_arn = f"arn:aws:dynamodb:{region}:{account_id}:table/{table_name}"
        self.table = self.dynamodb.Table(name=self.table_arn)

    def get_preview_url(self, domain: str, pr_id: str) -> str:
        try:
            response = self.table.get_item(

                Key={
                    'domain': domain
                }
            )

            if 'Item' not in response:
                raise ValueError(f"No preview URL found for domain: {domain}")

            return response['Item']['apprunner_host']

        except self.dynamodb.meta.client.exceptions.ResourceNotFoundException:
            raise ValueError(f"No preview URL found for domain: {domain}")
        except Exception as e:
            raise ValueError(f"Error: {str(e)}") from e
