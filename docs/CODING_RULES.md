# Coding rules for Codex

## Required starting context

Read README.md and every document under docs/ before changing the project. Inspect the relevant original SQL and current implementation files. State the requested task and its boundaries. The final SQL controls database facts; documentation explains them. If documentation and SQL disagree, flag the conflict and correct the documentation rather than silently changing the database. The current user's explicit instructions take precedence over earlier chat suggestions.

**ถามก่อนทุกครั้งเมื่อข้อมูลไม่เพียงพอ — Ask before proceeding whenever information is insufficient.** Ask a focused question before any implementation decision that depends on missing requirements. Do not present an assumption as an agreed requirement or fill gaps with new entities.

## Schema and seed preservation

- Keep the 11-table schema unchanged unless the user explicitly authorizes a specific schema change. This includes column names/types, NULL behavior, defaults, checks, unique keys, and delete actions.
- Do not add entities such as progress_analysis, authentication tables, or an exercise/equipment junction table on your own.
- Preserve every current equipment/exercise master value and mapping. Do not rename, recategorize, deduplicate, reseed, or substitute equipment based on intuition.
- Resolve seed references by stable lookup values; do not rely on IDs starting at 1 or remaining the same after a reset.
- Distinguish system exercises (NULL creator) from custom exercises; do not expose another user's custom rows in candidate queries. Clarify the source's provenance ambiguity before implementing user deletion.
- Never run the opening DROP DATABASE against existing data without explicit authorization. Do not run the baseline SQL, ORM create_all, schema reset, or automatic seeding during normal application startup.

## Work scope and completion

- Use README.md and ROADMAP.md for current progress and its supporting evidence. Task 2.1 is complete for the local foundation scope; Task 2.2 demo Profile API is implemented; the user supplied an 18-test OK summary; live GET /profile returned 200 with demo data supplied by the user; Codex verified live PATCH/readback and invalid-value rejection; the user-run seven-check MySQL suite passed with a saved JSON report; Task 2.2 is complete for local demo scope; Tasks 2.3–2.5 are not started. Do not reuse old experimental backend files as accepted completed work.
- Implement only the task authorized by the user. Creating documentation does not authorize backend implementation. Do not automatically progress from Task 2.1 to 2.2.
- Distinguish proposed API design from an approved contract, SQL capability from application behavior, and source completion from successful runtime validation.
- Do not invent dependency versions, credentials, allowed-value enums, generation rules, load units, or deployment details. Ask when the relevant information is needed.

## Future backend implementation requirements

- Map SQL types, nullable fields, defaults, and constraints faithfully. Use decimal-aware handling for stored decimals and explicit validation for dates and ranges.
- Preserve NULL target_weight on first use and NULL actual_weight when applicable. Never replace NULL with zero merely for convenience.
- Permit ad hoc logs with NULL program_exercise_id and sessions with NULL program_id.
- Validate ownership and relationship consistency in application operations; an existing FK alone does not prove the session/program/exercise belongs to the selected user.
- Make compound writes atomic with commit/rollback handling; do not partially save programs or sessions on errors.
- Store secrets outside version control. Supply placeholders in .env.example, never actual passwords. Do not request the user's password in chat or log connection secrets.
- Do not treat the demo's NULL password_hash as an authenticated account or implement unrestricted user selection as production authentication without an agreed identity model.

## Verification and handoff

Use checks appropriate to the requested change. For database-affecting work, use an approved isolated test database; preserve the seed and inspect the relevant constraints and relationship behavior. A MySQL PASS claim needs actual saved results. Task 1.5 result rows labeled FAIL must fail acceptance even if the SQL client exits successfully.

After each task, report changed files, resulting behavior, checks actually run, and material limitations. Update ROADMAP.md and CHANGELOG.md when status changes are supported. Do not claim browser, API, database, or production validation from static document inspection.

Before closing each task, including documentation-only work, update CHANGELOG.md with the date, scope, changed files, actual checks, and remaining limitations. Review affected project documents for consistency and correct stale current-state statements. Update README.md, PROJECT_SPEC.md, and ROADMAP.md when the task changes their scope, development path, or progress information. Preserve clearly labeled historical records and evidence limits; a documentation update does not establish new runtime acceptance.
