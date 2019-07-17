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

--- Attaches the main ltypekit functions into _G.__ref
importAll = ->
  import data, typeclass, instance from require "ltypekit.typeclass"
  import sign, impure, flatten     from require "ltypekit.sign"
  import match, case               from require "ltypekit.match"
  import typeof, type1, typefor    from require "ltypekit.type"
  _G.__ref.data      = data
  _G.__ref.typeclass = typeclass
  _G.__ref.instance  = instance
  _G.__ref.sign      = sign
  _G.__ref.impure    = impure
  _G.__ref.flatten   = flatten
  _G.__ref.match     = match
  _G.__ref.case      = case
  _G.__ref.typeof    = typeof
  _G.__ref.type1     = type1
  _G.__ref.typefor   = typefor

{ :doGlobal, :importAll }
