--> # ltypekit7
--> Advanced type checking library for Lua.
-- ltypekit.7/type
-- By daelvn
-- 15.05.2019

--> # data
--> Adds a new named type.
data = (n, r) ->
  typeof\add r
  { :name, methods: {}, belongs: {}}

String = data "String", (v) -> isString v
--> # typeclass
--> Declares a new typeclass.
typeclass = (annot, sigl) ->
  words  = [word for word in annot\gmatch "%S+"]
  params = [par for par in *words[2,]]
  setmetatable {name: words[1], :params, :sigl},
    __call: (...) => return @, ...

--> # instance
--> Declares a new instance of a typeclass.
instance = (...) ->
  argl = {...}
  base = selectFirst ...
  decl = selectLast  ...
  --
  for typecl in *argl[2,#argl-1]
    table.insert typecl.belongs, base
  --
