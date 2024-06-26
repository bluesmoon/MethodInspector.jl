"""
Inspect the names and types of positional and keyword arguments to a method
"""
module MethodInspector

export
    kwarg_types,
    kwarg_names,
    arg_types,
    arg_names

"""
* `kwarg_names(::Method)` → `Symbol[]`

Given a method, return the names of all Keyword Arguments of that method.

### Arguments

`m::Method`
: The method to check for `kwargs`

### Returns

A `Symbol` array of the kwargs supported by method `m`. Arg types can be fetched using [`kwarg_types`](@ref) which returns types in the same order.
Default values are not returned. Methods that do not support `kwargs` will return an empty array.

### Examples

```julia
kwarg_names(methods(foo).ms[1])

kwarg_names(methods(foo, (Int,), MyModule))
```
"""
function kwarg_names(m::Method)
    real_fn = Base.bodyfunction(m)
    isnothing(real_fn) && return Symbol[]

    kwargs = arg_names(methods(real_fn))
    delimiter = something(findfirst(==(Symbol("")), kwargs), length(kwargs)+1)

    return kwargs[1:delimiter-1]
end
function kwarg_names(mts::Union{Vector{Method},Base.MethodList})
    for m in mts
        if !isnothing(Base.bodyfunction(m))
            return kwarg_names(m)
        end
    end
    return Symbol[]
end


"""
* `arg_names(::Method)` → `Symbol[]`

Given a method, return a list of args required by that method.

### Arguments

`m::Method`
: The Method or MethodList to check for `args`

#### Returns

A `Symbol` array of the args required by the first method passed in. Arg types and default values are not returned.  Functions with no required `args` will return an empty array.

### Examples

```julia
arg_names(foo)
```
"""
arg_names(mts::Union{Vector{Method},Base.MethodList}) = arg_names(first(mts))
arg_names(mt::Method) = Base.method_argnames(mt)[2:end]



"""
* `kwarg_types(::Method)` → `Type[]`

Given a Method, return a list of types of the keyword warguments supported by that method.

### Arguments

`m::Method`
: The method to check for `kwargs`

### Returns

A `Type` array of the kwarg types supported by method `m`. Arg names can be fetched using [`kwarg_names`](@ref). Both functions will
return values in the same order. Methods that do not support `kwargs` will return an empty array.

### Examples

```julia
kwarg_types(foo)
```
"""
function kwarg_types(m::Method)
    real_fn = Base.bodyfunction(m)
    isnothing(real_fn) && return Type[]

    real_mt = only(methods(real_fn))

    m_name = Base.unwrap_unionall(m.sig).parameters[1].name
    sig = Base.unwrap_unionall(real_mt.sig)

    last_param = findfirst(p -> p isa DataType && p.name == m_name, sig.parameters)

    _params2vec(sig.parameters[2:last_param-1])
end
function kwarg_types(mts::Union{Vector{Method},Base.MethodList})
    for m in mts
        if !isnothing(Base.bodyfunction(m))
            return kwarg_types(m)
        end
    end
    return Type[]
end


"""
* `arg_types(::Method)` → `Type[]`

Given a method, return the datatype of all its positional arguments.

### Arguments

`m::Method`
: The Method or MethodList to check for `args`

### Returns

A `Type` array of the arg types supported by method `m`. Arg names can be fetched using [`arg_names`](@ref). Both functions will
return values in the same order. Methods that do not support `args` will return an empty array.

### Examples

```julia
arg_types(foo)
```
"""
function arg_types(mt::Method)
    sig = Base.unwrap_unionall(mt.sig)

    _params2vec(sig.parameters[2:end])
end
arg_types(mts::Union{Vector{Method},Base.MethodList}) = arg_types(first(mts))


"""
Unwrap a `TypeVar` into its upper type
"""
unwrap_typevar(x::TypeVar) = unwrap_all(x.ub)

"""
Unwrap the components of a `Union` type to non-parametrized types
"""
unwrap_union(x::Union) = Union{unwrap_all(x.a), unwrap_all(x.b)}

"""
Generic method to call the appropriate unwrapper for the given type
"""
unwrap_all(x)           = Base.unwrapva(x)
unwrap_all(x::DataType) = (x = Base.unwrapva(x); x.name.name == :NamedTuple ? x : isempty(x.parameters) ? x : x.name.wrapper{map(unwrap_all, x.parameters)...})
unwrap_all(x::Union)    = unwrap_union(x)
unwrap_all(x::TypeVar)  = unwrap_all(unwrap_typevar(x))
unwrap_all(x::UnionAll) = unwrap_all(Base.unwrap_unionall(x))


# Internal method to convert its parameters to a Vector{Type}
_params2vec(params::Core.SimpleVector) = convert(Vector{Type}, map(unwrap_all, params))

end
