--- This example reflects the usage of the Maybe typeclass in MoonScript.
-- It is truly cursed, I am aware.
import data         from require "ltypekit.typeclass"
import sign, impure from require "ltypekit.sign"
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
fromMaybe (d) -> (x) -> switch x
  when Nothing then d
  when x       then x

p! isJust Just 5
p! isJust Nothing

def5 = fromMaybe 5
p! y def5 Just 6
p! y def5 Nothing
