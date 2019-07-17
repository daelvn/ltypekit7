--- Implementation of the Monad class in ltypekit7.
-- I hope Roberto Ierusalimschy himself beats me up for this.
import data, typeclass, instance, isInstanceOf from require "ltypekit.typeclass"
import sign, impure                            from require "ltypekit.sign"
import match, case                             from require "ltypekit.match"
import kindof                                  from require "ltypekit.type"
import doGlobal                                from require "ltypekit"
import DEBUG                                   from require "ltypekit.config"
import y, c, p                                 from DEBUG

doGlobal!

compose = sign ". ? (b -> c) -> (a -> b) -> a -> c"
compose (f) -> (g) -> (x) -> f (g x)

const   = sign "const ? a -> b -> a"
const   (x) -> -> x

Maybe = data "Maybe",
  Nothing: ""
  Just:    "a"

Functor = typeclass "Functor f'",
  fmap: => sign @"fmap ? (a -> b) -> f' a -> f' b"
  fc:   => sign @"<$   ? a -> f' b -> f' a"
  -- TODO allow for default implementations
  -- TODO tuple syntax for profunctor stuff and the like. `(Number * Number)`

Applicative = typeclass "Functor f' => Applicative f'",
  pure:    => sign @"pure   ? a -> f' a"
  seqAppl: => sign @"<*>    ? f' (a -> b) -> f' a -> f' b"
  liftA2:  => sign @"liftA2 ? (a -> b -> c) -> f' a -> f' b -> f' c"
  seqR:    => sign @"*>     ? f' a -> f' b -> f' b"
  seqL:    => sign @"<*     ? f' a -> f' b -> f' a"

seqAppl1 = sign "<**> ? Applicative f => f a -> f (a -> b) -> f b"
seqAppl1 -> liftA2 (a) -> (f) -> f a

liftA    = sign "liftA ? Applicative f => (a -> b) -> f a -> f b"
liftA    (f) -> (a) -> pure ((seqAppl f) a)

--liftA3   = sign "(liftA3) Applicative f => (a -> b -> c -> d) -> f a -> f b -> f c -> f d"
--liftA3   (f) -> (a) -> (b) -> (c) -> ((liftA2 f) a) (seqAppl b) c

Monad = typeclass "Applicative m' => Monad m'",
  bind: => sign @">>=    ? m' a -> (a -> m' b) -> m' b"
  pass: => sign @">>     ? m' a -> m' b -> m' b"
  ret:  => sign @"return ? a -> m' a"
  fail: => sign @"fail   ? String -> m' a"

instance Functor, Maybe,
  fmap: (f) -> (aa) -> match aa,
    [case Nothing]:   -> Nothing
    [case Just, "a"]: -> Just f a

instance Applicative, Maybe,
  -- pure
  pure:    Just
  -- <*>
  seqAppl: (ff) -> (aa) -> match ff,
    [case Just, "f"]:   -> (fmap f) m
    [case Nothing]:     -> Nothing
  -- liftA2
  liftA2:  (f) -> (aa)  -> (bb) -> match aa,
    [case Just, "x"]:   -> match bb,
      [case Just, "y"]: -> Just ((f x) y)
      [case bb]:        -> Nothing
    [case aa]:          -> Nothing
  -- *>
  seqR:    (ff) -> (w)  -> match ff,
    [case Just, "_m1"]: -> w
    [case Nothing]:     -> Nothing

instance Monad, Maybe,
  -- >>=
  bind: (aa) -> (k) -> match aa,
    [case Just, "x"]: -> k x
    [case Nothing]:   -> Nothing
  -- >>
  pass: seqR -- *>
  -- fail
  fail: -> Nothing
  -- return
  ret:  pure

kleisli = sign ">=> ? Monad m => (a -> m b) -> (b -> m c) -> a -> m c"
kleisli (m) -> (n) -> (x) -> (bind (m x)) (y) -> n y

f = sign "f ? a -> Maybe b"
f (x) -> Just (x+1)
g = sign "g ? a -> Maybe b"
g (x) -> Just (x+1)
--p y (bind a) f

id = sign "id ? a -> a"
id (x) -> x

--> Functor laws
--       a = Just 5
--- Identity law
--       p y (fmap.Maybe id) a
--       p y id a
--- Composition law
--       add1 = sign "(add1) Number -> Number"
--       add1 (x)->x+1
--       p add2 5
--       p y (fmap.Maybe (compose add1) add1) a
--       fmapf  = fmap.Maybe add1
--       fmapg  = fmap.Maybe add1
--       fmapgf = (compose fmapf) fmapg
--       p y fmapgf a

--> Applicative laws
v = 3
--- Identity law
p y (seqAppl (pure.Maybe id)) v
