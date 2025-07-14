from pydantic import BaseModel

from preview_url_mapper.core.usecases.get_preview_url_by_domain import GetPreviewUrlByDomain


class HandleApiRequest(BaseModel):
    get_preview_url_by_domain: GetPreviewUrlByDomain

    def handler(self, event, context):
        request = event['Records'][0]['cf']['request']
        headers = request['headers']
        host = headers['host'][0]['value']  # e.g., pr-123.example.com
        subdomain = host.split('.')[0]  # 'pr-123'

        try:
            apprunner_host = self.get_preview_url_by_domain.execute(domain=host, pr_id=subdomain)
        except ValueError as e:
            # Return 404 if subdomain not found
            return {
                'status': '404',
                'statusDescription': 'Not Found',
                'body': f'error: {str(e)}',
            }

        # Set the origin to the App Runner service
        request['origin'] = {
            'custom': {
                'domainName': apprunner_host,
                'port': 443,
                'protocol': 'https',
                'path': '',
                'sslProtocols': ['TLSv1.2'],
                'readTimeout': 5,
                'keepaliveTimeout': 5,
                'customHeaders': {}
            }
        }
        # Forward the correct Host header
        request['headers']['host'] = [{'key': 'host', 'value': apprunner_host}]

        return request
