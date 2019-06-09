--> # ltypekit7
--> Advanced type checking library for Lua.
-- ltypekit.7/associative
-- By daelvn
-- 15.05.2019

--> # Associative Pairing
--> Creates a structure `Associative` that supports multiple keys and reverse searching.

--> # Associative
--> Creates an associative list.
Associative = (base={}) -> {:base, reverse: {v,k for k,v in pairs base}, keys: {}}

--> # indexAssoc
--> Indexes an associative list.
indexAssoc

--> # insertAssoc
--> Inserts an element in an associative list.
--insertAssoc = (al) -> (k, v) ->
