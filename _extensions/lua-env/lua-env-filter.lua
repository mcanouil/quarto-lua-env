--- @module lua-env-filter
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Extension name constant
local EXTENSION_NAME = 'lua-env'

--- Load modules
local str = require(quarto.utils.resolve_path('_modules/string.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_modules/logging.lua'):gsub('%.lua$', ''))
local meta_mod = require(quarto.utils.resolve_path('_modules/metadata.lua'):gsub('%.lua$', ''))
local pdoc = require(quarto.utils.resolve_path('_modules/pandoc-helpers.lua'):gsub('%.lua$', ''))

--- @type string|nil The JSON file path to export metadata to
local json_file = nil

--- Export metadata to JSON file
--- @param metadata table The metadata to export
--- @param filepath string The file path to write to
local function export_to_json(metadata, filepath)
  local json_content = quarto.json.encode(metadata)
  local file, err = io.open(filepath, 'w')
  if file then
    file:write(json_content)
    file:close()
    log.log_output(EXTENSION_NAME, 'Exported metadata to: ' .. filepath)
  else
    log.log_error(EXTENSION_NAME, 'Failed to write JSON file: ' .. (err or 'unknown error'))
  end
end

--- Get configuration from metadata
--- @param meta table The document metadata table
--- @return table The metadata table
local function get_configuration(meta)
  local meta_json = meta_mod.get_metadata_value(meta, 'lua-env', 'json')

  -- Set JSON file path
  if not str.is_empty(meta_json) then
    if meta_json == 'true' then
      json_file = 'lua-env.json'
    elseif meta_json == 'false' then
      json_file = nil
    else
      json_file = meta_json --[[@as string]]
    end
  end

  return meta
end

--- Recursively extract values from an object, filtering out empty, function, and userdata values
--- @param obj any The object to extract values from
--- @return table A table containing the extracted values
local function get_values(obj)
  local values_array = {}
  if not pdoc.is_object_empty(obj) then
    if not pdoc.is_type_simple(obj) and not pdoc.is_function_userdata(obj) then
      for k, v in pairs(obj) do
        if not pdoc.is_object_empty(v) then
          if not pdoc.is_type_simple(v) and not pdoc.is_function_userdata(v) then
            local values_array_temp = get_values(v)
            if not pdoc.is_object_empty(values_array_temp) then
              values_array[k] = values_array_temp
            end
          elseif pandoc.utils.type(v) ~= 'table' and not pdoc.is_function_userdata(v) then
            values_array[k] = v
          end
        end
      end
    elseif pandoc.utils.type(obj) ~= 'table' and not pdoc.is_function_userdata(obj) then
      values_array[pandoc.utils.stringify(obj)] = obj
    end
  end
  return values_array
end

--- Populate lua-env metadata
--- @param meta table The document metadata table
--- @return table The metadata table with lua-env populated
local function populate_lua_env(meta)
  meta['lua-env'] = {
    ['quarto'] = get_values(quarto),
    ['pandoc'] = {
      ['PANDOC_STATE'] = get_values(PANDOC_STATE),
      ['FORMAT'] = tostring(FORMAT),
      ['PANDOC_READER_OPTIONS'] = get_values(PANDOC_READER_OPTIONS),
      ['PANDOC_WRITER_OPTIONS'] = get_values(PANDOC_WRITER_OPTIONS),
      ['PANDOC_VERSION'] = tostring(PANDOC_VERSION),
      ['PANDOC_API_VERSION'] = tostring(PANDOC_API_VERSION),
      ['PANDOC_SCRIPT_FILE'] = get_values(PANDOC_SCRIPT_FILE)
    }
  }

  -- Export to JSON if configured
  if json_file then
    export_to_json(meta['lua-env'], json_file)
  end

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
