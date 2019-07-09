import sign from require "ltypekit.sign"
y = require "inspect"

map = sign "(map) (a -> b) -> [a] -> [b]"
map (f) -> (l) -> [f v for v in *l]

y (map tonumber) {"1", "2", "3"}
