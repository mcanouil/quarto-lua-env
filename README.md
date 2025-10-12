# Lua Environment Extension For Quarto

`lua-env` is an extension for [Quarto](https://quarto.org) to provide access to LUA objects as metadata.

## Installing

```bash
quarto add mcanouil/quarto-lua-env
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Using

Add the following to your YAML header:

```yaml
filters:
  - lua-env
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
filters:
  - lua-env
extensions:
  lua-env:
    json: true  # Exports to "lua-env.json"
```

To specify a custom file path:

```yaml
filters:
  - lua-env
extensions:
  lua-env:
    json: "custom-path.json"  # Exports to "custom-path.json"
```

The JSON file will contain all the LUA environment metadata collected during document rendering.

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).
