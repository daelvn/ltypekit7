import DEBUG                    from require "ltypekit.config"
import y, c, p, f, filter, mapM from DEBUG
unpack or= table.unpack
print (mapM (filter {"a"})) unpack {"hello", "hallo", "hewwo"}
