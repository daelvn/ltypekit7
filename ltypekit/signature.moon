--- Module for parsing signatures.
-- @module signature
-- @author daelvn
import DEBUG      from require "ltypekit.config"
import init, last from require "ltypekit.util"
import y, c, p    from DEBUG

-- Helper functions
index    = (t) -> (i) ->
  switch type t
    when "table"  then t[i]
    when "string" then t\sub i,i
insert   = (t) -> (v) -> table.insert t, v
remove   = (t) -> (i) -> (e) ->
  x = table.remove t, i
  (x == e) and x or false
concat   = (t) -> (s) ->
  newt = {k, tostring v for k, v in pairs t}
  table.concat newt, s
pack     = (...)      -> {...}
map      = (f) -> (t) -> [f v for v in *t]
unpack or= table.unpack
isUpper  = (s) -> s\match "^%u"
isLower  = (s) -> s\match "^%l"

--- Splits an application.
-- @tparam string appl Type application.
-- @treturn table Parts of the type application.
applSplit = (appl) ->
  return appl if (type appl) != "string"
  return appl if (appl\gsub "%b()", "")\match "[-=]>"
  x = [part for part in appl\gmatch "%S+"]
  x.__appl = true
  setmetatable x, __tostring: => (concat @) " "
  return x if #x > 1 else appl

--- Splits a context string into a table.
-- @tparam string context Context.
-- @treturn table Parts of the context.
contextSplit = (context) -> [constraint for constraint in context\gmatch "[^,()]+"]

--- Split for multiple arguments.
-- @tparam string arg Argument list.
-- @treturn table Parts of the argument list.
multiargSplit = (arg) ->
  return arg if (type arg) != "string"
  x = [applSplit par for par in arg\gmatch "[^,]+"]
  x.__multi = true
  return x if #x > 1 else arg

--- Removes the top-most parens from a string.
-- @tparam string str String.
-- @treturn string String without top-most parentheses.
removeTopMostParens = (str) ->
  return str if (type str) != "string"
  _, countOpen   = str\gsub "%(", ""
  _, countClosed = str\gsub "%)", ""
  if (str\match "^%(") and (str\match "%)$") and (countOpen == 1) and (countClosed == 1)
    return str\sub 2, -2
  str

--- Converts an application into a matchable pattern for comparison.
-- @tparam string cons Application to be compared.
-- @treturn string Pattern.
applToPattern = (cons) ->
  parts = {}
  for word in cons\gmatch "%S+"
    if isLower word
      table.insert parts, "(.-)"
    else
      table.insert parts, word
  table.concat parts, " "

--- Turns any `[x]` into `{"x", __list: true}`
-- @tparam string a List argument.
-- @tparam table c Context.
-- @treturn table A list node.
applyLists = (a, c) ->
  return a if (type a) != "string"
  if list = a\match "^%b[]$"
    {list\sub( 2, -2 ), __list: true, context: c}
  else
    a

--- Turns any `{x:y}` into `{"x", "y", __table: true}`
-- @tparam string a A table argument.
-- @tparam table c Context.
-- @treturn table A table node.
applyTables = (a, c) ->
  return a if (type a) != "string"
  if tbl = a\match "^%b{}$"
    {tbl\match"^{(.-):", tbl\match":(.-)}$", __table: true, context: c}
  else
    a

--- Compares two constraints. Curried function.
-- @tparam string c1 Constraint one.
-- @tparam string c2 Constraint two.
-- @treturn boolean Result of the comparison.
-- @raise Unmatching type application.
compareCons = (c1) -> (c2) ->
  pat1 = applToPattern c1
  if c2\match pat1
    return true
  else
    p "err trig here"
    return false, "compareAppl $ unmatching type application. Expected #{c1}, got #{c2}"

--- Turns the context into an indexable table.
-- @tparam table c context Context.
-- @treturn table Normalized context.
normalizeContext = (c) ->
  final = {}
  for constraint in *c
    parts = [p for p in constraint\gmatch "%S+"]
    final[last parts] = init parts
  final

--- Merges two context tables. **Curried function.**
-- @tparam table c1 Base context.
-- @tparam table c2 Merging context.
-- @treturn table Final context.
mergeContext = (c1) -> (c2) ->
  cf = {k, [ap for ap in *v] for k, v in pairs c1}
  for k, v in pairs c2 do if cf[k] then for ap in *v do table.insert cf[k], ap else cf[k] = v
  return cf

--- Returns a Right and Left part for a function. It may also return a Context.  
-- @tparam string signature Signature to be parsed.
-- @tparam table context Context to be applied to the tree. Defaults to an empty table.
-- @treturn table Node tree for the signature. It has a left field, right field, a context field and optionally a name field.
-- @raise
--   Unmatching parentheses.  
--   Expected '>'.  
--   Unexpected '>'.  
--   Unexpected tag.
binarize = (signature, context={}) ->
  local sigName
  with signature
    signature = \gsub "^(.-)%s*%?%s*", (name) ->
      sigName = name
      return ""
    signature = \gsub " *%-> *",   "->"
    signature = \gsub " *%=> *",   "=>"
    signature = \gsub ",%s",       ","
  signature = removeTopMostParens signature
  local getNext
  -- Tree structure
  tree  = left: "", right: "", context: ""
  right = false
  -- Agglutination
  aggl   = (ch)  -> if right then tree.right ..= ch else tree.left ..= ch
  nextIs = (tag) -> -> tag
  -- Stack operations
  _stack = {}
  push   = insert _stack
  pop    = (remove _stack) 1
  peek   = -> _stack[1]
  -- Depth
  depth = 0
  -- Binarizing loop
  col = 0
  for char in signature\gmatch "."
    col   += 1
    column = index signature
    switch char
      when "("
        depth += 1
        push "par"
        aggl char
      when ")"
        depth -= 1
        error "binarize $ unmatching parentheses at column #{col} in '#{signature}'" if depth < 0
        pop "par"
        aggl char
      when "-"
        if right or depth > 0
          aggl char
          continue
        error "binarize $ expected '>' at column #{col+1} in '#{signature}'" if (column col+1) != ">"
        getNext = nextIs "set-right"
      when "="
        if right or depth > 0
          aggl char
          continue
        error "binarize $ expected '>' at column #{col+1} in '#{signature}'" if (column col+1) != ">"
        getNext = nextIs "set-context"
      when ">"
        if right or depth > 0
          aggl char
          continue
        error "binarize $ unexpected '>' at column #{col} in '#{signature}'" if (column col-1)\match "[^-=]"
        switch getNext!
          when "set-right"
            right = true
          when "set-context"
            tree.context = tree.left
            tree.left    = ""
          else
            error "binarize $ unexpected tag '#{tag}'"
      else
        aggl char
  -- Fix :: x -> () into :: x
  if tree.right == ""
    tree.right = tree.left
    tree.left  = ""
  -- Normalize context
  tree.context = normalizeContext contextSplit tree.context
  for constraint in *context do table.insert tree.context, constraint
  -- Remove top-most parens
  tree = {k, removeTopMostParens v for k, v in pairs tree}
  -- Remove multiarguments
  tree = {k, multiargSplit v for k, v in pairs tree}
  -- Type applications split
  tree = {k, applSplit v for k, v in pairs tree}
  -- Lists
  tree = {k, applyLists v, tree.context for k, v in pairs tree}
  -- Tables
  tree = {k, applyTables v, tree.context for k, v in pairs tree}
  -- Set name
  tree.name = sigName
  --
  tree.__fn  = true
  tree.__sig = signature
  setmetatable tree, __tostring: => @__sig

--- Recursively binarize a signature.
-- @tparam string signature Signature to be recursively binarized.
-- @tparam table context Context to apply to the signature.
-- @tparam boolean topmost Defines whether it is the topmost iteration or not.
-- @treturn table Node tree.
rbinarize = (signature, context={}, topmost=true) ->
  tree = binarize signature, context
  --print "tree: " .. (require "inspect") tree
  if ((type tree.left) == "string") and tree.left\match "[=-]>"
    tree.left = rbinarize tree.left, tree.context, false
  elseif ((type tree.left) == "table") and tree.left.__appl
    tree.left[2] = rbinarize tree.left[2], tree.context, false if tree.left[2]\match "[=-]>"
  elseif ((type tree.left) == "table") and tree.left.__list
    tree.left[1] = rbinarize tree.left[1], tree.context, false if tree.left[1]\match "[=-]>"
  elseif ((type tree.left) == "table") and tree.left.__table
    tree.left[1] = rbinarize tree.left[1], tree.context, false if tree.left[1]\match "[=-]>"
    tree.left[2] = rbinarize tree.left[2], tree.context, false if tree.left[2]\match "[=-]>"
  if ((type tree.right) == "string") and tree.right\match "[=-]>"
    tree.right = rbinarize tree.right, tree.context, false
  elseif ((type tree.right) == "table") and tree.right.__appl
    tree.right[2] = rbinarize tree.right[2], tree.context, false if tree.right[2]\match "[=-]>"
  elseif ((type tree.right) == "table") and tree.right.__list
    tree.right[1] = rbinarize tree.right[1], tree.context, false if tree.right[1]\match "[=-]>"
  elseif ((type tree.right) == "table") and tree.right.__table
    tree.right[1] = rbinarize tree.right[1], tree.context, false if tree.right[1]\match "[=-]>"
    tree.right[2] = rbinarize tree.right[2], tree.context, false if tree.right[2]\match "[=-]>"
  tree

--- Annotates a parameter with a list of constraints.
-- @tparam string par Parameter.
-- @tparam table conl List of constraints.
-- @treturn string Annotated parameter.
annotatePar = (par, conl) ->
  for cons in *conl
    p = [pa for pa in cons\gmatch "%S+"]
    print "annotpar", p[#p], cons
    par = par\gsub p[#p], cons
  par

local compare

--- Compare a type application.
compareAppl = compareCons

isTable  = (t) -> (type t) == "table"
isString = (s) -> (type s) == "string"
--- Compare a type application node.
compareApplN = (base) -> (against) ->
  for part1 in *base do for part2 in *against
    if (isString part1) and (isString part2)
      if part1\match"^%u" and part2\match "^%u"
        return false, "compareApplN $ unmatching type application. got #{part2}, expected #{part1}" unless part1 == part2
    elseif (isTable part1) and (isTable part2)
      return (compare part1) part2
    else
      return false, "compareApplN $ mismatching types in type application. got #{type part2}, expected #{type part1}"
  return true

--- Compare two lists
compareList = (base) -> (against) ->
  t1, t2 = base[1], against[1]
  if (isString t1) and (isString t2)
    if t1\match"^%u" and t2\match"^%u"
      return false, "compareList $ unmatching list. got #{t2}, expected #{t1}" unless t1 == t2
  elseif (isTable t1) and (isTable t2)
    return (compare t1) t2
  else
    return false, "compareList $ mismatching types in list. got #{type t2}, expected #{type t1}"
  return true

--- Compare two tables
compareTable = (base) -> (against) ->
  t1a, t1b, t2a, t2b = base[1], base[2], against[1], against[2]
  if (isString t1a) and (isString t2a)
    if t1a\match"^%u" and t2a\match"^%u"
      return false, "compareTable $ unmatching table key. got #{t2a}, expected #{t1a}" unless t1a == t2a
  elseif (isTable t1a) and (isTable t2a)
    return (compare t1a) t2a
  else
    return false, "compareTable $ mismatching types in table key. got #{type t2a}, expected #{type t1a}"
  if (isString t1b) and (isString t2b)
    if t1b\match"^%u" and t2b\match"^%u"
      return false, "compareTable $ unmatching table value. got #{t2b}, expected #{t1b}" unless t1b == t2b
  elseif (isTable t1b) and (isTable t2b)
    return (compare t1b) t2b
  else
    return false, "compareTable $ mismatching types in table value. got #{type t2b}, expected #{type t1b}"
  return true

isTable  = (t) -> (type t) == "table"
isString = (s) -> (type s) == "string"
isLower  = (s) -> s\match "^%l"
isUpper  = (s) -> s\match "^%u"
hasMulti = (t) -> ((type t) == "table") and t.__multi
--- Compare mixed values (like string and table)
compareMixed = (base) -> (against) ->
  if (isString base) and (isTable against)
    if (isLower base) then return true
    else if against.__appl then return (base == against[#against]) else return false
  else return false

--- Compares the similarity of two signatures. **Curried function.**
-- @tparam table base Base signature.
-- @tparam table against Signature to compare against.
-- @treturn boolean Result of the comparison.
-- @treturn nil|string Error detected.
compare = (base) -> (against) ->
  shape = {}
  p "base",    y base
  p "against", y against
  
  -- rf/1
  --return false, "compare $ base and against are not of the same type. base is #{type base} and against is #{type against}" if (type base) != (type against)
  unless (type base) == (type against)
    p "rf/1"
    return false, "compare $ base and against are not of the same type. base is #{type base} and against is #{type against}"

  -- The compared context should have at least the ones required in the base.
  if base.__fn and against.__fn -- Compare two signatures
    p "compare/fn"
    equalConstraints = 0
    for cons1 in *base.context do for cons2 in *against.context
      p cons1, cons2
      equalConstraints += 1 if (compareCons cons1) cons2
    -- rf/2
    --return false, "compare $ not all constraints matched. got #{equalConstraints}, expected #{#base.context}" unless equalConstraints >= #base.context
    unless equalConstraints >= #base.context
      p "rf/2"
      return false, "compare $ not all constraints matched. got #{equalConstraints}, expected #{#base.context}"
    -- Leftmost part of the signature.
    if (isString base.left) and (isString against.left)
      base.left    = annotatePar base.left,    base.context
      against.left = annotatePar against.left, against.context
      r, err       = (compareAppl base.left)   against.left
      -- rf/3
      -- return false, err unless r
      unless r
        p "rf/3"
        p r, err
        return false, err
    elseif (isTable base.left) and (isTable against.left)
      r, err = (compare base.left) against.left
      -- rf/4
      -- return false, err unless r
      unless r
        p "rf/4"
        return false, err
    else
      -- rf/5
      r, err = (compareMixed base.left) against.left
      unless r
        p "rf/5"
        return false, "compare $ mismatch in left side. base.left is #{type base.left}, against.left is #{type against.left}"
    -- Rightmost part of the signature.
    if (isString base.right) and (isString against.right)
      base.right    = annotatePar base.right,    base.context
      against.right = annotatePar against.right, against.context
      r, err        = (compareAppl base.right)   against.right
      -- rf/6
      -- return false, err unless r
      unless r
        p "rf/6"
        return false, err
    elseif (isTable base.right) and (isTable against.right)
      r, err = (compare base.right) against.right
      -- rf/7
      -- return false, err unless r
      unless r
        p "rf/7"
        p "rf/7", (y base.right), (y against.right)
        return false, err
    else
      r, err = (compareMixed base.right) against.right
      unless r
        p "rf/8"
        p (y base.right), (y against.right)
        return false, "compare $ cannot compare sides. base.right is #{type base.right}, against.right is #{type against.right}"
    --
    return true
  elseif base.__appl and against.__appl -- Compare two type applications
    p "compare/appl"
    r, err = (compareApplN base) against
    -- rf/9
    -- return false, err unless r
    unless r
      p "rf/9"
      return false, err
    return true
  elseif base.__list and against.__list -- Compare two lists
    p "compare/list"
    r, err = (compareList base) against
    -- rf/10
    -- return false, err unless r
    unless r
      p "rf/10"
      return false, err
    return true
  elseif base.__tabapplle and against.__table -- Compare two tables
    p "compare/table"
    r, err = (compareTable base) against
    -- rf/11
    -- return false, err unless r
    unless r
      p "rf/11"
      return false, err
    return true
  else
    -- rf/12
    p "rf/12"
    return false, "compare $ cannot compare base and against"

--- Gets two similar type applications and makes them equal by replacing all parameters with explicit types. **Curried function.**
-- @tparam string ap1 Type application one.
-- @tparam string ap2 Type application two.
-- @treturn string The annotated application.
annotateAppl = (ap1) -> (ap2) -> (cache) ->
  print "appl", ap1, ap2, y cache
  if ap1\match"^%l" and ap2\match"^%u"
    cache[ap1] = ap2
  cache

isNList  = (t) -> t.__list
isNTable = (t) -> t.__table
--- Annotates a node tree using a cache. **Curried function.**
-- @tparam table base Base signature.
-- @tparam table against Signature to annotate against.
-- @tparam table cache Cache table to save the results to.
-- @treturn table The cache table.
annotate = (base) -> (against) -> (cache={},i=1) ->
  print "========================"
  print "annot-base",    i, y base
  print "annot-against", i, y against

  -- Leftmost part of the signature.
  if (isString base.left) and (isString against.left)
    print "annot-l", base.left, against.left
    base.left    = annotatePar base.left, base.context
    against.left = annotatePar against.left, against.context
    print "annot-l-an", base.left, against.left
    cache, err   = ((annotateAppl base.left) against.left) cache
    return false, (err or "l"), 1 unless cache
  elseif (isTable base.left) and (isTable against.left)
    cache, err, n = ((annotate base.left) against.left) cache, i+1
    print "Propagated!"           unless cache
    return false, (err or "L"), n unless cache
  elseif (isNList base) and (isNList against)
    base[1]       = annotatePar base[1], base.context
    against[1]    = annotatePar against[1], against.context
    cache, err, n = ((annotateAppl base[1]) against[1]) cache
    return false, (err or "Rr"), n unless cache
  else
    print "Raised!"
    return false, "annotate $ mismatch in left side. base.left is #{type base.left}, against.left is #{type against.left}", 2
  -- Rightmost part of the signature.
  if (isString base.right) and (isString against.right)
    print "annot-r", base.right, against.right
    base.right    = annotatePar base.right, base.context
    against.right = annotatePar against.right, against.context
    print "annot-r-an", base.right, against.right
    cache, err, n = ((annotateAppl base.right) against.right) cache
    return false, (err or "r"), n unless cache
  elseif (isTable base.right) and (isTable against.right)
    cache, err, n = ((annotate base.right) against.right) cache, i+1
    print "Propagated!" unless cache
    return false, (err or "R"), n unless cache
  elseif (isNList base) and (isNList against)
    base[1]       = annotatePar base[1], base.context
    against[1]    = annotatePar against[1], against.context
    cache, err, n = ((annotateAppl base[1]) against[1]) cache
    return false, (err or "Rr"), n unless cache
  else
    print "Raised!"
    return false, "annotate $ mismatch in right side. base.right is #{type base.right}, against.right is #{type against.right}", 4
  --
  cache, "", 5

if DEBUG
  --print y rbinarize "(test) Tree a, b -> x"
  --print y (compare rbinarize "Tree a => a, b -> x") rbinarize "Tree y => a,b->x"
  --print y rbinarize "(map) (a -> b) -> [a] -> [b]"
  --print y (compare rbinarize "(map) (a -> b) -> [a] -> [b]") rbinarize "(map') (b -> c) -> [b] -> [c]"
  --print y (compare rbinarize "(map) Eq a => (a -> b) -> [a] -> [b]") rbinarize "(map') Ord b => (b -> c) -> [b] -> [c]"

  --print y rbinarize "(map') (a -> b) -> (c -> d) -> {a:b} -> {c:d}"
  --print (compare rbinarize "(invert) {a:b} -> {b:a}") rbinarize "(invert') {k:v} -> {v:k}"
  --print (compare rbinarize "(invert) Eq a => {a:b} -> {b:a}") rbinarize "(invert') Eq k => {k:v} -> {v:k}"
  --print (compare rbinarize "(invert) Eq a => {a:b} -> {b:a}") rbinarize "(invert') Ord k => {k:v} -> {v:k}"
  --print annotatePar "String", {"Eq String"}
  --print annotatePar "a", {"Ord a"}
  --print annotatePar "b", {}
  --p y ((annotate rbinarize "() (a -> b) -> [a] -> [b]") rbinarize "() (Int -> String) -> [Int] -> [String]") {}
  --print "fromMaybe", y rbinarize "(fromMaybe) a -> Maybe a -> a"
  --print "isJust", y rbinarize "(isJust) Maybe a -> Boolean"
  --print "Just", y rbinarize "(Just) a -> Maybe a"
  --print y rbinarize "a -> (a -> c) -> c"
  --p y binarize "Eq Ord a, Ord a => a -> a"
  --print y rbinarize "f (b -> b) -> f b"
  { :contextSplit, :removeTopMostParens, :applToPattern, :binarize, :rbinarize, :annotatePar, :compareAppl, :compare, :annotate, :normalizeContext, :mergeContext }
else
  { :contextSplit, :removeTopMostParens, :applToPattern, :binarize, :rbinarize, :annotatePar, :compareAppl, :compare, :annotate, :normalizeContext, :mergeContext }
