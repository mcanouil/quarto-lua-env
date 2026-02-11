--- @module lua-env-shortcode
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Extension name constant
local EXTENSION_NAME = 'lua-env'

--- Load utils module
local utils = require(quarto.utils.resolve_path('_modules/utils.lua'):gsub('%.lua$', ''))

return {
  ['lua-env'] = function(args, kwargs, meta)
    if #args == 0 then
      utils.log_warning(EXTENSION_NAME, 'No variable name provided.')
      return pandoc.Null()
    end

    if not meta['lua-env'] then
      utils.log_warning(EXTENSION_NAME, 'No lua-env metadata found.')
      return pandoc.Null()
    end

    local var_name = utils.stringify(pandoc.Span(args[1]))
    local value = utils.get_value(utils.split(var_name, '.'), meta['lua-env'])

    if not value then
      utils.log_warning(EXTENSION_NAME, 'Variable \'' .. var_name .. '\' not found in lua-env metadata.')
      return pandoc.Null()
    end

    if args[1] == 'quarto.version' and type(value) == 'table' then
      return table.concat(value, '.')
    else
      return value
    end
  end
}
