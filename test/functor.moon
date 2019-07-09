--- This example tries to use Functors in MoonScript.
-- It is truly cursed, I am aware.
import data, typeclass, instance from require "ltypekit.typeclass"
import sign, impure              from require "ltypekit.sign"
import match, case               from require "ltypekit.match"
import doGlobal                  from require "ltypekit"
import DEBUG                     from require "ltypekit.config"

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

Functor = typeclass "Functor f", fmap: => sign "(fmap) (a -> b) -> #{@f} a -> #{@f} b"
instance Functor, Maybe,         fmap: (f) -> (m) -> match m,
  [case Nothing]:   -> Nothing
  [case Just, "a"]: -> Just (f a)

add = sign "Number -> Number -> Number"
add (x) -> (y) -> x + y

p! y (fmap.Maybe (add 5)) (Just 10)
