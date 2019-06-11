--- Typeclasses, instances and type representations to use alongside `type`.
-- @module type
-- @author daelvn
-- @license MIT
-- @copyright 10.06.2019
unpack or= table.unpack
import sign             from require "ltypekit.sign"
import reverse, collect from require "ltypekit.util"

--- Enables referencing by changing the metatable for `_G`.
doReferencing = ->
  gmt         = (getmetatable _G) or {}
  _G.__ref    = {}
  gmt.__index = _G.__ref

--- Adds a new reference in `_G.__ref`
-- @tparam table ref Reference to store in `_G`
addReference = (ref) -> _G.__ref[ref.name] = ref

--- Creates a new constructor function out of a constructor string.
makeConstructor = (name, cons) ->
  -- Examples of constructor strings.
  --   "String"          : Requires a single string.
  --   "String String"   : Requires two strings.
  --   "a"               : Takes any parameter.
  --   "a b"             : Takes any two parameters.
  --   "name:String x:a" : Record syntax.
  signature = ""
  records   = {}
  ordered   = {}
  i         = 0
  for arg in cons\gmatch "%S+"
    i += 1
    if arg\match ":"
      record, type = arg\match "(.-):(.+)"
      -- Record
      r          = sign "(#{record}) #{name} -> #{type}"
      records[i] = r (t) -> t[i]
      addReference r if _G.__ref
      -- Type
      signature ..= "#{arg} ->"
      table.insert ordered, type
    else
      -- Type only
      signature ..= "#{arg} ->"
      table.insert ordered, type
  signature ..= name
  --
  c = sign signature
  f = (...) -> {...}
  return (c collect f, #ordered), records

--- Creates a new type.
-- @tparam string name Name for the new type.
-- @tparam table|string constructorl List of constructors to use, or a single constructor string.
-- @tparam Type Newly created type.
data = (name, constructorl) ->
  this   = { :name }
  __this = { __ref: {}, __index: __this.__ref, __type: "Type", __kind: name }
  switch type constructorl
    when "string" then __this.__call = makeConstructor constructorl
    when "table"
      for constructor, annot in pairs constructorl
        __this.__ref[constructor] = makeConstructor annot
        addReference __this.__ref[constructor] if _G.__ref

--Maybe = data "Maybe",
--  Nothing: ""
--  Just:    "a"

--f = sign "Int -> Maybe Int"
--f (x) -> switch x
--  when 0 then Nothing
--  when x then Just x

--f (x) -> switch x
--  when 0 then Maybe.Nothing
--  when x then Maybe.Just x

--Person = data "Person", "s"
