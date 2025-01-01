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

local function is_empty(obj)
  local function length(x)
    local count = 0
    if x ~= nil then
      for _ in pairs(x) do
        count = count + 1
      end
    end
    return count
  end
  if pandoc.utils.type(obj) == "table" or pandoc.utils.type(obj) == "List" then
    return obj == nil or obj == '' or length(obj) == 0
  else 
    return obj == nil or obj == ''
  end
end

local function is_type_simple(obj)
  return pandoc.utils.type(obj) == "string" or pandoc.utils.type(obj) == "number" or pandoc.utils.type(obj) == "boolean"
end

local function is_function_userdata(obj)
  return pandoc.utils.type(obj) == "function" or pandoc.utils.type(obj) == "userdata"
end

local function get_values(obj)
  local values_array = {}
  if not is_empty(obj) then
    if not is_type_simple(obj) and not is_function_userdata(obj) then
      for k, v in pairs(obj) do
        if not is_empty(v) then
          if not is_type_simple(v) and not is_function_userdata(v) then
            local values_array_temp = get_values(v)
            if not is_empty(values_array_temp) then
              values_array[k] = values_array_temp
            end
          elseif pandoc.utils.type(v) ~= "table" and not is_function_userdata(v) then
            values_array[k] = v
          end
        end
      end
    elseif pandoc.utils.type(obj) ~= "table" and not is_function_userdata(obj) then
      values_array[pandoc.utils.stringify(obj)] = obj
    end
  end
  return values_array
end

function Meta(meta)
  meta["lua-env"] = {
    ["quarto"] = get_values(quarto),
    ["pandoc"] = {
      ["PANDOC_STATE"] = get_values(PANDOC_STATE),
      ["FORMAT"] = tostring(FORMAT),
      ["PANDOC_READER_OPTIONS"] = get_values(PANDOC_READER_OPTIONS),
      ["PANDOC_WRITER_OPTIONS"] = get_values(PANDOC_WRITER_OPTIONS),
      ["PANDOC_VERSION"] = tostring(PANDOC_VERSION),
      ["PANDOC_API_VERSION"] = tostring(PANDOC_API_VERSION),
      ["PANDOC_SCRIPT_FILE"] = get_values(PANDOC_SCRIPT_FILE)
    }
  }
  -- quarto.log.output(meta["lua-env"])
  return meta
end
