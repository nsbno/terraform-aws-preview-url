import abc


class PreviewUrlRepository(abc.ABC):
    @abc.abstractmethod
    def get_preview_url(self, domain: str, pr_id: str) -> str:
        pass
