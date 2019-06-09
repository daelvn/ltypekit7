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
  p = ->

local sign

--- Applies arguments to to a function and checks the types of the inputs and outputs. **Curried function.**
-- It returns whatever the function is supposed to return.
-- @tparam table constructor Signed constructor.
-- @tparam table argl List of arguments.
-- @tparam table cache Cache to initialize the application with. Passed alongside argl.
-- @return ...
-- @todo List and table validation should be annotated (String instead of a).
applyArguments = (constructor) -> (argl, cache={}) ->
  p c "%{yellow}@ Applying arguments to #{constructor.signature}"
  die1  = die constructor
  warn1 = warn constructor
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
  arg_i = {}
  for i, arg in ipairs argl
    p "argi", i, (typeof arg), y arg
    p "Li", y L[i]
    p "cachei", y cache
    if isString L[i]
      if L[i]\match "^%l"
        if cache[L[i]]
          p c "%{cyan}! Reading parameter from cache. '#{L[i]} is #{cache[L[i]]} and got #{typeof arg}."
          die1 "Wrong argument ##{i} to function. Expected #{cache[L[i]]} (#{L[i]}), got #{typeof arg}.", 3 unless cache[L[i]] == typeof arg
        else
          p c "%{cyan}! Saving argument in cache. '#{L[i]}' becomes #{typeof arg}"
          cache[L[i]] = typeof arg
        arg_i[i] = arg
      elseif L[i]\match "^%u"
        die1 "Wrong argument ##{i} to function. Expected #{L[i]}, got #{typeof arg}.", 4 unless L[i] == typeof arg
        arg_i[i] = arg
      else
        die1 "Malformed type #{L[i]}.", 5
    else
      ns = L[i]
      if ns.__list
        p "verlist", (verifyList ns) arg
        die1 "Wrong argument ##{i} to function. Expected [#{ns[1]}], got [#{typeof arg[1]}].", 6 unless (verifyList ns) arg
        arg_i[i] = arg
      elseif ns.__table
        die1 "Wrong argument ##{i} to function. Expected {#{ns[1]}:#{ns[2]}}, got {?:?}.", 7 unless (verifyTable ns) arg
        arg_i[i] = arg
      elseif ns.__fn
        switch type1 arg
          when "Function"
            warn1 "Argument ##{i} passed has no known signature.", 8
            arg_i[i] = arg
          when "Table"
            if "TypeKit" == kindof arg
              die1 "Wrong argument ##{i} to function. Expected #{ns.__sig}, got #{arg.__sig or "no signature"}.", 9 unless (compare ns) arg.tree
              cache    = ((annotate ns) arg.tree) cache
              arg_i[i] = arg
            else
              p y arg
              die1 "Wrong argument ##{i} to function. Expected #{ns.__sig}, got #{typeof arg}.", 10
          else
            die1 "Wrong argument ##{i} to function. Expected #{ns.__sig}, got #{typeof arg}.", 11
        
  p "full-argi", y arg_i
  p c "%{blue}============"
  -- Now run the function
  retv = {constructor.fn (unpack or table.unpack) arg_i}
  p "retv", y retv
  p c "%{blue}============"
  -- Now run the function
  -- Typecheck the returned values
  arg_o = {}
  for i, arg in ipairs retv
    p "argo", i, (typeof arg), y arg
    p "Ri", y R[i]
    p "cacheo", y cache
    if isString R[i]
      if R[i]\match "^%l"
        if cache[R[i]]
          p c "%{cyan}! Reading parameter from cache. '#{R[i]} is #{cache[R[i]]} and got #{typeof arg}."
          die1 "Wrong return value ##{i} from function. Expected #{cache[R[i]]} (#{R[i]}), got #{typeof arg}.", 12 unless cache[R[i]] == typeof arg
        else
          p c "%{cyan}! Saving parameter in cache. '#{L[i]}' becomes #{typeof arg}"
          cache[R[i]] = typeof arg
        arg_o[i] = arg
      elseif R[i]\match "^%u"
        die1 "Wrong return value ##{i} from function. Expected #{R[i]}, got #{typeof arg}", 13 unless R[i] == typeof arg
        arg_o[i] = arg
      else
        die1 "Malformed type #{R[i]}.", 14
    else
      ns = R[i]
      if ns.__list
        die1 "Wrong return value ##{i} to function. Expected [#{ns[1]}], got [#{typeof arg[1]}].", 15 unless (verifyList ns) arg
        arg_o[i] = arg
      elseif ns.__table
        die1 "Wrong return value ##{i} to function. Expected {#{ns[1]}:#{ns[2]}}, got {?:?}.", 16 unless (verifyTable ns) arg
        arg_o[i] = arg
      elseif ns.__fn
        p "hit it", type1 arg
        switch type1 arg
          when "Function"
            p "yeetus"
            warn1 "Return value ##{i} returned has no known signature. Automatically signing. This may have unintended consequences.", 17
            arg_o[i] = (sign "(#{constructor.tree.name}) "..ns.__sig, {}, cache) arg
            p "reach?", y arg_o[i]
          when "Table"
            if arg.tree
              die1 "Wrong return value ##{i} to function. Expected #{ns.__sig}, got #{arg.__sig or "no signature"}.", 18 unless (compare ns) arg.tree
              arg_o[i] = arg
            else
              die1 "Wrong return value ##{i} to function. Expected #{ns.__sig}, got #{typeof arg}.", 19
          else
            die1 "Wrong return value ##{i} to function. Expected #{ns.__sig}, got #{typeof arg}.", 20
  p "argo-full", y arg_o
  return (unpack or table.unpack) arg_o

--- Signs functions.
-- @tparam string signature Signature to apply.
-- @tparam table context Context to sign the function with. Defaults to an empty table.
-- @tparam table cache Cache to initialize the application with. Defaults to an empty table.
-- @treturn table Signed constructor.
-- @usage Set a function to sign with a signature, then call that placeholder with the actual function definition, and then you can use it as a normal function.
sign = (signature, context={}, cache={}) ->
  p c "%{green}# Creating signed constructor for #{signature}"
  setmetatable {
    :signature
    tree: rbinarize signature, context
    type: typeof
    fn:   (->)
    --
    safe:   false
    silent: false
  }, {
    __type: "SignedConstructor"
    __kind: "TypeKit"
    __call: (...) =>
      argl = {...}
      if "SignedConstructor" == typeof @
        @fn = ("Function" == typeof argl[1]) and argl[1] or error "sign $ Invalid function passed to signed constructor for '#{@signature}', got #{typeof argl[1]}."
        p c "%{yellow}@ Setting function for #{@signature}"
        (metatype "Function") @
      elseif "Function" == typeof @
        p (c "%{yellow}@ Calling function #{@signature}"), y argl
        p (c "%{magenta}= Using cache"), y cache
        return (applyArguments @) argl, cache
      else
        error "sign $ Self is unknown type #{typeof @}"
  }

impure = (f) -> -> f

toNumber = sign "(toNumber) a -> Number"
toNumber (a) -> tonumber a
map      = sign "(map) (a -> b) -> [a] -> [b]"
map      (f) -> (l) -> [v for v in *l]

p y (map toNumber) {"1", "2", "3"}

{ :sign, :impure }
