"""Connection management only; no schema creation, migrations or seeding."""

from sqlalchemy import URL, create_engine
from sqlalchemy.engine import Engine

from backend.config import Settings


def create_database_engine(settings: Settings) -> Engine:
    url = URL.create(
        drivername="mysql+pymysql",
        username=settings.user,
        password=settings.password,
        host=settings.host,
        port=settings.port,
        database=settings.database,
        query={"charset": "utf8mb4"},
    )
    return create_engine(
        url,
        pool_pre_ping=True,
        pool_size=5,
        max_overflow=0,
        pool_timeout=5,
        hide_parameters=True,
        echo=False,
        connect_args={"connect_timeout": 5, "read_timeout": 5, "write_timeout": 5},
    )
