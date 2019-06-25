describe "signature parsing #signature", ->
  import binarize, rbinarize, compare, annotate from require "ltypekit.signature"
  --
  describe "signature binarizing #binarize", ->
    it "binarizes simple signatures", ->
      assert.are.same (binarize "a -> b"),
        __fn:    true
        __sig:   "a -> b"
        context: {}
        left:    "a"
        right:   "b"
      assert.are.same (binarize "(a -> b) -> c"),
        __fn:    true
        __sig:   "(a -> b) -> c"
        context: {}
        left:    "(a -> b)"
        right:   "c"
