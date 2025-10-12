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

--- @type string|nil The JSON file path to export metadata to
local json_file = nil

--- Check if a string is empty or nil
--- @param s string|nil The string to check
--- @return boolean true if the string is nil or empty
local function is_empty(s)
  return s == nil or s == ''
end

--- Extract metadata value from document meta using nested structure
--- @param meta table The document metadata table
--- @param key string The metadata key to retrieve
--- @return string|nil The metadata value as a string, or nil if not found
local function get_metadata_value(meta, key)
  -- Check for the nested structure: extensions.lua-env.key
  if meta['extensions'] and meta['extensions']['lua-env'] and meta['extensions']['lua-env'][key] then
    return pandoc.utils.stringify(meta['extensions']['lua-env'][key])
  end

  return nil
end

--- Export metadata to JSON file
--- @param metadata table The metadata to export
--- @param filepath string The file path to write to
local function export_to_json(metadata, filepath)
  local json_content = quarto.json.encode(metadata)
  local file, err = io.open(filepath, "w")
  if file then
    file:write(json_content)
    file:close()
    quarto.log.output("Exported lua-env metadata to: " .. filepath)
  else
    quarto.log.error("Failed to write JSON file: " .. (err or "unknown error"))
  end
end

--- Get configuration from metadata
--- @param meta table The document metadata table
--- @return table The metadata table
local function get_configuration(meta)
  local meta_json = get_metadata_value(meta, 'json')

  -- Set JSON file path
  if not is_empty(meta_json) then
    if meta_json == "true" then
      json_file = "lua-env.json"
    elseif meta_json == "false" then
      json_file = nil
    else
      json_file = meta_json --[[@as string]]
    end
  end

  return meta
end

--- Check if an object (including tables and lists) is empty or nil
--- @param obj any The object to check
--- @return boolean true if the object is nil, empty string, or empty table/list
local function is_object_empty(obj)
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

--- Check if an object is a simple type (string, number, or boolean)
--- @param obj any The object to check
--- @return boolean true if the object is a string, number, or boolean
local function is_type_simple(obj)
  return pandoc.utils.type(obj) == "string" or pandoc.utils.type(obj) == "number" or pandoc.utils.type(obj) == "boolean"
end

--- Check if an object is a function or userdata
--- @param obj any The object to check
--- @return boolean true if the object is a function or userdata
local function is_function_userdata(obj)
  return pandoc.utils.type(obj) == "function" or pandoc.utils.type(obj) == "userdata"
end

--- Recursively extract values from an object, filtering out empty, function, and userdata values
--- @param obj any The object to extract values from
--- @return table A table containing the extracted values
local function get_values(obj)
  local values_array = {}
  if not is_object_empty(obj) then
    if not is_type_simple(obj) and not is_function_userdata(obj) then
      for k, v in pairs(obj) do
        if not is_object_empty(v) then
          if not is_type_simple(v) and not is_function_userdata(v) then
            local values_array_temp = get_values(v)
            if not is_object_empty(values_array_temp) then
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

--- Populate lua-env metadata
--- @param meta table The document metadata table
--- @return table The metadata table with lua-env populated
function populate_lua_env(meta)
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
  
  -- Export to JSON if configured
  if json_file then
    export_to_json(meta["lua-env"], json_file)
  end
  
  -- quarto.log.output(meta["lua-env"])
  return meta
end

--- Pandoc filter configuration
--- Defines the order of filter execution:
--- 1. Get configuration from metadata
--- 2. Populate lua-env metadata and export to JSON if configured
return {
  { Meta = get_configuration },
  { Meta = populate_lua_env }
}
