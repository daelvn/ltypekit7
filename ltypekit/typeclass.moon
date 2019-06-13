--- Typeclasses, instances and type representations to use alongside `type`.
-- @module typeclass
-- @author daelvn
-- @license MIT
-- @copyright 10.06.2019
unpack or= table.unpack
import sign               from require "ltypekit.sign"
import reverse, collect   from require "ltypekit.util"
import metatype, metakind from require "ltypekit.type"
import DEBUG              from require "ltypekit.config"

local y, c, p
if DEBUG
  io.stdout\setvbuf "no"
  y = require "inspect"
  c = require "ansicolors"
  p = print
else
  p, y, c = (->), (->), (->)

--- Adds a new reference in `_G.__ref`
-- @tparam table ref Reference to store in `_G`
addReference = (ref) -> _G.__ref[ref.name] = ref

--- Creates a new constructor function out of a constructor string.
-- @tparam string type_ Name of the type.
-- @tparam string name Name of the constructor.
-- @tparam string cons Constructor string.
-- @treturn function Constructor.
makeConstructor = (type_, name, cons) ->
  -- Examples of constructor strings.
  --   "String"          : Requires a single string.
  --   "String String"   : Requires two strings.
  --   "a"               : Takes any parameter.
  --   "a b"             : Takes any two parameters.
  --   "name:String x:a" : Record syntax.
  signature = "(#{name}) "
  records   = {}
  ordered   = {}
  i         = 0
  for arg in cons\gmatch "%S+"
    i += 1
    if arg\match ":"
      record, type = arg\match "(.-):(.+)"
      -- Record
      r               = sign "(#{record}) #{name} -> #{type}"
      records[record] = r (t) -> t[i]
      addReference r if _G.__ref
      -- Type
      signature ..= "#{type} ->"
      table.insert ordered, type
    else
      -- Type only
      signature ..= "#{arg} ->"
      table.insert ordered, type
  signature ..= " " .. type_
  --
  p "len", #ordered
  if #ordered > 0
    c = sign signature
    f = (...) ->
      p "constructing-with", y {...}
      (metatype type_) (metakind name) {...}
    return (c collect f, #ordered), records
  else
    return ((metatype type_) (metakind name) {:name}), {}

--- Creates a new type.
-- @tparam string name Name for the new type.
-- @tparam table|string constructorl List of constructors to use, or a single constructor string.
-- @treturn Type Newly created type.
data = (name, constructorl) ->
  this           = { :name }
  __this         = { __ref: {}, __type: "Type", __kind: name }
  __this.__index = __this.__ref
  switch type constructorl
    when "string"
      __this.__call = (...) =>
        f, records = makeConstructor name, name, constructorl
        for k,r in pairs records do __this.__ref[k] = r
        f ...
    when "table"
      for constructor, annot in pairs constructorl
        __this.__ref[constructor] = makeConstructor name, constructor, annot
        addReference __this.__ref[constructor] if _G.__ref
  setmetatable this, __this

Maybe = data "Maybe",
  Nothing: ""
  Just:    "a"

--f = sign "Int -> Maybe Int"
--f (x) -> switch x
--  when 0 then Nothing
--  when x then Just x

--f (x) -> switch x
--  when 0 then Maybe.Nothing
--  when x then Maybe.Just x

--just    = Maybe.Just 5
--p y just
--nothing = Maybe.Nothing
--p y Maybe.Nothing
--p y nothing

{ :addReference, :data }
