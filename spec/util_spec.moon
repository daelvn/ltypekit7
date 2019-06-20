describe "util functions #util", ->
  import reverse, collect from require "ltypekit.util"
  --
  it "reverses a list", ->
    assert.are.same {3, 2, 1}, reverse {1, 2, 3}
  describe "function currying", ->
    const =           -> 3
    fn    = (x)       -> x + 1
    fn3   = (x, y, z) -> x + y + z
    --
    it "supports zero-depth", ->
      cf = collect const, 0
      assert.are.equal const!, cf!
    it "supports one-depth", ->
      cf = collect fn, 1
      assert.are.equal (fn 5), (cf 5)
    it "supports multiple-depth", ->
      cf = collect fn3, 3
      assert.are.equal (fn3 1, 2, 3), (((cf 1) 2) 3)
