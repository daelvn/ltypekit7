<img width="140" height="128" align="left" src=".github/ltypekit.png">
<h1>ltypekit</h1>

![GitHub](https://img.shields.io/github/license/daelvn/ltypekit7.svg?style=flat-square) ![GitHub stars](https://img.shields.io/github/stars/daelvn/ltypekit7.svg?style=flat-square) ![GitHub issues](https://img.shields.io/github/issues/daelvn/ltypekit7.svg?style=flat-square) ![Mastodon Follow](https://img.shields.io/mastodon/follow/230811.svg?color=429bf4&domain=https%3A%2F%2Fmstdn.io&style=flat-square)

**ltypekit** is a Lua/[MoonScript](http://moonscript.org) library for advanced type checking. Although currently in active development (no, it does not work), planned features include being able to use type signatures with functions, lists and tables; implement custom type checking using *resolvers* and metamethods such as `__type`, typeclasses and instances (polymorphism!), and a list of custom types. All of these are configured easily, for example, type signatures are defined only with a signature string, such as `(a -> b) -> [a] -> [b]`, and with descriptive type errors, all of this should make your program generally safer, and you'll be able to forget about all these assert one-by-one argument checking.

This does not only work for input arguments, it also checks that the returned values are correct, it provides a complete wrapper for functions.

## Documentation
Documentation is generated using LDoc. It might not be the best choice, given some of the functions are curried, but those functions are noted in the documentation, there's just too many! You can read the full documentation [here](https://git.daelvn.ga/ltypekit).

## License
This project is released to the public domain.
<a href="https://icons8.com/icon/11378/moon-and-stars">Moon and Stars icon by Icons8</a>
