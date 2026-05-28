# Lua Environment Extension For Quarto

`lua-env` is an extension for [Quarto](https://quarto.org) to provide access to LUA objects as metadata.

## Installation

```bash
quarto add mcanouil/quarto-lua-env@1.5.0
```

This will install the extension under the `_extensions` subdirectory.

If you're using version control, you will want to check in this directory.

## Usage

Add the following to your YAML header:

- Old (<1.8.21):

  ```yml
  filters:
    - quarto
    - lua-env
  ```

- New (>=1.8.21):

  ```yml
  filters:
    - path: lua-env
      at: post-quarto
  ```

This will give you access to the `quarto` and several Pandoc LUA internal objects using any of the below shortcodes:

```markdown
{{< lua-env quarto.doc.input_file >}}

{{< meta lua-env.quarto.doc.input_file >}}
```

LUA objects currently available as metadata:

```yaml
lua-env:
  quarto: "quarto"
  pandoc:
    PANDOC_STATE: "PANDOC_STATE"
    FORMAT: "FORMAT"
    PANDOC_READER_OPTIONS: "PANDOC_READER_OPTIONS"
    PANDOC_WRITER_OPTIONS: "PANDOC_WRITER_OPTIONS"
    PANDOC_VERSION: "PANDOC_VERSION"
    PANDOC_API_VERSION: "PANDOC_API_VERSION"
    PANDOC_SCRIPT_FILE: "PANDOC_SCRIPT_FILE"
```

See [Pandoc LUA API - Global Variables](https://pandoc.org/lua-filters.html#global-variables) for more information about Pandoc global variables.

## JSON Export

You can export the `lua-env` metadata to a JSON file by configuring the `json` option.

By default, no JSON file is written (`json: false`).

To enable JSON export with the default filename:

```yaml
extensions:
  lua-env:
    json: true  # Exports to "lua-env.json"
```

To specify a custom file path:

```yaml
extensions:
  lua-env:
    json: "custom-path.json"  # Exports to "custom-path.json"
```

The boolean toggle accepts raw YAML booleans (`true`, `false`), their quoted string forms (`"true"`, `"false"`), and a path string for custom filenames.

### JSON export schema

The exported JSON has two top-level keys, `pandoc` and `quarto`, that mirror the live Pandoc/Quarto Lua objects:

```json
{
  "pandoc": {
    "FORMAT": "html",
    "PANDOC_API_VERSION": "1.23",
    "PANDOC_VERSION": "3.6.3",
    "PANDOC_READER_OPTIONS": { },
    "PANDOC_WRITER_OPTIONS": { },
    "PANDOC_STATE": { }
  },
  "quarto": {
    "version": [1, 7, 32],
    "doc": { },
    "project": { },
    "log": { },
    "json": { }
  }
}
```

Functions and userdata values are dropped.
Empty branches are pruned.

### Filtering the export

Four sibling options control what ends up in the JSON file:

- `json-include`: array of dot-separated paths to keep (e.g. `pandoc.FORMAT`).
  Everything outside the listed paths is omitted.
  Omit to keep every non-excluded path.
- `json-exclude`: array of dot-separated paths to drop.
  Applied after the include whitelist.
- `json-exclude-sensitive` (default `true`): redacts built-in sensitive paths that expose host filesystem layout.
  The redacted paths are `quarto.doc.input_file`, `quarto.doc.output_file`, `quarto.project.directory`, `quarto.project.output_directory`, and `pandoc.PANDOC_SCRIPT_FILE`.
  Set to `false` to include them.
- `json-warn-on-server` (default `true`): emits a warning when JSON export is enabled in a CI or server context (`CI`, `GITHUB_ACTIONS`, `GITLAB_CI`, `CIRCLECI`, `TRAVIS`, `JENKINS_URL`, `BUILDKITE`, `TF_BUILD`).
  Set to `false` to silence the warning.

Example, keeping only the active format and Quarto version:

```yaml
extensions:
  lua-env:
    json: true
    json-include:
      - pandoc.FORMAT
      - quarto.version
```

Example, removing a noisy branch while keeping everything else:

```yaml
extensions:
  lua-env:
    json: true
    json-exclude:
      - quarto._quarto
```

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

Output of `example.qmd`:

- [HTML](https://m.canouil.dev/quarto-lua-env/)
