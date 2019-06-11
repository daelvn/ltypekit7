local native = type
local getmetatable = getmetatable or debug.getmetatable
local selectFirst
selectFirst = function(...)
  return select(1, ...)
end
local selectLast
selectLast = function(...)
  local argl = {
    ...
  }
  return argl[#argl]
end
local baseTypes = {
  number = "Number",
  string = "String",
  ["function"] = "Function",
  thread = "Thread",
  ["nil"] = "Nil",
  userdata = "Userdata",
  table = "Table",
  boolean = "Boolean"
}
local nativeResolvers
do
  local _tbl_0 = { }
  for k, v in pairs(baseTypes) do
    _tbl_0["is" .. v] = (function(a)
      return ((native(a)) == k) and v or false
    end)
  end
  nativeResolvers = _tbl_0
end
local isNumber, isString, isFunction, isThread, isNil, isUserdata, isTable, isBoolean
isNumber, isString, isFunction, isThread, isNil, isUserdata, isTable, isBoolean = nativeResolvers.isNumber, nativeResolvers.isString, nativeResolvers.isFunction, nativeResolvers.isThread, nativeResolvers.isNil, nativeResolvers.isUserdata, nativeResolvers.isTable, nativeResolvers.isBoolean
local type1
type1 = function(a)
  return baseTypes[native(a)]
end
local hasMeta
hasMeta = function(any)
  local typeMeta
  do
    local typeMetatable = getmetatable(any)
    if typeMetatable then
      typeMeta = typeMetatable.__type
    end
  end
  local _exp_0 = native(typeMeta)
  if "function" == _exp_0 then
    return typeMeta(any)
  elseif "string" == _exp_0 then
    return typeMeta
  else
    return false
  end
end
local isIO
isIO = function(a)
  return (io.type(a)) and "IO" or false
end
local typeof = setmetatable({
  resolvers = {
    hasMeta,
    isIO
  },
  resolve = function(any, resolverl)
    for _index_0 = 1, #resolverl do
      local _continue_0 = false
      repeat
        local resolver = resolverl[_index_0]
        local resolved = resolver(any)
        local _exp_0 = type1(resolved)
        if "String" == _exp_0 then
          return resolved
        else
          _continue_0 = true
          break
        end
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    return (type1(any)) or false
  end,
  add = function(self, resolver)
    return table.insert(self.resolvers, resolver)
  end
}, {
  __call = function(self, a)
    return self.resolve(a, self.resolvers)
  end
})
local metatype
metatype = function(ty)
  return function(t)
    do
      local x = getmetatable(t)
      if x then
        x.__type = ty
      else
        setmetatable(t, {
          __type = ty
        })
      end
    end
    return t
  end
end
local metakind
metakind = function(k)
  return function(t)
    do
      local x = getmetatable(t)
      if x then
        x.__kind = k
      else
        setmetatable(t, {
          __kind = k
        })
      end
    end
    return t
  end
end
local metakindFor
metakindFor = function(t)
  do
    local x = getmetatable(t)
    if x then
      return x.__kind
    else
      return false
    end
  end
end
local metacall
metacall = function(f)
  return function(t)
    do
      local x = getmetatable(t)
      if x then
        x.__call = f
      else
        setmetatable(t, {
          __call = f
        })
      end
    end
    return t
  end
end
local hasKind
hasKind = function(any)
  local typeKind = metakindFor(any)
  if typeKind then
    local _exp_0 = native(typeKind)
    if "function" == _exp_0 then
      return typeKind(any)
    elseif "string" == _exp_0 then
      return typeKind
    else
      return false
    end
  else
    return false
  end
end
local kindof = setmetatable({
  resolvers = {
    hasKind
  },
  resolve = function(any, resolverl)
    for _index_0 = 1, #resolverl do
      local _continue_0 = false
      repeat
        local resolver = resolverl[_index_0]
        local resolved = resolver(any)
        local _exp_0 = type1(resolved)
        if "String" == _exp_0 then
          return resolved
        else
          _continue_0 = true
          break
        end
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    return (type1(any)) or false
  end,
  add = function(self, resolver)
    return table.insert(self.resolvers, resolver)
  end
}, {
  __call = function(self, a)
    return self.resolve(a, self.resolvers)
  end
})
local verifyList
verifyList = function(struct, cache)
  if cache == nil then
    cache = { }
  end
  return function(list)
    if not ("Table" == typeof(list)) then
      error("verifyList $ wrong argument 'list'. Expected Table, got " .. tostring(typeof(list)) .. ".")
    end
    if not ("Table" == typeof(struct)) then
      error("verifyList $ wrong argument 'struct'. Expected Table, got " .. tostring(typeof(struct)) .. ".")
    end
    local ty = struct[1]
    for _index_0 = 1, #list do
      local elem = list[_index_0]
      print("verifyList:", elem, (typeof(elem)), ty, (ty == typeof(elem)))
      if ty:match("^%l") then
        if cache[ty] then
          if not ((typeof(elem)) == cache[ty]) then
            return false
          end
        else
          print("set-cache-verlist", ty, typeof(elem))
          cache[ty] = typeof(elem)
        end
      else
        if not ((typeof(elem)) == ty) then
          return false
        end
      end
    end
    return true
  end
end
local verifyTable
verifyTable = function(struct)
  return function(t)
    if not ("Table" == typeof(t)) then
      error("verifyTable $ wrong argument 't'. Expected Table, got " .. tostring(typeof(t)) .. ".")
    end
    if not ("Table" == typeof(struct)) then
      error("verifyTable $ wrong argument 'struct'. Expected Table, got " .. tostring(typeof(struct)) .. ".")
    end
    local ty, ty2 = struct[1], struct[2]
    for k, v in pairs(t) do
      if ty:match("^%l") then
        if cache[ty] then
          if not ((typeof(k)) == cache[ty]) then
            return false
          end
        else
          print("set-cache-vertab-k", ty, typeof(k))
          cache[ty] = typeof(k)
        end
      else
        if not ((typeof(k)) == ty) then
          return false
        end
      end
      if ty2:match("^%l") then
        if cache[ty2] then
          if not ((typeof(v)) == cache[ty2]) then
            return false
          end
        else
          print("set-cache-vertab-v", ty2, typeof(v))
          cache[ty2] = typeof(v)
        end
      else
        if not ((typeof(v)) == ty) then
          return false
        end
      end
    end
    return true
  end
end
return {
  typeof = typeof,
  hasMeta = hasMeta,
  isIO = isIO,
  metatype = metatype,
  metakind = metakind,
  metakindFor = metakindFor,
  metacall = metacall,
  type1 = type1,
  kindof = kindof,
  isString = isString,
  isNumber = isNumber,
  isBoolean = isBoolean,
  isTable = isTable,
  isNil = isNil,
  isThread = isThread,
  isUserdata = isUserdata,
  isFunction = isFunction,
  verifyList = verifyList,
  verifyTable = verifyTable
}
