--- Implementation of the Monad class in ltypekit7.
-- I hope Roberto Ierusalimschy himself beats me up for this.
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

compose = sign "(b -> c) -> (a -> b) -> a -> c"
compose (f) -> (g) -> (x) -> f (g x)

const   = sign "a -> b -> a"
const   (x) -> -> x

Maybe = data "Maybe",
  Nothing: ""
  Just:    "a"

Functor = typeclass "Functor f",
  fmap: => sign "(fmap) (a -> b) -> #{@f} a -> #{@f} b"
  fc:   => sign "(<$)   a -> f b -> f a"
  -- TODO allow for default implementations
  -- TODO allow for constraints in typeclass annotations
  -- TODO tuple syntax for profunctor stuff and the like. `(Number * Number)`

Applicative = typeclass "Applicative f",
  pure:    => sign "(pure)   Functor #{@f} => a -> #{@f} a"
  seqAppl: => sign "(<*>)    Functor #{@f} => #{@f} (a -> b) -> #{@f} a -> #{@f} b"
  liftA2:  => sign "(liftA2) Functor #{@f} => (a -> b -> c) -> #{@f} a -> #{@f} b -> #{@f} c"
  seqD1:   => sign "(*>)     Functor #{@f} => #{@f} a -> #{@f} b -> #{@f} b"
  seqD2:   => sign "(<*)     Functor #{@f} => #{@f} a -> #{@f} b -> #{@f} a"

seqAppl1 = sign "(<**>) Applicative f => f a -> f (a -> b) -> f b"
seqAppl1 -> liftA2 (a) -> (f) -> f a

liftA    = sign "(liftA) Applicative f => (a -> b) -> f a -> f b"
liftA    (f) -> (a) -> pure ((seqAppl f) a)

liftA3   = sign "(liftA3) Applicative f => (a -> b -> c -> d) -> f a -> f b -> f c -> f d"
liftA3   (f) -> (a) -> (b) -> (c) -> ((liftA2 f) a) (seqAppl b) c

Monad = typeclass "Monad m",
  bind: => sign "(>>=)    Applicative #{@m} => #{@m} a -> (a -> #{@m} b) -> #{@m} b"
  pass: => sign "(>>)     Applicative #{@m} => #{@m} a -> #{@m} b -> #{@m} b"
  ret:  => sign "(return) Applicative #{@m} => a -> #{@m} a"
  fail: => sign "(fail)   Applicative #{@m} => String -> #{@m} a"
