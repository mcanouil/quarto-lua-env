--- @module lua-env-shortcode
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Extension name constant
local EXTENSION_NAME = 'lua-env'

--- Load modules
local str = require(quarto.utils.resolve_path('_modules/string.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_modules/logging.lua'):gsub('%.lua$', ''))
local pdoc = require(quarto.utils.resolve_path('_modules/pandoc-helpers.lua'):gsub('%.lua$', ''))

return {
  ['lua-env'] = function(args, kwargs, meta)
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
