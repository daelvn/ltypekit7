--- This example reflects the usage of the Maybe typeclass in MoonScript.
-- It is truly cursed, I am aware.
import data     from require "ltypekit.typeclass"
import sign     from require "ltypekit.sign"
import doGlobal from require "ltypekit"
import DEBUG    from require "ltypekit.config"

local y, c, p
if DEBUG
  io.stdout\setvbuf "no"
  y = require "inspect"
  c = require "ansicolors"
  p = print
else
  p, y, c = (->), (->), (->)

doGlobal!

Maybe = data "Maybe",
  Nothing: ""
  Just:    "a"

just    = Just 5
p y just
nothing = Nothing!
p y nothing
