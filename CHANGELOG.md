# Changelog

## Unreleased

## 1.5.0 (2026-05-28)

### New Features

- feat: Add `json-include` whitelist of dot-separated paths to keep in the JSON export.
- feat: Add `json-exclude` blacklist of dot-separated paths to drop from the JSON export.
- feat: Add `json-exclude-sensitive` option (default `true`) to redact host filesystem paths (`quarto.doc.input_file`, `quarto.doc.output_file`, `quarto.project.directory`, `quarto.project.output_directory`, `pandoc.PANDOC_SCRIPT_FILE`).
- feat: Add `json-warn-on-server` option (default `true`) to warn when JSON export is enabled in CI or server contexts.
- feat: Document the JSON export schema in the README and example.

### Bug Fixes

- fix: Coerce boolean metadata robustly, accepting raw Lua booleans, Pandoc `MetaBool`, and the strings `'true'`/`'false'` (case-insensitive).
- fix: Reset module-level configuration state at the start of each `Meta` pass to prevent cross-document leakage in batch renders.

### Documentation

- docs: Document the JSON export schema, filtering options, and example coverage for the new filter behaviour.

## 1.4.1 (2026-04-15)

### Refactoring

- refactor: Synchronise shared modules (`logging.lua`, `string.lua`) with canonical versions.

## 1.4.0 (2026-03-23)

### Refactoring

- refactor: Replace monolithic `utils.lua` with focused modules (`string.lua`, `logging.lua`, `metadata.lua`, `pandoc-helpers.lua`, `html.lua`, `paths.lua`, `colour.lua`).

## 1.3.0 (2026-02-21)

### New Features

- feat: Add _schema.yml for configuration validation and IDE support (#14).

### Bug Fixes

- fix: Correct json option type from string to boolean/string union.

## 1.2.1 (2026-02-11)

### Bug Fixes

- fix: Update copyright year.
- fix: Use british english spelling.

## 1.2.0 (2025-10-25)

### New Features

- feat: Enhance example document metadata and formatting.

### Refactoring

- refactor: Use lua modules and enhance error handling (#11).

## 1.1.0 (2025-10-12)

### New Features

- feat: Add JSON export functionality for lua-env metadata (#9).

## 1.0.3 (2025-04-05)

### New Features

- feat: Add CITATION file for project citation.

## 1.0.2 (2024-06-28)

### Bug Fixes

- fix: FORMAT is a string (#6).
- fix: Switch to deploy from GitHub Actions (#5).

## 1.0.1 (2024-02-03)

### New Features

- feat: Format quarto.version.

### Bug Fixes

- fix: Add internal license for extension.

## 1.0.0 (2023-01-24)

### New Features

- feat: Expose pandoc variables.

### Bug Fixes

- fix: Better description.
- fix: Rm duplicated functions.

### Refactoring

- refactor: Rename variable to be more general.
- refactor: Rename functions.

### Documentation

- docs: Add examples for Pandoc lua env as meta.
- docs: Add exposed variables/objects.
- docs: Improve readme.
- docs: Add raw shortcodes.

### Style

- style: No empty lines in license.
