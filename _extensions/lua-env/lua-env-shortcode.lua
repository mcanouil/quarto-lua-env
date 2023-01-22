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

return {
  ['lua-env'] = function(args, kwargs, meta)
    if #args > 0 then
      local var_name = pandoc.utils.stringify(pandoc.Span(args[1]))
      return get_value(split(var_name, "."), meta["lua-env"])
    else
      return nil
    end
  end
}
