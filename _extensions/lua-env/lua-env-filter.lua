--[[
# MIT License
#
# Copyright (c) Mickaël Canouil
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
]]

local function is_empty(s)
  return s == nil or s == ''
end

local function get_strings(obj)
  local quarto_array = {}
  if type(obj) == "table" then
    for k, v in pairs(obj) do
      if type(v) == "table" then
        local quarto_array_temp = get_strings(v)
        local tab_size = 0
        for _ in pairs(quarto_array_temp) do
          tab_size = tab_size + 1
        end
        if not is_empty(tab_size) and tab_size > 0 then
          quarto_array[k] = quarto_array_temp
        end
      elseif type(v) == "string"then
        quarto_array[k] = v
      end
    end
  elseif type(obj) == "string" then
    quarto_array[pandoc.utils.stringify(obj)] = obj
  end
  return quarto_array
end

function Meta(meta)
  meta["lua-env"] = { ["quarto"] = get_strings(quarto) }
  return meta
end
