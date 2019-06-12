--- Main functions of the module, required for interoperation between them, or to enable optional features.
-- @module init
-- @author daelvn
-- @license MIT
-- @copyright 12.06.2019
import metaindex from require "ltypekit.type"

--- Enables the use of global referencing
-- @see data
-- @treturn table `_G`
doGlobal = ->
  _G.__ref or= {}
  (metaindex _G.__ref) _G

{ :doGlobal }
