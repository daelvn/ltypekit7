--- Module for parsing signatures.
-- @module signature
-- @author daelvn
-- @license MIT
-- @copyright 09.05.2019
import DEBUG from require "ltypekit.config"

local y
if DEBUG
  io.stdout\setvbuf "no"
  y = require "inspect"

-- Helper functions
index    = (t) -> (i) ->
  switch type t
    when "table"  then t[i]
    when "string" then t\sub i,i
insert   = (t) -> (v) -> table.insert t, v
remove   = (t) -> (i) -> (e) ->
  x = table.remove t, i
  (x == e) and x or false
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
  return appl if appl\match "[-=]>"
  x = [part for part in appl\gmatch "%S+"]
  x.__appl = true
  setmetatable x, __tostring: => table.concat @, " "
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
  return (c2\match pat1) and true or unpack {false, "compareAppl $ unmatching type application. Expected #{c1}, got #{c2}."}

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
    signature = \gsub " *%-> *",   "->"
    signature = \gsub " *%=> *",   "=>"
    signature = \gsub ",%s",       ","
    signature = \gsub "^%(([^>]-)%) *", (name) ->
      sigName = name
      ""
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
  tree.context = contextSplit tree.context
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
  tree

--- Recursively binarize a signature.
-- @tparam string signature Signature to be recursively binarized.
-- @tparam table context Context to apply to the signature.
-- @tparam boolean topmost Defines whether it is the topmost iteration or not.
-- @treturn table Node tree.
rbinarize = (signature, context={}, topmost=true) ->
  tree = binarize signature, context
  -- print "tree: " .. (require "inspect") tree
  if ((type tree.left) == "string") and tree.left\match "[=-]>"
    tree.left = rbinarize tree.left, tree.context, false
  if ((type tree.right) == "string") and tree.right\match "[=-]>"
    tree.right = rbinarize tree.right, tree.context, false
  tree

--- Annotates a parameter with a list of constraints.
-- @tparam string par Parameter.
-- @tparam table conl List of constraints.
-- @treturn string Annotated parameter.
annotatePar = (par, conl) ->
  getParameter = (con) ->
    p  = [pa for pa in con\gmatch "%S+"]
    po = [pl for pl in *p[,#p-1]]
    p[#p], table.concat po, " "
  parts = [word for word in par\gmatch "%S+"]
  final = {}
  for part in *parts
    for con in *conl
      if part == getParameter con
        table.insert final, select 2, getParameter con
      else
        table.insert final, part
  table.concat final, " "
annotatePar = (par, conl) ->
  for cons in *conl
    p = [pa for pa in cons\gmatch "%S+"]
    print "annotpar", p[#p], cons
    par = par\gsub p[#p], cons
  par

--> # compareAppl
--> Compare a type application.
--compareAppl = (base) -> (against) ->
--  baseWords    = [word for word in base\gmatch "%S+"]
--  againstWords = [word for word in against\gmatch "%S+"]
--  equalWords   = 0
--  for word1 in *baseWords do for word2 in *againstWords
--    equalWords += 1 if word1 == word2
--  return false, "compareAppl $ unmatching type application. got #{against}, expected #{base}" unless equalWords >= base\len!
--  true
compareAppl = compareCons

isTable  = (t) -> (type t) == "table"
isString = (s) -> (type s) == "string"
--- Compares the similarity of two signatures. **Curried function.**
-- @tparam table base Base signature.
-- @tparam table against Signature to compare against.
-- @treturn boolean Result of the comparison.
-- @treturn nil|string Error detected.
compare = (base) -> (against) ->
  shape = {}
  print "base",    y base
  print "against", y against
  
  isTable  = (t) -> (type t) == "table"
  isString = (s) -> (type s) == "string"
  hasMulti = (t) -> ((type t) == "table") and t.__multi
  -- The compared context should have at least the ones required in the base.
  equalConstraints = 0
  for cons1 in *base.context do for cons2 in *against.context
    print cons1, cons2
    equalConstraints += 1 if (compareCons cons1) cons2
  return false, "compare $ not all constraints matched. got #{equalConstraints}, expected #{#base.context}" unless equalConstraints >= #base.context
  -- Leftmost part of the signature.
  if (isString base.left) and (isString against.left)
    base.left    = annotatePar base.left,    base.context
    against.left = annotatePar against.left, against.context
    r, err       = (compareAppl base.left)   against.left
    return false, err unless r
  elseif (isTable base.left) and (isTable against.left)
    r = (compare base.left) against.left
  else
    return false, "compare $ mismatch in left side. base.left is #{type base.left}, against.left is #{type against.left}"
  -- Rightmost part of the signature.
  if (isString base.right) and (isString against.right)
    base.right    = annotatePar base.right,    base.context
    against.right = annotatePar against.right, against.context
    r, err        = (compareAppl base.right)   against.right
    return false, err unless r
  elseif (isTable base.right) and (isTable against.right)
    r = (compare base.right) against.right
  else
    return false, "compare $ mismatch in right side. base.right is #{type base.right}, against.right is #{type against.right}"
  --
  true

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
  --print y ((annotate rbinarize "() (a -> b) -> [a] -> [b]") rbinarize "() (Int -> String) -> [Int] -> [String]") {}
  --print "fromMaybe", y rbinarize "(fromMaybe) a -> Maybe a -> a"
  --print "isJust", y rbinarize "(isJust) Maybe a -> Boolean"
  --print "Just", y rbinarize "(Just) a -> Maybe a"
  --print y rbinarize "a -> (a -> c) -> c"
  { :contextSplit, :removeTopMostParens, :applToPattern, :binarize, :rbinarize, :annotatePar, :compareAppl, :compare, :annotate }
else
  { :contextSplit, :removeTopMostParens, :applToPattern, :binarize, :rbinarize, :annotatePar, :compareAppl, :compare, :annotate }
