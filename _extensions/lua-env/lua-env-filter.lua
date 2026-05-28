--- @module lua-env-filter
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Extension name constant
local EXTENSION_NAME = 'lua-env'

--- Load modules
local str = require(quarto.utils.resolve_path('_modules/string.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_modules/logging.lua'):gsub('%.lua$', ''))
local pdoc = require(quarto.utils.resolve_path('_modules/pandoc-helpers.lua'):gsub('%.lua$', ''))

--- @type string|nil The JSON file path to export metadata to
local json_file = nil

--- @type table<string, boolean>|nil Set of dot-separated paths to include (whitelist)
local include_paths = nil

--- @type table<string, boolean>|nil Set of dot-separated paths to exclude (blacklist)
local exclude_paths = nil

--- @type boolean Whether to redact built-in sensitive paths (absolute filesystem paths)
local exclude_sensitive = true

--- @type boolean Whether to warn when exporting in detected server/CI contexts
local warn_on_server = true

--- @type table Set of dot-separated paths considered sensitive by default
--- These leak the host filesystem layout, so are redacted unless the user opts out.
local SENSITIVE_PATHS = {
  ['quarto.doc.input_file'] = true,
  ['quarto.doc.output_file'] = true,
  ['quarto.project.directory'] = true,
  ['quarto.project.output_directory'] = true,
  ['pandoc.PANDOC_SCRIPT_FILE'] = true,
}

--- Coerce a metadata value to a Lua boolean if it represents one, otherwise return nil.
--- Handles raw Lua booleans, Pandoc MetaBool (via `pandoc.utils.type`), and the strings
--- `'true'`/`'false'` (case-insensitive). Any other value yields nil so callers can
--- treat it as a non-boolean (for example a file path string).
--- @param value any The metadata value to coerce
--- @return boolean|nil The coerced boolean, or nil if value is not boolean-like
local function coerce_boolean(value)
  if value == nil then return nil end
  if type(value) == 'boolean' then return value end
  if pandoc.utils.type(value) == 'boolean' then return value end
  local s = pandoc.utils.stringify(value)
  if s == nil or s == '' then return nil end
  local lower = s:lower()
  if lower == 'true' then return true end
  if lower == 'false' then return false end
  return nil
end

--- Read a raw metadata value at extensions.{extension_name}.{key} without stringifying.
--- @param meta table The document metadata table
--- @param extension_name string The extension namespace key
--- @param key string The configuration key
--- @return any The raw metadata value, or nil if missing
local function get_raw_meta(meta, extension_name, key)
  if not meta['extensions'] then return nil end
  if not meta['extensions'][extension_name] then return nil end
  return meta['extensions'][extension_name][key]
end

--- Parse a list-style metadata value into a set of strings.
--- Accepts a MetaList of strings or a single scalar string.
--- @param value any The raw metadata value
--- @return table<string, boolean>|nil A set keyed by path string, or nil if absent
local function parse_path_list(value)
  if value == nil then return nil end
  local set = {}
  if pandoc.utils.type(value) == 'List' or type(value) == 'table' then
    local has_array = value[1] ~= nil
    if has_array then
      for _, entry in ipairs(value) do
        local s = str.trim(pandoc.utils.stringify(entry))
        if s ~= '' then set[s] = true end
      end
      return next(set) and set or nil
    end
  end
  local s = str.trim(pandoc.utils.stringify(value))
  if s == '' then return nil end
  set[s] = true
  return set
end

--- Detect a server or CI execution context via well-known environment variables.
--- @return string|nil The matching environment variable name, or nil if not detected
local function detect_server_context()
  local server_vars = {
    'CI',
    'GITHUB_ACTIONS',
    'GITLAB_CI',
    'CIRCLECI',
    'TRAVIS',
    'JENKINS_URL',
    'BUILDKITE',
    'TF_BUILD',
  }
  for _, name in ipairs(server_vars) do
    local value = os.getenv(name)
    if value ~= nil and value ~= '' and value ~= 'false' then
      return name
    end
  end
  return nil
end

--- Test if a dot-separated path is matched by a path set, including any ancestor entry.
--- @param path string The dot-separated path to test (e.g. 'quarto.doc.input_file')
--- @param set table<string, boolean>|nil The path set to check against
--- @return boolean True if the path or any of its ancestors is in the set
local function path_matches(path, set)
  if not set then return false end
  if set[path] then return true end
  local prefix = path
  while true do
    local dot = prefix:find('%.[^%.]*$')
    if not dot then break end
    prefix = prefix:sub(1, dot - 1)
    if set[prefix] then return true end
  end
  return false
end

--- Decide whether a path should be retained in the exported metadata.
--- Applies include whitelist (if set), exclude blacklist, and sensitive defaults.
--- The check also passes for descendants of an included path so containers above
--- a kept leaf are preserved.
--- @param path string The dot-separated path to test
--- @return boolean True if the path should be kept
local function should_keep(path)
  if exclude_sensitive and SENSITIVE_PATHS[path] then return false end
  if path_matches(path, exclude_paths) then return false end
  if include_paths then
    if path_matches(path, include_paths) then return true end
    for entry in pairs(include_paths) do
      if entry:sub(1, #path + 1) == path .. '.' then return true end
    end
    return false
  end
  return true
end

--- Recursively filter a metadata tree against include/exclude/sensitive rules.
--- Empty branches are pruned so the resulting JSON stays compact. A node whose
--- own path is dropped (e.g. a sensitive container) is removed wholesale, so all
--- descendants disappear regardless of their individual paths.
--- @param value any The current subtree value
--- @param path string The dot-separated path of the current node
--- @return any The filtered value, or nil if the entire branch was filtered out
local function filter_tree(value, path)
  if path ~= '' and not should_keep(path) then return nil end
  if type(value) ~= 'table' then
    return value
  end
  local is_array = value[1] ~= nil
  if is_array then
    return value
  end
  local result = {}
  local kept = false
  for k, v in pairs(value) do
    local child_path = path == '' and tostring(k) or (path .. '.' .. tostring(k))
    local filtered = filter_tree(v, child_path)
    if filtered ~= nil then
      result[k] = filtered
      kept = true
    end
  end
  if kept then return result end
  if next(value) == nil then return value end
  return nil
end

--- Export metadata to JSON file
--- @param metadata table The metadata to export
--- @param filepath string The file path to write to
local function export_to_json(metadata, filepath)
  local payload = filter_tree(metadata, '') or {}
  local json_content = quarto.json.encode(payload)
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
  -- Reset module-level state per document to avoid cross-document leakage in batch renders.
  json_file = nil
  include_paths = nil
  exclude_paths = nil
  exclude_sensitive = true
  warn_on_server = true

  local raw_json = get_raw_meta(meta, 'lua-env', 'json')
  local json_bool = coerce_boolean(raw_json)
  if json_bool == true then
    json_file = 'lua-env.json'
  elseif json_bool == false then
    json_file = nil
  elseif raw_json ~= nil then
    local s = pandoc.utils.stringify(raw_json)
    if s ~= '' then
      json_file = s
    end
  end

  include_paths = parse_path_list(get_raw_meta(meta, 'lua-env', 'json-include'))
  exclude_paths = parse_path_list(get_raw_meta(meta, 'lua-env', 'json-exclude'))

  local raw_sensitive = get_raw_meta(meta, 'lua-env', 'json-exclude-sensitive')
  local sensitive_bool = coerce_boolean(raw_sensitive)
  if sensitive_bool ~= nil then exclude_sensitive = sensitive_bool end

  local raw_warn = get_raw_meta(meta, 'lua-env', 'json-warn-on-server')
  local warn_bool = coerce_boolean(raw_warn)
  if warn_bool ~= nil then warn_on_server = warn_bool end

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
    if warn_on_server then
      local ctx = detect_server_context()
      if ctx then
        log.log_warning(
          EXTENSION_NAME,
          'JSON export is enabled in a server/CI context (' .. ctx .. ' is set). ' ..
          'The exported file may leak host filesystem paths. ' ..
          'Set extensions.lua-env.json-warn-on-server: false to silence this warning.'
        )
      end
    end
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
