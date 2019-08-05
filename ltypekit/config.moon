--- Project-wide configuration for ltypekit
-- @module config
-- @author daelvn
unpack or= table.unpack

--- Debugging flag
DEBUG = true

--- Map (vararg).
mapM = (f) -> (...) -> unpack [f v for v in *{...}]

--- Filtering function. Returns nil if v is a string and matches s, otherwise the value. **Curried function.**
-- @tparam table t Filters.
-- @param v The value to filter.
filter = (t) -> (v) ->
  for s in *t
    return nil if (tostring v)\match s
  return v

i, s, f = ->, {}, {"base", "against", "precache?", "argx", "cachex", "constructing-with"}
if DEBUG
  io.stdout\setvbuf "no"
  i               = require "inspect"
  --s               = require "StackTracePlus"
  --debug.traceback = s.stacktrace
return DEBUG and { DEBUG:
  :i, :s, :f
  y: (o) -> i o, depth: 5, process: (path) =>
    switch path[#path]
      when i.KEY
        lk = path[#path-1]
        return nil if lk == "__tostring"
        return nil if lk == "__call"
        return nil if lk == "__parent"
        return nil if lk == "instances"
        return nil if lk == "safe"
        return nil if lk == "silent"
        return nil if lk == "__sig"
        return @
      when i.METATABLE
        return @
      else
        return @
  c: require "ansicolors"
  p: (...) -> print (mapM (filter f)) ...
  :filter, :mapM
} or {
  :i, :s, :f
  p: ->
  y: ->
  c: ->
  f: {}
}
