--- Signs functions and does all of the typechecking.
-- @module sign
-- @author daelvn
-- @license MIT
-- @copyright 13.05.2019
import rbinarize, compare, annotate                                                                                 from require "ltypekit.signature"
import typeof, type1, metatype, isTable, isString, verifyList, verifyTable, kindof, typefor, classfor, isInstanceOf from require "ltypekit.type"
import warn, die                                                                                                    from require "ltypekit.util"
import DEBUG                                                                                                        from require "ltypekit.config"
import y, c, p                                                                                                      from DEBUG

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
-- @table msg_
-- @field reading_from_cache `(f,w) -> (name, is, got) -> ...`
-- @field saving_in_cache `(f,w) -> (name, becomes) -> ...`
-- @field modifying_cache `(f,w) -> (from_) -> (to) -> ...`
-- @field expected_cache `(f,w) -> (i, type_, name, got) -> ...`
-- @field expected `(f,w) -> (i, type_, name) -> ...`
-- @field expected_list `(f,w) -> (i, type_, name) -> ...`
-- @field expected_table `(f,w) -> (i, key, value) -> ...`
-- @field malformed `(f,w) -> (name) -> ...`
-- @field unknown_signature `(f,w) -> (i) -> ...`
msg_ =
  reading_from_cache: (f,w) -> (name, is, got) ->
    p c cyan.."! Reading parameter from cache. '#{name}' is #{is} and got #{got}."
  saving_in_cache: (f,w) -> (name, becomes) ->
    p c cyan.."! Saving value in cache. '#{name}' becomes #{becomes}."
  modifying_cache: (f,w) -> (from_) ->
    p (c cyan.."! Modifying cache. From... "), y from_
    (to) -> p y to
  expected_cache: (f,w) -> (i, type_, name, got) ->
    f "Wrong value ##{i}. Expected #{type_} (#{name}), got #{got}."
  expected: (f,w) -> (i, type_, got, cerr="") ->
    f "Wrong value ##{i}. Expected #{type_}, got #{got}. #{cerr}"
  expected_list: (f,w) -> (i, type_, got) ->
    f "Wrong value ##{i}. Expected [#{type_}], got [#{got}]"
  expected_table: (f,w) -> (i, key, value) ->
    f "Wrong value ##{i}. Expected {#{key}:#{value}}, got {?:?}."
  malformed: (f,w) -> (name) ->
    f "Malformed type #{name}."
  unknown_signature: (f,w) -> (i) ->
    w "Argument ##{i} has no known signature."
  autosign: (f,w) -> (i, sn) ->
    w "Automatically signing ##{i} with signature '#{sn}'. This may cause unintended behaviour."
  not_instance_of: (f, w) -> (tag, tc) ->
    f "Value of #{tag} is not an instance of #{tc}."

--- Verifies a type application. **Curried function.**
-- @tparam table a1 Base application.
-- @tparam table cache Cache. Passed alongside a1.
-- @tparam number i Argument number. Passed alongside a1.
-- @tparam table msg Table with error messages.
-- @tparam table a2 Application to compare against.
-- @treturn boolean Whether it could compare.
verifyAppl = (a1, cache, i, msg) -> (a2) ->
  main = a1[1]
  -- applications have a __tostring method
  msg.expected i, a1, typeof a2 unless main == typeof a2
  --
  p "appl1/2", (y a1), (y a2)
  for j=2, #a1
    param  = a1[j]
    xparam = a2[j-1]
    p "p/xparam", j, param, xparam
    if xparam -- Only compare if there's something to compare it to
      if ("table" == type xparam) and ("table" == type param)
        r = (compare param) xparam
        msg.expected j, (tostring param), (tostring xparam) unless r
      elseif param\match "^%l"
        if cache[param]
          msg.reading_from_cache param, cache[param], typeof xparam
          msg.expected_cache j, cache[param], param, typeof xparam unless cache[param] == typeof xparam
        else
          msg.saving_in_cache param, typeof xparam
          cache[param] = typeof xparam
      elseif param\match "^%u"
        msg.expected j, a1, "#{typeof xparam} (##{j})" unless param == typeof xparam
      else
        msg.malformed param
    else -- Otherwise, the constructor might just not have a value for it.
      p "no/param"
      continue
  true

--- Checks the values of a side for `applyArguments`.
-- @tparam table T Node tree (side).
-- @tparam table argl Argument list.
-- @tparam table cache Cache.
-- @tparam table msg Table with error messages.
-- @tparam string isLR Whether it is the `L`eft or `R`ight side.
-- @tparam table C Context (constraints).
-- @treturn table The filtered argument list.
checkSide = (T, argl, cache, msg, isLR, C) ->
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
          -- here goes the context checking
          if cx = C[T[i]]
            for tc in *cx do msg.not_instance_of T[i], tc unless (isInstanceOf (classfor tc)) arg
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
      elseif ns.__appl
        msg.expected i, ns, typeof arg unless (verifyAppl ns, cache, i, msg) arg
        arg_x[i] = arg
      elseif ns.__fn
        switch type1 arg
          when "Function"
            if isLR == "L"
              msg.unknown_signature i
              arg_x[i] = arg
            elseif isLR == "R"
              msg.autosign i, ns.__sig
              arg_x[i] = (sign ns.__sig, {}, cache) arg
          when "Table"
            if "TypeKit" == kindof arg
              cr, cerr = (compare ns) arg.tree
              p "comparef", cr, cerr
              msg.expected i, ns.__sig, (arg.__sig or "unknown"), cerr unless cr
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
  msg   = {k, (v die1, warn1) for k, v in pairs msg_}
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
  arg_i = checkSide L, argl, cache, msg, "L", tree.context
  p "full-argi", y arg_i
  p c blue.."============"
  -- Now run the function
  retv = {constructor.fn (unpack or table.unpack) arg_i}
  p "retv", y retv
  p c blue.."============"
  -- Now run the function
  -- Typecheck the returned values
  arg_o = checkSide R, retv, cache, msg, "R", tree.context
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
    __name: tree.name
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

--- Turns a signed function into a normal function.
-- This will make it look like a normal function to lua, but all information is lost, and therefore makes it unable to be modified.
-- @tparam function(ltypekit) fltk TypeKit function
-- @treturn function Flat function.
flatten = (fltk) -> (...) -> fltk ...

--toNumber = sign "(toNumber) a -> Number"
--toNumber (a) -> tonumber a
--p typeof toNumber "5"
--map      = sign "(map) (a -> b) -> [a] -> [b]"
--map      (f) -> (l) -> [f v for v in *l]
--map1     = sign "(map1) (a -> b) -> (c -> d) -> {a:b} -> {c:d}"
--map1     (fk) -> (fv) -> (t) -> {(fk k), (fv v) for k, v in pairs t}

--p y (map tonumber) {"1", "2", "3"}
--p y ((map1 tostring) tonumber) {"1", "2", "3"}

{ :sign, :impure, :flatten }
