--- Implementing pattern matching by abusing table syntax.
-- The idea of this is to implement pattern matching so that we can support things such as `Just x` and then have x
-- availiable in the scope. All it takes is some table magic and parsing.
-- @module match
-- @author daelvn
import DEBUG                                               from require "ltypekit.config"
import y, c, p                                             from DEBUG
import hasMeta, typeof, kindof, isConstructor, metaconsFor from require "ltypekit.type"
import generateSavePairing                                 from require "ltypekit.typeclass"

head = (t) -> t[1]
tail = (t) -> return for x in *t[2,] do x

setfenv or= (fn, env) ->
  i = 1
  while true do
    name = debug.getupvalue fn, i
    if name == "_ENV"
      debug.upvaluejoin fn, i, (-> env), 1
    elseif not name
      break
    i += 1
  fn

--- Compares a value and a case
-- @param v Any value.
-- @tparam table c The case to compare against.
-- @treturn boolean Returns whether it matches or not.
-- @treturn nil|table If the mode of the case is `match-patterns`, it additionally returns a table of parameters and their corresponding values.
compareCase = (v, c) ->
  p "using case", y c
  switch c.__mode
    when "unknown"
      error "compareCase $ Comparison method is not specified"
    when "match-value"
      return false if (typeof v) != c.type
      return false if v          != c.value
      true, nil
    when "match-kind"
      return false if (kindof v) != c.kind
      true, nil
    when "match-patterns"
      save = {}
      return false if (kindof v) != c.const
      for key, target in pairs c.save
        p "matchpat", key, target, y save
        if target\match "^%l"
          save[target] = v[key]
        elseif target\match "^%u"
          return false if (typeof v[key]) != target
      true, save
    else
      error "compareCase $ Unknown comparison method."

--- Creates a case for the pattern matching.
case = (...) ->
  hd = head {...}
  tl = tail {...}
  --
  this =
    __case: true
    __mode: "unknown"
  --
  switch typeof hd
    when "String", "Number", "Table", "Thread", "Boolean", "Userdata", "Nil"
      -- Normal type, just expect this
      this.__mode = "match-value"
      this.type   = typeof hd
      this.value  = hd
    when "Function"
      -- make sure that it's not a constructor
      p "isactually", y hd
      if isConstructor hd
        -- It's a constructor, therefore we have to enable some basic pattern matching.
        ghd         = getmetatable hd
        this.__mode = "match-patterns"
        this.const  = ghd.__name
        this.type   = ghd.__parent.name
        this.save   = generateSavePairing ghd.__parent.constructors[ghd.__name], tl
      else
        -- Match value, again.
        this.__mode = "match-value"
        this.type   = typeof hd
        this.value  = hd
    when "Type"
      -- wait that's illegal
      -- That means we should expect *actually* the kind.
      this.__mode = "match-kind"
      this.kind   = kindof hd
    else
      if isConstructor hd
        -- It's a constructor, therefore we have to enable some basic pattern matching.
        ghd         = getmetatable hd
        this.__mode = "match-patterns"
        this.const  = ghd.__name
        this.type   = ghd.__parent.name
        p "parent-cons", y ghd.__parent.constructors
        this.save   = generateSavePairing ghd.__parent.constructors[ghd.__name], tl
      else
        -- Match value, again.
        this.__mode = "match-value"
        this.type   = typeof hd
        this.value  = hd
  this

--- Given a value and a list of patterns, it calls the function which matches the pattern first.
match = (v, cl) ->
  for case_, f in pairs cl
    ok, sv = compareCase v, case_
    continue unless ok
    p "sv", y sv
    setfenv f, setmetatable (sv or {}), {__index: _G}
    return f!

{ :case, :match }
