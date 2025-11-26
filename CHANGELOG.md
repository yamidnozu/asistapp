# Changelog

All notable changes to this project will be documented in this file.

## [1.0.7] - 2025-11-26
### Added
- Settings screen and persisted theme toggle (dark/light) available to all user roles.
- Navigation entry for Settings in the app shell and dashboards.

### Fixed
- Schedule (`horarios`) parsing: models (`Grupo`, `Materia`, `User`) made tolerant to nested partial objects returned by API; fixed deserialization issues.
- Created null-safety fixes across models and UI to handle missing fields in API responses.

### Changed
- Theme colors refactor to remove hard-coded white colors and support proper dark mode visuals.
- Internal improvements and refactors for code maintainability and theme consistency.

## [1.0.6] - Previous versions
- Smaller changes and fixes (see commits for details)
