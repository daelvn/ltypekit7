--- Typeclasses, instances and type representations to use alongside `type`.
-- @module type
-- @author daelvn
-- @license MIT
-- @copyright 10.06.2019
unpack or= table.unpack
import sign from require "ltypekit.sign"

--- Enables referencing by changing the metatable for `_G`.
doReferencing = ->
  gmt         = (getmetatable _G) or {}
  _G.__ref    = {}
  gmt.__index = _G.__ref

--- Adds a new reference in `_G.__ref`
-- @tparam table ref Reference to store in `_G`
addReference = (ref) -> _G.__ref[ref.name] = ref

--- Reverses a list x.
-- @todo Move this to util.
reverse = (x) ->
  y = {}
  for i = #x, 1, -1
    y[#y+1] = x[i]
  y

--- Generates a function that has to be called x times to return a value.
-- @todo Move this to util.
-- @tparam function x When called with the list of accumulated arguments, returns a value.
-- @tparam number n Depth level.
-- @tparam table a Accumulated arguments.
-- @treturn function Curried function.
collect = (f, depth, ...) ->
  argl = {...}
  (x) ->
    if depth == 1
      table.insert argl, 1, x
      f unpack reverse argl
    else
      collect f, depth-1, x, unpack argl

--- Creates a new constructor function out of a constructor string.
makeConstructor = (name, cons) ->
  -- Examples of constructor strings.
  --   "String"          : Requires a single string.
  --   "String String"   : Requires two strings.
  --   "a"               : Takes any parameter.
  --   "a b"             : Takes any two parameters.
  --   "name:String x:a" : Record syntax.
  signature = ""
  ordered   = {}
  for arg in cons\gmatch "%S+"
    if arg\match ":"
      record, type = arg\match "(.-):(.+)"
      r = sign "(#{record}) #{name} -> #{type}"
      r () -- DEFINE RECORD FUNCTION
    else signature ..= "#{arg} ->"
  signature ..= name
  --
  c = sign signature
  f = (...) -> -- DEFINE THE FUNCTION FOR CREATING THE TYPE
  c collect -- FILL THIS UP

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
