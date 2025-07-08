import abc


class PreviewUrlRepository(abc.ABC):
    @abc.abstractmethod
    def get_preview_url(self, pr_number: int, domain: str) -> str:
        pass
