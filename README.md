# MethodInspector.jl
Julia package to inspect the names and types of method arguments

[![GH Build](https://github.com/bluesmoon/MethodInspector.jl/workflows/CI/badge.svg)](https://github.com/bluesmoon/MethodInspector.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage Status](https://coveralls.io/repos/github/bluesmoon/MethodInspector.jl/badge.svg?branch=main)](https://coveralls.io/github/bluesmoon/MethodInspector.jl?branch=main)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://bluesmoon.github.io/MethodInspector.jl/)

## Quick Usage
```julia
julia> Pkg.add("MethodInspector")

julia> using MethodInspector

julia> # Now you can use arg_names, arg_types, kwarg_names and kwarg_types on any method of a function.
```


See the [docs](https://bluesmoon.github.io/MethodInspector.jl/) for more details on usage.

You'll also find more examples in the [tests/](tests/).
