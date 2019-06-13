--- Signs functions and does all of the typechecking.
-- @module sign
-- @author daelvn
-- @license MIT
-- @copyright 13.05.2019
import rbinarize, compare, annotate                                                from require "ltypekit.signature"
import typeof, type1, metatype, isTable, isString, verifyList, verifyTable, kindof from require "ltypekit.type"
import warn, die                                                                   from require "ltypekit.util"
import DEBUG                                                                       from require "ltypekit.config"

local y, c, p
if DEBUG
  io.stdout\setvbuf "no"
  y = require "inspect"
  c = require "ansicolors"
  p = print
else
  p, y, c = (->), (->), (->)

local sign

--- Resolves a type using the cache, only for display purposes.
resolveCache = (str, cache) ->
  for k, v in pairs cache
    str = str\gsub k, v
  str

cyan    = "%{cyan}"
yellow  = "%{yellow}"
green   = "%{green}"
magenta = "%{magenta}"
blue    = "%{blue}"
--- A table to contain all debug, warning, and error messages.
-- @table msg
-- @field reading_from_cache `(f,w) -> (name, is, got) -> ...`
-- @field saving_in_cache `(f,w) -> (name, becomes) -> ...`
-- @field modifying_cache `(f,w) -> (from_) -> (to) -> ...`
-- @field expected_cache `(f,w) -> (i, type, name, got) -> ...`
-- @field expected `(f,w) -> (i, type, name) -> ...`
-- @field expected_list `(f,w) -> (i, type, name) -> ...`
-- @field expected_table `(f,w) -> (i, key, value) -> ...`
-- @field malformed `(f,w) -> (name) -> ...`
-- @field unknown_signature `(f,w) -> (i) -> ...`
msg =
  reading_from_cache: (f,w) -> (name, is, got) ->
    p c cyan.."! Reading parameter from cache. '#{name}' is #{is} and got #{got}."
  saving_in_cache: (f,w) -> (name, becomes) ->
    p c cyan.."! Saving value in cache. '#{name}' becomes #{becomes}."
  modifying_cache: (f,w) -> (from_) ->
    p (c cyan.."! Modifying cache. From... "), y from_
    (to) -> p y to
  expected_cache: (f,w) -> (i, type, name, got) ->
    f "Wrong value ##{i}. Expected #{type} (#{name}), got #{got}."
  expected: (f,w) -> (i, type, got) ->
    f "Wrong value ##{i}. Expected #{type}, got #{got}."
  expected_list: (f,w) -> (i, type, got) ->
    f "Wrong value ##{i}. Expected [#{type}], got [#{got}]"
  expected_table: (f,w) -> (i, key, value) ->
    f "Wrong value ##{i}. Expected {#{key}:#{value}}, got {?:?}."
  malformed: (f,w) -> (name) ->
    f "Malformed type #{name}."
  unknown_signature: (f,w) -> (i) ->
    w "Argument ##{i} has no known signature."

--- Checks the values of a side for `applyArguments`.
-- @tparam table T Node tree (side).
-- @tparam table argl Argument list.
-- @tparam table cache Cache.
-- @treturn table The filtered argument list.
checkSide = (T, argl, cache) ->
  arg_x = {}
  for i, arg in ipairs argl
    p "argx", i, (typeof arg), y arg
    p "Ti", y T[i]
    p "cachex", y cache
    if isString T[i]
      if T[i]\match "^%l"
        if cache[T[i]]
          msg.reading_from_cache T[i], cache[T[i]], typeof arg
          msg.expected_cache i, cache[T[i]], T[i], typeof arg unless cache[T[i]] == typeof arg
        else
          msg.saving_in_cache T[i], typeof arg
          cache[T[i]] = typeof arg
        arg_x[i] = arg
      elseif T[i]\match "^%u"
        msg.expected i, T[i], typeof arg unless T[i] == typeof arg
        arg_x[i] = arg
      else
        msg.malformed T[i]
    else
      ns = T[i]
      if ns.__list
        msg.expected_list i, (resolveCache ns[1], cache), typeof arg[1] unless (verifyList ns, cache) arg
        arg_x[i] = arg
      elseif ns.__table
        msg.expected_table i, (resolveCache ns[1], cache), (resolveCache ns[2], cache) unless (verifyTable ns, cache) arg
        arg_x[i] = arg
      elseif ns.__fn
        switch type1 arg
          when "Function"
            msg.unknown_signature i
            arg_x[i] = arg
          when "Table"
            if "TypeKit" == kindof arg
              msg.expected i, ns.__sig, (arg.__sig or "unknown") unless (compare ns) arg.tree
              u = msg.modifying_cache cache
              cache    = ((annotate ns) arg.tree) cache
              u cache
              arg_x[i] = arg
            else
              p y arg
              msg.expected i, ns.__sig, typeof arg
          else
            msg.expected i, ns.__sig, typeof arg
  arg_x
--- Applies arguments to to a function and checks the types of the inputs and outputs. **Curried function.**
-- It returns whatever the function is supposed to return.
-- @tparam table constructor Signed constructor.
-- @tparam table argl List of arguments.
-- @tparam table cache Cache to initialize the application with. Passed alongside argl.
-- @return ...
applyArguments = (constructor) -> (argl, cache={}) ->
  p c yellow.."@ Applying arguments to #{constructor.signature}"
  die1  = die constructor
  warn1 = warn constructor
  msg   = {k, (v die1, warn1) for k, v in pairs msg}
  -- Tree elements
  tree = constructor.tree
  L, R = tree.left, tree.right
  -- Check that they are the same length.
  if (isTable L) and L.__multi
    if #L < #argl
      warn1 "Passed too many arguments to function. Expected #{#L}, got #{#argl}", 1
    elseif #L > #argl
      die1 "Did not pass enough arguments to function. Expected #{#L}, got #{#argl}", 2
  else
    L = {L}
  unless (isTable R) and R.__multi
    R = {R}
  -- Next, check that all arguments are the expected type or compatible.
  arg_i = checkSide L, argl, cache
  p "full-argi", y arg_i
  p c blue.."============"
  -- Now run the function
  retv = {constructor.fn (unpack or table.unpack) arg_i}
  p "retv", y retv
  p c blue.."============"
  -- Now run the function
  -- Typecheck the returned values
  arg_o = checkSide R, retv, cache
  p "argo-full", y arg_o
  return (unpack or table.unpack) arg_o

--- Signs functions.
-- @tparam string signature Signature to apply.
-- @tparam table context Context to sign the function with. Defaults to an empty table.
-- @tparam table cache Cache to initialize the application with. Defaults to an empty table.
-- @treturn table Signed constructor.
-- @usage Set a function to sign with a signature, then call that placeholder with the actual function definition, and then you can use it as a normal function.
sign = (signature, context={}, cache) ->
  p c green.."# Creating signed constructor for #{signature}"
  tree = rbinarize signature, context
  setmetatable {
    :signature
    :tree
    name: tree.name
    type: typeof
    fn:   (->)
    --
    safe:   false
    silent: false
  }, {
    __type: "SignedConstructor"
    __kind: "TypeKit"
    __call: (...) =>
      if "SignedConstructor" == typeof @
        argl = {...}
        @fn = ("Function" == typeof argl[1]) and argl[1] or error "sign $ Invalid function passed to signed constructor for '#{@signature}', got #{typeof argl[1]}."
        p c yellow.."@ Setting function for #{@signature}"
        (metatype "Function") @
      elseif "Function" == typeof @
        p "precache?", y argl
        argl = {...}
        p (c yellow.."@ Calling function #{@signature}"), y argl
        p (c magenta.."= Using cache"), y (cache or {})
        return (applyArguments @) argl, (cache or {})
      else
        error "sign $ Self is unknown type #{typeof @}"
  }

--- Makes a function "impure". Adds a `!` marker to it when calling.
-- @tparam function f Any function.
-- @usage
--   printx  = impure sign "a -> Boolean"
--   printx! (a) -> print a
--   printx! "string"
impure = (f) -> -> f

--toNumber = sign "(toNumber) a -> Number"
--toNumber (a) -> tonumber a
--p typeof toNumber "5"
--map      = sign "(map) (a -> b) -> [a] -> [b]"
--map      (f) -> (l) -> [f v for v in *l]
--map1     = sign "(map1) (a -> b) -> (c -> d) -> {a:b} -> {c:d}"
--map1     (fk) -> (fv) -> (t) -> {(fk k), (fv v) for k, v in pairs t}

--p y (map tonumber) {"1", "2", "3"}
--p y ((map1 tostring) tonumber) {"1", "2", "3"}

{ :sign, :impure }
