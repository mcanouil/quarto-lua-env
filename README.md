# `lua-env` Extension For Quarto

`lua-env` is a work in progress extension for [Quarto](https://quarto.org) that provides access to the `quarto` LUA environment as metadata.

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

This will give you access to `quarto` LUA internal variables using any of the below shortcodes:

```markdown
{{< lua-env quarto.doc.input_file >}}

{{< meta lua-env.quarto.doc.input_file >}}
```

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).
