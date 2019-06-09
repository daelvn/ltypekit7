--- Various util functions for the whole project.
-- @module util
-- @author daelvn
-- @license MIT
-- @copyright 13.05.2019
color = (require "ansicolors") or ((x) -> x\gsub "%%%b{}","")

--- Prints a simple warning.
-- @tparam string s Error message.
warnS  = (s) -> print color "%{yellow}[WARN]  #{s}"
--- Prints a panic message.
-- @tparam string s Error message.
panicS = (s) -> print color "%{red}[ERROR] #{s}"

--- Prints a traceback message with details about name, signature, error and stacktrace.
-- @tparam table self Signed constructor.
-- @tparam string s Error message.
-- @tparam number n Error number.
traceback = (s, n) =>
  infot = {}
  for i=3,6 do infot[i] = debug.getinfo i
  print color "%{red}[ERROR] #{s} (##{n})"
  print color "%{white}        In function: %{yellow}#{@tree.name or infot[3].name}%{white}"
  print color "        Signature:   %{green}'#{@signature or "???"}'"
  print color "        Stack traceback:"
  print color "          %{red}#{infot[3].name}%{white} in #{infot[3].source} at line #{infot[3].currentline}"
  print color "          %{red}#{infot[4].name}%{white} in #{infot[4].source} at line #{infot[4].currentline}"
  print color "          %{red}#{infot[5].name}%{white} in #{infot[5].source} at line #{infot[5].currentline}"
  print color "          %{red}#{infot[6].name}%{white} in #{infot[6].source} at line #{infot[6].currentline}"

--- Prints a traceback and errors. **Curried function.**
-- @tparam table c Signed constructor.
-- @tparam string s Error message.
-- @tparam number n Error number. Passed alongside s.
-- @raise The error passed to the function.
die = (c) -> (s, n) ->
  traceback c, s, n unless c.silent
  error s

--- Prints a traceback message, but as a warning, with details about name, signature, error and stacktrace.
-- @tparam table self Signed constructor.
-- @tparam string s Error message.
-- @tparam number n Warning number.
tracebackWarn = (s, n) =>
  infot = {}
  for i=1,4 do infot[i] = debug.getinfo i
  print color "%{yellow}[WARN] #{s} (##{n})"
  print color "%{white}       In function: %{yellow}#{@tree.name or infot[3].name}%{white}"
  print color "       Signature:   %{green}'#{@signature or "???"}'"
  print color "       Stack traceback:"
  print color "         %{yellow}#{infot[1].name}%{white} in #{infot[1].source} at line #{infot[1].currentline}"
  print color "         %{yellow}#{infot[2].name}%{white} in #{infot[2].source} at line #{infot[2].currentline}"
  print color "         %{yellow}#{infot[3].name}%{white} in #{infot[3].source} at line #{infot[3].currentline}"
  print color "         %{yellow}#{infot[4].name}%{white} in #{infot[4].source} at line #{infot[4].currentline}"

--- Prints a traceback and errors if running in safe mode. **Curried function.**
-- @tparam table c Signed constructor.
-- @tparam string s Error message.
-- @tparam number n Warning number. Passed alsongside s.
warn = (c) -> (s, n) ->
  tracebackWarn c, s, n unless c.silent
  error s                if c.safe

{ :warnS, :panicS, :traceback, :tracebackWarn, :die, :warn }
