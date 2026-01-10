from pydantic import BaseModel


class User(BaseModel):
    id: str
    member_id: str | None = None
    name: str | None = None
    email: str | None = None

    class Config:
        from_attributes = True
