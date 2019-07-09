import data, typeclass, instance, isInstanceOf from require "ltypekit.typeclass"
import sign, impure                            from require "ltypekit.sign"
import kindof                                  from require "ltypekit.type"
import doGlobal                                from require "ltypekit"
import DEBUG                                   from require "ltypekit.config"

local y, c, p
if DEBUG
  io.stdout\setvbuf "no"
  y = require "inspect"
  c = require "ansicolors"
  p = impure print
else
  p, y, c = (-> ->), (->), (->)

doGlobal!

Bool = data "Bool",
  True:  ""
  False: ""
  -- these metamethods will be set for all constructors
  __eq: (ag) =>
    switch kindof @
      when "True"  then return "True"  == kindof ag
      when "False" then return "False" == kindof ag
      else              error "Bool.__eq $ Self element is malformed"

Bool1 = data "Bool1",
  True1:  ""
  False1: ""
  --
  __eq: (ag) =>
    switch kindof @
      when "True1"  then return "True1"  == kindof ag
      when "False1" then return "False1" == kindof ag
      else               error "Bool1.__eq $ Self element is malformed"

Eq = typeclass "Eq a", compare: => sign "#{@a} -> #{@a} -> Boolean"
instance Eq, Bool,  compare: (ba) -> (ag) -> ba == ag
instance Eq, Bool1, compare: (ba) -> (ag) -> ba == ag

compare1 = sign "(compare') (Eq a) => a -> a -> Boolean"
compare1 (ba) -> (ag) -> (compare ba) ag

x = compare1 True
p! "c1", y (x), indent: "| "
p! "c2", y (x False), indent: "| "
z = compare1 True1
p! "c3", y (z), indent: "| "
p! "c4", y (z True1), indent: "| "
w = compare1 5
p! "c5", y (w), indent: "> "
p! "c6", y (w True1), indent "> "
