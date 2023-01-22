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

local function split(str, sep)
  local fields = {}
  local pattern = string.format("([^%s]+)", sep)
  str:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

local function get_value(fields, obj)
  local value = obj
  for _, field in ipairs(fields) do
    value = value[field]
  end
  return value
end

function Meta(meta)
  -- meta["lua-env"] = {}
  meta["lua-env"] = { ["quarto"] = get_strings(quarto) }
  return meta
end