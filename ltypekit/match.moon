--- Implementing pattern matching by abusing table syntax.
-- The idea of this is to implement pattern matching so that we can support things such as `Just x` and then have x
-- availiable in the scope. All it takes is some table magic and parsing.
-- @module match
-- @author daelvn
-- @license MIT
-- @copyright 16.06.2019
import DEBUG                                  from require "ltypekit.config"
import hasMeta, typeof, kindof, isConstructor from require "ltypekit.type"

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

--- Puts a value or case into custom objects that share the same `__eq` function.
Comparable = (x) ->
  if x.__case

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
        this.save   = generateSavePairing hd.parent.constructors[hd.name]
      else
        -- Match value, again.
        this.__mode = "match-value"
        this.type   = typeof hd
        this.value  = jd

--- Given a value and a list of patterns, it calls the function which matches the pattern first.
match = (v, cl) -> v, cl

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
