"""Load local configuration without printing credentials."""

import os
from dataclasses import dataclass, field
from pathlib import Path
from collections.abc import Mapping

from dotenv import dotenv_values


ENV_PATH = Path(__file__).resolve().parent / ".env"
DB_KEYS = ("DB_HOST", "DB_PORT", "DB_USER", "DB_PASSWORD", "DB_NAME")


class ConfigurationError(RuntimeError):
    """A safe error containing field names, never field values."""


@dataclass(frozen=True)
class Settings:
    host: str
    port: int
    user: str
    password: str = field(repr=False)
    database: str

    @classmethod
    def load(
        cls,
        env_path: Path = ENV_PATH,
        environ: Mapping[str, str] | None = None,
    ) -> "Settings":
        # Disable ${...} expansion so literal passwords are preserved.
        values = dict(dotenv_values(env_path, encoding="utf-8-sig", interpolate=False))
        environment = os.environ if environ is None else environ
        values.update({key: environment[key] for key in DB_KEYS if key in environment})
        missing = [
            key for key in DB_KEYS
            if values.get(key) is None
            or (key != "DB_PASSWORD" and not str(values[key]).strip())
        ]
        if missing:
            raise ConfigurationError("Missing database configuration: " + ", ".join(missing))
        try:
            port = int(str(values["DB_PORT"]))
        except ValueError:
            raise ConfigurationError("DB_PORT must be an integer from 1 to 65535.") from None
        if not 1 <= port <= 65535:
            raise ConfigurationError("DB_PORT must be an integer from 1 to 65535.")
        return cls(
            host=str(values["DB_HOST"]).strip(),
            port=port,
            user=str(values["DB_USER"]).strip(),
            password=str(values["DB_PASSWORD"]),
            database=str(values["DB_NAME"]).strip(),
        )
