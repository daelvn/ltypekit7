--- This example reflects the usage of the Maybe typeclass in MoonScript.
-- It is truly cursed, I am aware.
import data         from require "ltypekit.typeclass"
import sign, impure from require "ltypekit.sign"
import match, case  from require "ltypekit.match"
import doGlobal     from require "ltypekit"
import DEBUG        from require "ltypekit.config"

local y, c, p
if DEBUG
  io.stdout\setvbuf "no"
  y = require "inspect"
  c = require "ansicolors"
  p = impure print
else
  p, y, c = (-> ->), (->), (->)

doGlobal!

Maybe = data "Maybe",
  Nothing: ""
  Just:    "a"

isJust = sign "(isJust) Maybe a -> Boolean"
isJust (x) -> switch x
  when Nothing then false
  when x       then true

fromMaybe = sign "(fromMaybe) a -> Maybe a -> a"
fromMaybe (d) -> (x) -> match x,
  [case Nothing]:   ->
    print "nada"
    d
  [case Just, "a"]: ->
    print "todo"
    a

juststr = Just "is string"
print 2
-- Nothing becomes Nothing @string
p! y (fromMaybe "no string") Nothing
print 4
