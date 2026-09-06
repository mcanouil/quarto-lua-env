--- @module "lua-env-shortcode"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Extension name constant
local EXTENSION_NAME = 'lua-env'

--- Load modules
local str = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/string.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/logging.lua'):gsub('%.lua$', ''))
local pdoc = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/pandoc-helpers.lua'):gsub('%.lua$', ''))
local schema = require(quarto.utils.resolve_path('_vendor/quarto-wizard/schema.lua'):gsub('%.lua$', ''))
local check = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/schema-check.lua'):gsub('%.lua$', ''))

--- The schema check, built once and reused by every shortcode call. It reads
--- `_schema.yml` on the way in and checks each call against the entry that
--- describes it.
---
--- The validator is injected rather than required by the check module, so the
--- two vendored sources stay independent of where the other was placed.
---
--- The extension contributes both a filter and a shortcode, in two files, so
--- the check is split across them. The call check runs from the shortcode
--- handler, because that is the only place a call exists. The filter file
--- checks the document configuration.
---
--- A schema that cannot be read is reported by the module as an error and the
--- render carries on: a configuration file must not stop a document.
local checker = check.new(schema, EXTENSION_NAME)

return {
  ['lua-env'] = function(args, kwargs, meta)
    checker:call('lua-env', args, kwargs)

    if #args == 0 then
      log.log_warning(EXTENSION_NAME, 'No variable name provided.')
      return pandoc.Null()
    end

    if not meta['lua-env'] then
      log.log_warning(EXTENSION_NAME, 'No lua-env metadata found.')
      return pandoc.Null()
    end

    local var_name = str.stringify(pandoc.Span(args[1]))
    local value = pdoc.get_value(str.split(var_name, '.'), meta['lua-env'])

    if not value then
      log.log_warning(EXTENSION_NAME, 'Variable \'' .. var_name .. '\' not found in lua-env metadata.')
      return pandoc.Null()
    end

    if args[1] == 'quarto.version' and type(value) == 'table' then
      return table.concat(value, '.')
    else
      return value
    end
  end
}
