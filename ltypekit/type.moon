--- Contains a replacement for the native Lua `type` function and implements resolvers and kinds.
-- @module type
-- @author daelvn
-- @license MIT
-- @copyright 09.05.2019
native         = type
getmetatable or= debug.getmetatable

--- Selects the first element from all arguments.
selectFirst = (...) -> select 1, ...
--- Selects the last element from all arguments.
selectLast  = (...) ->
  argl = {...}
  argl[#argl]

--- Native type checking.
-- Direct `type` replacement and extension functions. This is done so native types match the Uppercase style.
-- @field number "Number"
-- @field string "String"
-- @field function "Function"
-- @field thread "Thread"
-- @field nil "Nil"
-- @field userdata "Userdata"
-- @field table "Table"
-- @field boolean "Boolean"
-- @table baseTypes
baseTypes =
  number: "Number", string: "String",     function: "Function", thread: "Thread",
  nil: "Nil",       userdata: "Userdata", table: "Table",       boolean: "Boolean"

--- Type resolvers for native types.
-- Each of the functions are prefixed with "is" and suffixed with an uppercase type name.
-- @field isNumber Returns either "Number" or false.
-- @field isString Returns either "String" or false.
-- @field isFunction Returns either "Function" or false.
-- @field isThread Returns either "Thread" or false.
-- @field isNil Returns either "Nil" or false.
-- @field isUserdata Returns either "Userdata" or false.
-- @field isTable Returns either "Table" or false.
-- @field isBoolean Returns either "Boolean" or false.
-- @table nativeResolvers
nativeResolvers = {"is"..v, ((a) -> ((native a) == k) and v or false) for k,v in pairs baseTypes}
import isNumber, isString, isFunction, isThread, isNil, isUserdata, isTable, isBoolean from nativeResolvers

--- `type` equivalent, but returns uppercase values.
-- @param a any value
-- @treturn string|nil
type1 = (a) -> baseTypes[native a]

-- # Resolvers
-- Resolvers are functions which take in any value and return a string value depending on whether it can resolve the
-- type or not.
-- ## Issues with overlapping
-- You should make sure that your resolver *only* resolves your type, so for example, not all tables are mistaken with
-- your type. Most of the times you should be able to use a `__type` metamethod.

--> hasMeta
--> Checks for a `__type` metamethod. It can be either a function or a string.
--> If it is a function, it will be called with the value as an argument.
--> ## Dynamic types

--- Checks for a `__type` metamethod. It can be either a function or a string.
-- If it is a function, it will be called with the value as an argument.  
-- As `hasMeta` allows you to have a function be called with the value, the type returned can depend on the value. This
-- is called "dynamic types" in ltypekit. It means that you can define a single type (`Boolean`) and have it return two
-- types (`True` or `False`).
-- @param any any value
-- @treturn string|false
hasMeta = (any) ->
  local typeMeta
  if typeMetatable = getmetatable any
    typeMeta = typeMetatable.__type
  switch native typeMeta
    when "function" then typeMeta any
    when "string"   then typeMeta
    else                 false

--- Checks whether it is an `io` library handle.
-- @param a any value
-- @treturn "IO"|false
isIO = (a) -> (io.type a) and "IO" or false

--- Returns the type of a value. It requires to be a table with methods to exploit the mutability of Lua tables.
-- @table typeof
-- @field resolvers List of resolvers used by typeof.
-- @field add Adds a new type.
typeof = setmetatable {
  --- List of implicit resolvers to `typeof`.
  -- @within typeof
  -- @table resolvers
  resolvers: { hasMeta, isIO }

  --- Resolves a value given a list of resolvers.
  -- @within typeof
  -- @param any Any value.
  -- @tparam table resolverl List of resolvers.
  -- @treturn string|false
  resolve: (any, resolverl) ->
    -- print native any
    for resolver in *resolverl
      resolved = resolver any
      switch type1 resolved
        when "String" then return resolved
        else               continue--print _exp_0
    return (type1 any) or false

  --- Adds a new type.
  -- @within typeof
  -- @tparam function resolver Resolver for the new type.
  add: (resolver) => table.insert @resolvers, resolver
}, {
  --- Resolves a value with the implicit list of resolvers.
  -- @within typeof
  -- @param a Any value.
  -- @treturn string|false
  __call: (a) => @.resolve a, @resolvers
}

--- Sets a `__type` metamethod for a table. **This is a curried function**.
-- @tparam string ty Type name
-- @tparam table t Table to apply the metamethod to.
metatype = (ty) -> (t) ->
  if x = getmetatable t
    x.__type = ty
  else
    setmetatable t, { __type: ty }
  return t

--- Sets a `__kind` metamethod for a table. Only used internally.
-- @tparam string k Kind name
-- @tparam table t Table to apply the metamethod to.
metakind = (k) -> (t) ->
  if x = getmetatable t
    x.__kind = k
  else
    setmetatable t, { __kind: k }
  return t

--- Returns the `__kind` metamethod for a table. Only used internally.
-- @tparam table t Table to get the metamethod from.
metakindFor = (t) ->
  if x = getmetatable t
    x.__kind
  else
    false

--- Sets a `__call` metamethod for a table.
-- @tparam string f A function
-- @tparam table t Table to set the metamethod for.
metacall = (f) -> (t) ->
  if x = getmetatable t
    x.__call = f
  else
    setmetatable t, { __call: f }
  return t

--- Checks for a `__kind` metamethod. It can be either a function or a string.
-- If it is a function, it will be called with the value as an argument.
-- @param any Any value.
-- @treturn string|false
hasKind = (any) ->
  typeKind = metakindFor any
  if typeKind
    switch native typeKind
      when "function" then typeKind any
      when "string"   then typeKind
      else                 false
  else
    false

--- Returns the kind of a value. It is a table for the same reason than typeof.
-- @table kindof
-- @field resolvers List of resolvers used by `kindof`.
-- 
kindof = setmetatable {
  --- Contains the implicit resolvers for `kindof`.
  -- @table resolvers
  -- @within kindof
  resolvers: {hasKind}

  --- Resolves a value given a list of resolvers.
  -- @within kindof
  -- @param any Any value.
  -- @tparam table resolverl List of resolvers.
  -- @treturn string|false
  resolve: (any, resolverl) ->
    for resolver in *resolverl
      resolved = resolver any
      switch type1 resolved
        when "String" then return resolved
        else               continue
    return (type1 any) or false

  --- Adds a new kind.
  -- @within kindof
  -- @tparam function resolver Resolver for the new kind.
  add: (resolver) => table.insert @resolvers, resolver
}, {
  --- Resolves a value with the implicit list of resolvers.
  -- @within kindof
  -- @param a Any value.
  -- @treturn string|false
  __call: (a) => @.resolve a, @resolvers
}

--- Verifies the structure of a list. **Curried function.**
-- @tparam table struct Structure of the list.
-- @tparam table list List to be verified.
-- @treturn boolean Comparison result.
verifyList = (struct) -> (list) ->
  error "verifyList $ wrong argument 'list'. Expected Table, got #{typeof list}."     unless "Table" == typeof list
  error "verifyList $ wrong argument 'struct'. Expected Table, got #{typeof struct}." unless "Table" == typeof struct
  ty = struct[1]
  for elem in *list
    print "verifyList:", elem, (typeof elem), ty, (ty == typeof elem)
    return false unless (typeof elem) == ty
  return true

--- Verifies the structure of a map. **Curried function.**
-- @tparam table struct Structure of the table.
-- @tparam table t Table to be verified.
-- @treturn boolean Comparison result.
verifyTable = (struct) -> (t) ->
  error "verifyTable $ wrong argument 't'. Expected Table, got #{typeof t}."           unless "Table" == typeof t
  error "verifyTable $ wrong argument 'struct'. Expected Table, got #{typeof struct}." unless "Table" == typeof struct
  ty, ty2 = struct[1], struct[2]
  for k,v in pairs t
    return false if (typeof k) != ty
    return false if (typeof v) != ty2
  return true

{
  :typeof, :hasMeta, :isIO, :metatype, :metakind, :metakindFor, :metacall, :type1, :kindof
  :isString, :isNumber, :isBoolean, :isTable, :isNil, :isThread, :isUserdata, :isFunction
  :verifyList, :verifyTable
}
