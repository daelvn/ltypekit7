--- Implementing pattern matching by abusing table syntax.
-- The idea of this is to implement pattern matching so that we can support things such as `Just x` and then have x
-- availiable in the scope. All it takes is some table magic and parsing.
-- @module match
-- @author daelvn
-- @license MIT
-- @copyright 16.06.2019
import DEBUG                                  from require "ltypekit.config"
import hasMeta, typeof, kindof, isConstructor from require "ltypekit.type"
import generateSavePairing                    from require "ltypekit.typeclass"

local y, c, p
if DEBUG
  io.stdout\setvbuf "no"
  y = require "inspect"
  c = require "ansicolors"
  p = print
else
  p, y, c = (->), (->), (->)

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
      for key, target in pairs c.save
        if target\match "^%l"
          save[target] = v[key]
        elseif target\match "^%u"
          return false if (typeof v[key]) != target
      true, save
    else
      error "compareCase $ Unknown comparison method."

--- Puts a value or case into custom objects that share the same `__eq` function.
Comparable = (x) -> setmetatable x,
  __eq: (t) =>
    if @__base
      for case_, f in pairs t
        continue if case_ == "__base"
        ok, sv = compareCase case_, @[1]
        continue unless ok
        setfenv f, setmetatable (sv or {}), {__index: _G}
        return f!
    elseif @__against
      for case_, f in pairs @
        continue if case_ == "__against"
        ok, sv = compareCase case_, t[1]
        continue unless ok
        setfenv f, setmetatable (sv or {}), {__index: _G}
        return f!
    else
      error "Comparable $ The element passed to Comparable cannot be compared."

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
    when "String", "Number", "Function", "Table", "Thread", "Boolean", "Userdata", "Nil"
      -- Normal type, just expect this
      this.__mode = "match-value"
      this.type   = typeof hd
      this.value  = hd
    else "Type"
      -- wait that's illegal
      -- That means we should expect *actually* the kind.
      this.__mode = "match-kind"
      this.kind   = kindof hd
    else
      if isConstructor hd
        -- It's a constructor, therefore we have to enable some basic pattern matching.
        this.__mode = "match-patterns"
        this.const  = hd.name
        this.type   = hd.parent.name
        this.save   = generateSavePairing hd.parent.constructors[hd.name], tl
      else
        -- Match value, again.
        this.__mode = "match-value"
        this.type   = typeof hd
        this.value  = jd

--- Given a value and a list of patterns, it calls the function which matches the pattern first.
match = (v, cl) ->
  for case_, f in pairs cl
    ok, sv = compareCase case_, v
    continue unless ok
    setfenv f, setmetatable (sv or {}), {__index: _G}
    return f!

fromMaybe = sign "a -> Maybe a -> a"
fromMaybe (d) -> (x) -> match x,
  [case Nothing]:   -> d
  [case Just, "a"]: -> a

-- ((fromMaybe 5) Just 6)
fromMaybe (5) -> (Just 6) -> match (Just 6),
  [case Nothing]:   -> 5
  [case Just, "a"]: -> 6

fromMaybe (5) -> (Just 6) -> match (Just 6),
  [{
    type:  Maybe
    const: Nothing
  }]: -> 5
  [{
    type:  Maybe
    const: Just
    save:  {
      [1]: "a"
    }
  }]: -> 6

fromMaybe (5) -> (Just 6) -> match (Just 6),
  [{
    type:  Maybe
    const: Nothing
  }]: -> 5
  [{
    type:  Maybe
    const: Just
    save:  {
      [1]: "a"
    }
  }]: (setfenv (-> 6), (setmetable {a=6}, {__index=_G}))!
