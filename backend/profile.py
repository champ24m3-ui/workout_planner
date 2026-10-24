"""Demo-only profile API against the existing schema; no user/schema creation."""

from typing import Annotated, Literal

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, ConfigDict, Field, model_validator
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError


DEMO_EMAIL = "demo@gmail.com"
PROFILE_FIELDS = (
    "fitness_level", "primary_goal", "workout_location",
    "days_per_week", "minutes_per_session",
)
PROFILE_SELECT = text(
    "SELECT profile_id, user_id, fitness_level, primary_goal, workout_location, "
    "days_per_week, minutes_per_session FROM user_profiles WHERE user_id = :user_id"
)

FitnessLevel = Literal["Beginner", "Intermediate", "Advanced"]
PrimaryGoal = Literal["Build muscle", "Lose fat", "General fitness"]
WorkoutLocation = Literal["Home", "Gym"]
WorkoutDays = Annotated[int, Field(strict=True, ge=1, le=7)]
SessionMinutes = Annotated[int, Field(strict=True, gt=0, le=2147483647)]


class ProfilePatch(BaseModel):
    model_config = ConfigDict(extra="forbid")

    fitness_level: FitnessLevel | None = None
    primary_goal: PrimaryGoal | None = None
    workout_location: WorkoutLocation | None = None
    days_per_week: WorkoutDays | None = None
    minutes_per_session: SessionMinutes | None = None

    @model_validator(mode="after")
    def require_nonempty_values(self):
        if not self.model_fields_set:
            raise ValueError("Supply at least one profile field.")
        if any(getattr(self, name) is None for name in self.model_fields_set):
            raise ValueError("Supplied profile fields must not be null.")
        return self


class ProfileResponse(BaseModel):
    profile_id: int
    user_id: int
    # Read existing SQL values faithfully, including legacy text and NULLs.
    fitness_level: str | None
    primary_goal: str | None
    workout_location: str | None
    days_per_week: int | None
    minutes_per_session: int | None


router = APIRouter(prefix="/profile", tags=["Demo profile"])


def demo_user_id(connection, *, lock=False):
    query = "SELECT user_id FROM users WHERE email = :email"
    if lock:
        query += " FOR UPDATE"
    user_id = connection.execute(text(query), {"email": DEMO_EMAIL}).scalar_one_or_none()
    if user_id is None:
        raise HTTPException(status_code=404, detail="Demo user not found.")
    return user_id


def read_profile(connection, user_id):
    return connection.execute(PROFILE_SELECT, {"user_id": user_id}).mappings().one_or_none()


def database_unavailable():
    return HTTPException(status_code=503, detail="Database unavailable.")


@router.get("", response_model=ProfileResponse)
def get_profile(request: Request):
    try:
        with request.app.state.database_engine.connect() as connection:
            user_id = demo_user_id(connection)
            profile = read_profile(connection, user_id)
            if profile is None:
                raise HTTPException(status_code=404, detail="Profile not found.")
            return ProfileResponse.model_validate(dict(profile))
    except SQLAlchemyError:
        raise database_unavailable() from None


@router.patch("", response_model=ProfileResponse)
def patch_profile(payload: ProfilePatch, request: Request):
    changes = payload.model_dump(exclude_unset=True)
    try:
        # Lock the existing demo user to serialize updates and first creation.
        # begin() commits on success and rolls back on any exception, including
        # validation/readback or commit failures. No other user's rows are used.
        with request.app.state.database_engine.begin() as connection:
            user_id = demo_user_id(connection, lock=True)
            existing = read_profile(connection, user_id)
            fields = [name for name in PROFILE_FIELDS if name in changes]
            parameters = {"user_id": user_id, **changes}
            if existing is None:
                missing = [name for name in PROFILE_FIELDS if name not in changes]
                if missing:
                    raise HTTPException(
                        status_code=422,
                        detail={
                            "message": "Creating a profile requires all five fields.",
                            "missing_fields": missing,
                        },
                    )
                columns = ", ".join(["user_id", *fields])
                values = ", ".join(":" + name for name in ["user_id", *fields])
                statement = text(f"INSERT INTO user_profiles ({columns}) VALUES ({values})")
            else:
                # Column names come only from the fixed allowlist, never input.
                assignments = ", ".join(f"{name} = :{name}" for name in fields)
                statement = text(
                    f"UPDATE user_profiles SET {assignments} WHERE user_id = :user_id"
                )
            connection.execute(statement, parameters)
            latest = read_profile(connection, user_id)
            response = ProfileResponse.model_validate(dict(latest))
        return response
    except SQLAlchemyError:
        raise database_unavailable() from None
