# GitHub Copilot Instructions for WG-ShopSync

These instructions apply to all AI-assisted development and automation tasks in the `wg-shopsync` repository.

## 1. Authority of Documentation
- `docs/spec/` (Specification) and `docs/arch/` (Arc42 Architecture) are authoritative.
- All implementations must strictly conform to the functional requirements, data models (D1/D2), and architectural decisions (ADRs).
- Do not modify specification or architecture documents unless the implementation proves a genuine inconsistency or constraint that requires an approved architectural change.

## 2. Feature & Use Case Integrity
- Preserve existing use cases (UC-01 Registration, UC-02 Login, UC-03 Create WG, UC-04 Join WG, UC-05 Leave WG).
- Implement subsequent use cases (UC-06..UC-16) incrementally without breaking existing functionality or tests.

## 3. Git Workflow & Branches
- Use **Conventional Commits** (e.g. `feat(...)`, `fix(...)`, `chore(...)`, `test(...)`, `docs(...)`).
- One feature group / topic per branch (e.g., `feature/...`, `fix/...`).
- Never merge into `main` directly or perform direct pushes to `main`. Integration into `main` is done solely via reviewed Pull Requests.
- Do not rewrite history or perform force pushes unless explicitly directed.

## 4. Quality & Pre-Push Validation
Before committing and pushing any changes, always run and verify:
1. `dart format .` (or formatting check)
2. `flutter analyze` (must report 0 errors and 0 warnings)
3. `flutter test` (all tests must pass)
4. `git diff --check` (no whitespace or formatting violations)
Fix any failures before pushing.

## 5. Security & Firestore Rules
- **Deny by default**: All collections, documents, and fields not explicitly permitted must be denied.
- Validate authentication, resource ownership, WG membership (`isMember`), allowed field structures, and valid state transitions.
- Never weaken, bypass, or loosen Firestore Security Rules just to make client code work.
- Unimplemented use cases/subcollections must remain denied until their respective implementation and rules are ready.

## 6. Dependencies & Libraries
- Do not add new dependencies to `pubspec.yaml` unless strictly required and approved.
- Rely on standard Flutter and Dart libraries and the established project stack (`firebase_core`, `firebase_auth`, `cloud_firestore`).

## 7. Reviewability & Test Quality
- All AI-generated code, models, services, and widgets must remain clean, modular, reviewable, and covered by automated unit/widget tests.
- Maintain test doubles (e.g., fake services/repositories) under `app/test/support/` to allow isolated testing without live Firebase connections.
