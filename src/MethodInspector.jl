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
    real_fn_ref = Base.uncompressed_ast(m).code

    if length(real_fn_ref) <= 1 || !isa(real_fn_ref[end-1].args[1] , GlobalRef)
        # This method does not have kwargs
        return Type[]
    end

    if VERSION < v"1.10" || real_fn_ref[end-1].args[1].name != :_apply_iterate
        real_fn_ref = real_fn_ref[end-1].args
    end

    arg_idx = findfirst(a -> GlobalRef == typeof(a) && a.mod == m.module, real_fn_ref)

    if isnothing(arg_idx)
        @warn "Could not find $(m.name) in $(m.module)"
        return Type[]
    end

    real_fn_ref = real_fn_ref[arg_idx]

    real_fn = eval(real_fn_ref)
    real_mt = only(methods(real_fn))

    sig = Base.unwrap_unionall(real_mt.sig)

    last_param = findfirst(p -> p isa DataType && p.name == m.sig.parameters[1].name, sig.parameters)

    params = collect(sig.parameters[2:last_param-1])

    # Get rid of parameters from parameterized types
    for i in 1:length(params)
        while params[i] isa TypeVar
            params[i] = params[i].ub
        end
    end

    return Vector{Type}(params)
end
kwarg_types(m::Union{Vector{Method},Base.MethodList}) = kwarg_types(first(m.ms))


"""
* `kwarg_names(::Method)` → `Symbol[]`
* `kwarg_names(::Base.MethodList)` → `Symbol[]`

Given a method, return the names of all Keyword Arguments of that method.
Alternately, given a MethodList, return the names all all keyword arguments accepted by the method that accepts the most keyword arguments.

### Arguments

`m::Method`
: The method to check for `kwargs`

`mts::Base.MethodList`
: A MethodList (returned by `methods(...)`) to search for keyword arguments.

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
    kwargs = Base.kwarg_decl(m)

    if isa(kwargs, Vector) && length(kwargs) > 0
        kwargs = filter(!occursin("#") ∘ string, kwargs)

        # Keywords *may* not be sorted correctly. We move the vararg one to the end.
        index = something(findfirst(arg -> endswith(string(arg), "..."), kwargs), 0)
        if index > 0
            kwargs[index], kwargs[end] = kwargs[end], kwargs[index]
        end
    end

    return kwargs
end
function kwarg_names(mts::Union{Vector{Method},Base.MethodList})
    potential_args = Symbol[]

    for mt in mts
        kwargs = kwarg_names(mt)

        if length(kwargs) > length(potential_args)
            potential_args = kwargs
        end
    end

    return potential_args
end


"""
* `arg_names(::Method)` → `Symbol[]`
* `arg_names(::Base.MethodList)` → `Symbol[]`

Given a method, return a list of args required by that method.
If given a MethodList instead, use the first Method in that MethodList.

### Arguments

`m::Base.MethodList|Method`
: The Method or MethodList to check for `args`

#### Returns

A `Symbol` array of the args required by the first method passed in. Arg types and default values are not returned.  Functions with no required `args` will return an empty array.

### Examples

```julia
arg_names(foo)
```
"""
arg_names(mts::Union{Vector{Method},Base.MethodList}) = arg_names(first(mts))
arg_names(mt::Method)   = Base.method_argnames(mt)[2:end]



"""
* `arg_types(::Method)` → `Type[]`

Given a method, return the datatype of all its positional arguments.

### Arguments

`m::Base.MethodList|Method`
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
    type_tuple = Base.arg_decl_parts(mt)

    type_strings = map(x -> x[2], filter(x -> !isempty(x[1]), type_tuple[2]))
    type_params  = type_tuple[1]

    return convert(Vector{Type}, map(type_strings) do arg_type
        if isempty(arg_type)
            return Any
        else
            # Now replace any parameters that didn't have a parent type (i.e., were just Any)
            for type_param in type_params
                param = type_param.name
                ub    = type_param.ub

                arg_type = replace(arg_type, Regex("(?:<:)?\\b$(param)\\b") => "<:$(ub)")
            end

            return eval(Meta.parse(arg_type))
        end
    end)
end
arg_types(mts::Union{Vector{Method},Base.MethodList}) = arg_types(first(mts))

end