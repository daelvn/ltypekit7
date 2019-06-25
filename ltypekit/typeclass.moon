--- Typeclasses, instances and type representations to use alongside `type`.
-- @module typeclass
-- @author daelvn
-- @license MIT
-- @copyright 10.06.2019
unpack or= table.unpack
import sign                             from require "ltypekit.sign"
import reverse, collect, mergemetatable from require "ltypekit.util"
import metatype, metakind, metacons     from require "ltypekit.type"
import DEBUG                            from require "ltypekit.config"

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
addReference = (ref) ->
  p y ref
  p y _G.__ref
  _G.__ref[(getmetatable ref).__name] = ref

--- Parses a constructor out of a constructor string.
-- @tparam string type_ The type that should be returned by the constructor.
-- @tparam string name The name of the constructor.
-- @tparam string cons The annotation of the constructor.
-- @tparam boolean dorecords Defaults to true. Set to false if you do not want record functions to be produced.
-- @tparam boolean doaddrefs Defaults to true. Set to false if you do not want record functions to be added to `_G.__ref`
parseConstructor = (type_, name, cons, dorecords=true, doaddrefs=true) ->
  -- Examples of constructor strings.
  --   "String"          : Requires a single string.
  --   "String String"   : Requires two strings.
  --   "a"               : Takes any parameter.
  --   "a b"             : Takes any two parameters.
  --   "name:String x:a" : Record syntax.
  signature = "(#{name}) "
  records   = {}
  ordered   = {}
  index2r   = {}
  i         = 0
  for arg in cons\gmatch "%S+"
    i += 1
    if arg\match ":"
      record, type = arg\match "(.-):(.+)"
      -- Record
      r               = sign "(#{record}) #{name} -> #{type}"
      records[record] = r (t) -> t[i] if dorecords
      addReference r                  if _G.__ref and dorecords and doaddrefs
      -- Type
      signature ..= "#{type} ->"
      table.insert ordered, type
      index2r[#ordered] = record
    else
      -- Type only
      signature ..= "#{arg} ->"
      table.insert ordered, type
  signature ..= " " .. type_
  --
  signature, records, ordered, index2r

-- TODO Constructor values can have some unaccessible values, restricted by __index. That means that everything must be put
-- behind a proxy table, that way we avoid stuff like `v == (Just v)[1]`. I'd have to check the side effects of that.

--- Creates a new constructor function out of a constructor string.
-- @tparam string type_ Name of the type.
-- @tparam string name Name of the constructor.
-- @tparam string cons Constructor string.
-- @tparam table parent Parent type for the constructor.
-- @treturn function Constructor.
makeConstructor = (type_, name, cons, parent) ->
  signature, records, ordered = parseConstructor type_, name, cons
  p "len", #ordered
  if #ordered > 0
    c = sign signature
    f = (...) ->
      p "constructing-with", y {...}
      t = (mergemetatable {__name: name, __parent: parent}) (metatype type_) (metakind name) {...}
      p "constructed", y t
      return t
    return ((mergemetatable {__parent: parent}) (metacons name) (c collect f, #ordered)), records
  else
    return ((mergemetatable {__name: name, __parent: parent}) (metacons name) (metatype type_) (metakind name) {}), {}

--- Creates a list of expected parameters.
-- @tparam string annot Annotation for a constructor.
-- @treturn table Expected parameters.
getListFor = (annot) ->
  parts = [word for word in annot\gmatch "%S+"]
  return for part in *parts[2,] do part

--- Associate indexes in a value of a certain type to the name of the values they should be saved under.
-- @tparam string constructor The constructor string that generated the value.
-- @tparam table tail Names for each of the values in positional order.
-- @treturn table The generated save pairing.
-- @usage
--   generateSavePairing "Point Number Number", {"_", "a"} 
--   generateSavePairing "Point2 x:Number y:Number", {"Number", "c"}
generateSavePairing = (constructor, tail) ->
  p "savepair", y constructor
  name, rest         = constructor\match "(.-)%s*(.+)"
  p (y constructor), (y name), (y rest)
  _, _, ordered, i2r = parseConstructor "", name, rest, false
  p "savepair-r", (y ordered), (y i2r)
  save               = {}
  for i, arg in ipairs tail
    continue if arg == "_"
    if r = i2r[i] -- this means that it's indexed using a record
      save[r] = arg
    else -- a normal index
      save[i] = arg
  save

--- Creates a new type.
-- @tparam string name Name for the new type.
-- @tparam table|string constructorl List of constructors to use, or a single constructor string.
-- @treturn Type Newly created type.
data = (name, constructorl) ->
  this           = { constructors: {} }
  __this         = { __name: name, __ref: {}, __type: "Type", __kind: name }
  __this.__index = __this.__ref
  switch type constructorl
    when "string"
      __this.__call = (...) =>
        f, records = makeConstructor name, name, constructorl, this
        for k,r in pairs records do __this.__ref[k] = r
        this.constructors[name] = do
          p "constructorl", y constructorl
          --w = getListFor constructorl
          --table.insert w, 1, name
          --table.concat w, " "
          name .. ((constructorl != " ") and (" " .. constuctorl) or "")
        f ...
    when "table"
      for constructor, annot in pairs constructorl
        __this.__ref[constructor] = makeConstructor name, constructor, annot, this
        this.constructors[constructor] = do
          p "annot", y annot
          --w = getListFor annot
          --table.insert w, 1, name
          --table.concat w, " "
          name .. ((annot != " ") and (" " .. annot) or "")
        addReference __this.__ref[constructor] if _G.__ref
  setmetatable this, __this

{ :addReference, :data, :getListFor, :generateSavePairing }
