--- Typeclasses, instances and type representations to use alongside `type`.
-- @module typeclass
-- @author daelvn
unpack or= table.unpack
only     = (t) -> for k, v in pairs t do return v if k != "n"
import sign, flatten                                                              from require "ltypekit.sign"
import contextSplit, normalizeContext, mergeContext                               from require "ltypekit.signature"
import reverse, collect, mergemetatable, extractMeta, selectLast                  from require "ltypekit.util"
import metatype, metakind, metacons, baseTypes, kindof, typeof, typefor, classfor from require "ltypekit.type"
import DEBUG                                                                      from require "ltypekit.config"
import y, c, p                                                                    from DEBUG

--- Adds a new reference in `_G.__ref`
-- @tparam table ref Reference to store in `_G`.
addReference = (ref) ->
  p "addref", y ref
  _G.__ref[(getmetatable ref).__name] = ref

--- Adds a new stub reference in `_G.__ref`. This is used to select which instance of a function to use based on the arguments.
-- @tparam string ref Name of the stub.
newStub = (ref) ->
  stub   = { name: ref, instances: {} }
  __stub =
    __index: (i) => (rawget @, "instances")[i] or error "#{ref} $ No instance defined for #{i}"
    __call: (...) =>
      argl            = {...}
      farg            = argl[1]
      p "call-stub", y argl
      pickFunctions   = {k, v for k, v in pairs (rawget @, "instances") when k\match "^%f[%w_]#{typeof farg}%f[^%w_]"}
      pickFunctions.n = do
        n = 0
        for k, v in pairs pickFunctions do n += 1
        n
      p "picked", y pickFunctions
      if pickFunctions.n < 1
        error "#{ref} $ No instance defined for type #{typeof farg}."
      elseif pickFunctions.n == 1
        (only pickFunctions) unpack argl
      else
        possibilities = do
          final = ""
          for k, _ in pairs pickFunctions
            final ..= "  '#{k}'\n" unless k == "n"
          final
        error "#{ref} $ Ambiguous definition for function #{ref}.\n#{possibilities}"
  setmetatable stub, __stub
  _G.__ref[ref] = stub

--- Adds a function to a stub reference in `_G.__ref`
-- @tparam string ref Name of the stub.
-- @tparam string annot Annotation for the function.
-- @tparam function fn Function instance.
addToStub = (ref, annot, fn) ->
  newStub ref unless _G.__ref[ref]
  _G.__ref[ref].instances[annot] = fn

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
  signature = "#{name} ? "
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

-- TODO Scrap the last idea. To fix the "expected type" issue, the metatable should have a table to contain the types of its values,
-- and somehow the applier should be able to know them.

--- Creates a new constructor function out of a constructor string.
-- @tparam string type_ Name of the type.
-- @tparam string name Name of the constructor.
-- @tparam string cons Constructor string.
-- @tparam table parent Parent type for the constructor.
-- @tparam table mt Metatable to merge with the final product. Defaults to an empty table.
-- @treturn function Constructor.
makeConstructor = (type_, name, cons, parent, mt={}) ->
  signature, records, ordered = parseConstructor type_, name, cons
  p "len", #ordered
  if #ordered > 0
    c = sign signature
    f = (...) ->
      p "constructing-with", y {...}
      t = (mergemetatable mt) (mergemetatable {__name: name, __parent: parent}) (metatype type_) (metakind name) {...}
      return t
    return ((mergemetatable mt) (mergemetatable {__parent: parent}) (metacons name) (c collect f, #ordered)), records
  else
    return ((mergemetatable mt) (mergemetatable {__name: name, __parent: parent}) (metacons name) (metatype type_) (metakind name) {}), {}

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
  this           = { constructors: {}, instanceOf: {} }
  __this         = { __name: name, __ref: {}, __type: "Type", __kind: name, __tostring: -> name }
  __this.__index = __this.__ref
  switch type constructorl
    when "string"
      __this.__call = (...) =>
        f, records = makeConstructor name, name, constructorl, this
        for k,r in pairs records do __this.__ref[k] = r
        this.constructors[name] = do
          p "constructorl", y constructorl
          name .. ((constructorl != " ") and (" " .. constuctorl) or "")
        f ...
    when "table"
      for constructor, annot in pairs constructorl
        continue if constructor\match "^__"
        __this.__ref[constructor] = makeConstructor name, constructor, annot, this, extractMeta constructorl
        this.constructors[constructor] = do
          p "annot", y annot
          name .. ((annot != " ") and (" " .. annot) or "")
        addReference __this.__ref[constructor] if _G.__ref
  setmetatable this, __this
  typeof.datatypes[name] = this
  this

--- Parses constraints in a typeclass annotation
-- @tparam string annot The annotation of the typeclass.
-- @treturn table Context to inject in the signature
-- @treturn string Rest of the annotation
parseConstraintsTC = (annot) ->
  st, en      = annot\find " => "
  constraints = annot\sub 1, st-1
  rest        = annot\sub en+1
  return (normalizeContext contextSplit constraints), rest

--- Creates a new typeclass.
-- @tparam string annot Name and parameters of the new class.
-- @tparam table signl List of signature generators.
-- @treturn Typeclass The new typeclass.
typeclass = (annot, signl) ->
  context = {}
  context, annot = parseConstraintsTC annot if annot\match " => " -- we have to extract the constraints
  parts  = [p for p in annot\gmatch "%S+"]
  name   = parts[1]
  table.remove parts, 1
  --
  this   = { instances: {}, expect: parts, signatures: signl, :context }
  __this = { __name: name, __type: "Typeclass", __kind: name }
  --
  setmetatable this, __this
  classfor[name] = this
  this

--- Creates a new instance of a typeclass.
-- @tparam Typeclass Typeclass to make an instance of.
-- @usage
--   instance Eq, Bool, compare: (ba) -> (ag) -> ba == ag
instance = (tc, ...) ->
  fnl        = selectLast ...
  argl       = {i, arg for i, arg in ipairs {...} when i != #({...})}
  for arg in *argl do table.insert arg.instanceOf, tc
  instanceID = do
    args = [tostring arg for arg in *argl]
    table.concat args, ":"
  p "new-instance", (y fnl), (y argl), instanceID
  --
  callWith = setmetatable {}, __call: (sig) => with sig
    for param, ty in pairs @
      _with_0 = \gsub "([ %(%[])(#{param})([ %)%]])", "%1#{ty}%3"
  for i, part in ipairs tc.expect do callWith[part] = tostring argl[i]
  p "callWith", y callWith
  --
  tc.instances[instanceID] = {}
  -- this one required all functions to be instanced, and we don't want that
  --for fn, signature in pairs tc.signatures
  --  constructor = signature callWith
  --  tc.instances[instanceID][fn] = constructor fnl[fn]
  --  if _G.__ref
  --    addToStub fn, instanceID, tc.instances[instanceID][fn]
  --
  for fn, defin in pairs fnl
    signature   = tc.signatures[fn] or error "instance $ no signature defined for function #{fn}"
    constructor = signature callWith
    -- inject context
    (mergeContext constructor.tree.context) tc.context
    -- instance
    p "instancing", fn, (y constructor)
    tc.instances[instanceID][fn] = constructor flatten defin
    if _G.__ref
      addToStub fn, instanceID, tc.instances[instanceID][fn]

{ :addReference, :data, :getListFor, :generateSavePairing, :instance, :typeclass }
