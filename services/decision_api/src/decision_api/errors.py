class ApiError(Exception):
    """クライアントへ安全に返せる API エラー。"""

    def __init__(self, status_code: int, code: str, message: str) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.code = code
        self.message = message


class ConditionalWriteFailed(Exception):
    """一意制約に相当する条件付き書込みの失敗。"""

