# Project instructions

ถามก่อนทุกครั้งเมื่อข้อมูลไม่เพียงพอ — Ask before making a decision that depends on missing requirements.

Before making changes, read [README.md](README.md), all project documents in
[docs/](docs/), and the relevant existing source. Follow
[docs/CODING_RULES.md](docs/CODING_RULES.md). The current user's explicit scope
takes precedence over historical notes.

- Preserve the existing 11-table schema, SQL files, equipment/exercise seed,
  and approved demo Profile API contract unless a specific change is authorized.
- Never automatically run the baseline SQL: it starts with DROP DATABASE.
- Keep credentials in each machine's local `backend/.env`; do not print or
  commit them. Use `backend/.env.example` to explain configuration.
- Reuse an existing `.venv`. Only on a new clone without one, create a new
  environment on that machine; never copy a teammate's `.venv`.
- Run backend commands from the repository root. See
  [docs/TEAM_SETUP.md](docs/TEAM_SETUP.md) for a new machine.
- Consult [docs/ROADMAP.md](docs/ROADMAP.md) for status and evidence. Tasks 2.1
  and 2.2 have prior local acceptance; Tasks 2.3–2.5, workout logic and frontend
  remain unstarted. Agree on the next task's API scope before implementation.
- Keep database, isolated-test, HTTP, user-reported and historical evidence
  distinct. A new clone has not passed tests until checked on that machine.
- Update `docs/CHANGELOG.md` after completed work, including documentation;
  update `docs/ROADMAP.md` and affected documents when status or scope changes.
- Report changes and actual validation steps in Thai. Do not start another
  feature merely because the current task is complete.
