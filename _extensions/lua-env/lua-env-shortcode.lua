--[[
# MIT License
#
# Copyright (c) 2025 Mickaël Canouil
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
]]

--- Load utils module
local utils_path = quarto.utils.resolve_path("_modules/utils.lua")
local utils = require(utils_path)

return {
  ['lua-env'] = function(args, kwargs, meta)
    if #args == 0 then
      quarto.log.warning("[lua-env] No variable name provided")
      return pandoc.Null()
    end

    if not meta["lua-env"] then
      quarto.log.warning("[lua-env] No lua-env metadata found")
      return pandoc.Null()
    end

    local var_name = utils.stringify(pandoc.Span(args[1]))
    local value = utils.get_value(utils.split(var_name, "."), meta["lua-env"])

    if not value then
      quarto.log.warning("[lua-env] Variable '" .. var_name .. "' not found in lua-env metadata")
      return pandoc.Null()
    end

    if args[1] == "quarto.version" and type(value) == "table" then
      return table.concat(value, '.')
    else
      return value
    end
  end
}
