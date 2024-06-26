using MethodInspector, Test, InteractiveUtils

test_nokw() = "0_0k"
test_nokw(a::Vector{<:Real}) = "1cp_0k"
test_nokw(a::Int, b::Vector{<:T}) where T = "1vp_0k"
test_nokw(a::Char, b::Vector{T}) where T <: Real = "1vp_0k"
test_nokw(a::Float64, b::Tuple{<:T,<:Real}) where T <: AbstractString = "1vp_0k"
test_nokw(a::Bool, b::Tuple{<:Real,U}) where U = "1vp_0k"
test_nokw(a::Unsigned, b::Tuple{<:Real,U,<:V}) where {U, V<:AbstractFloat} = "1vp_0k"
test_nokw(a::Signed, b...) = "1vp_1va_0k"
test_nokw(a::Union{Vector{<:Complex},Vector{<:AbstractString}}) = "1u"

test_kw()  = "0_0k"
test_kw(a) = "1_0k"
test_kw(a::Int) = "1t_0k"
test_kw(a::Bool; b=10) = "1t_1k"
test_kw(a::Char; b::Int=20) = "1t_1tk"
test_kw(a::Float64, b::Char='a'; c::Int=30) = "1t_1d_1tk"
test_kw(a::AbstractString, b...; c::Int=30) = "1t_1v_1tk"
test_kw(a::Complex; c::Int=30, d...) = "1t_1tk_1kv"
test_kw(a::Symbol; c::Int=30, d::Float64=1., e::AbstractString="", f::Symbol=:a, g::Bool=false, h::Bool=true) = "1t_6k"
test_kw(a::Rational; c::Int=30, d::Float64=1., e::AbstractString="", f::Symbol=:a, g::Bool=false, h::Bool=true, i::Val{T}=Val(:foo), j::J) where {T, J<:AbstractString} = "1t_6k_2p"
test_kw(a::Signed, b::Signed, c...; d::Int=30, e...) = "1t_1v_1tk"
test_kw(a::Unsigned; d::Union{Vector{<:Real},Vector{<:AbstractString}}) = "1t_1uk"

test_opt_kw(a::Complex, b::Complex, c::Symbol = :c; d::Int=30, e::Float64=1., f::AbstractString="", g::Symbol=:a, h::Bool=false) = "2t_1o_5k"

test_ta_kw(; a::Vector{<:Real}=[1, 2, 3], b::Tuple{<:Real, <:T, V}=(1.0, -2, "Foo")) where { T <: Integer, V <: AbstractString} = "0vp_2ta_2kw"

test_unionall_method(a::Vector{Tuple{T1, T2}}; b::D = String[], c::Union{AbstractString, Symbol} = "", d::Union{AbstractString, Symbol} = :x) where { T1<:Real, T2<:Real, D<:Union{AbstractString, Symbol, AbstractVector} } = "unionall"



@testset "MethodInspector" begin

@testset "Initializations" begin
    @test test_nokw() == "0_0k"

    @test test_kw() == "0_0k"

    @test test_kw([]) == "1_0k"

    @test test_kw(10) == "1t_0k"

    @test test_kw(true) == "1t_1k"
    @test test_kw(true, b=5) == "1t_1k"

    @test test_kw('a') == "1t_1tk"
    @test test_kw('a', b=5) == "1t_1tk"

    @test test_kw(1.) == "1t_1d_1tk"
    @test test_kw(1., c=5) == "1t_1d_1tk"
    @test test_kw(1., 'b') == "1t_1d_1tk"
    @test test_kw(1., 'b', c=5) == "1t_1d_1tk"

    @test test_kw("A") == "1t_1v_1tk"
    @test test_kw("A", 3) == "1t_1v_1tk"
    @test test_kw("A", c=5) == "1t_1v_1tk"
    @test test_kw("A", 3, c=5) == "1t_1v_1tk"

    @test test_kw(10+5im) == "1t_1tk_1kv"
    @test test_kw(10+5im, c=5) == "1t_1tk_1kv"
    @test test_kw(10+5im, d=5) == "1t_1tk_1kv"
    @test test_kw(10+5im, x=5) == "1t_1tk_1kv"
    @test test_kw(10+5im, c=5, x=5) == "1t_1tk_1kv"
    @test test_kw(10+5im, c=5, x=5, y=6) == "1t_1tk_1kv"

    @test test_kw(:a) == "1t_6k"
    @test test_kw(:a, c=10) == "1t_6k"
end

@testset "kwarg_names" begin
    @test kwarg_names(methods(test_nokw)) == Symbol[]

    @test kwarg_names(methods(test_kw, (Symbol,)).ms[1]) == Symbol[:c, :d, :e, :f, :g, :h]
    @test kwarg_names(methods(test_kw)) == Symbol[:b]

    @test kwarg_names(methods(test_kw, (Symbol,))) == Symbol[:c, :d, :e, :f, :g, :h]
    @test kwarg_names(methods(test_kw, (Rational,))) == Symbol[:c, :d, :e, :f, :g, :h, :i, :j]

    @test kwarg_names(methods(test_kw, (Bool,))) == Symbol[:b]
    @test kwarg_names(methods(test_kw, (Char,))) == Symbol[:b]
    @test kwarg_names(methods(test_kw, (Int64,))) == Symbol[]
    @test kwarg_names(methods(test_kw, (Float64,))) == Symbol[]
    @test kwarg_names(methods(test_kw, (Float64, Char))) == Symbol[:c]
    @test kwarg_names(methods(test_kw, (Complex,))) == Symbol[:c, :d]
    @test kwarg_names(methods(test_kw, (Type{Symbol("")},))) == Symbol[]

    @test kwarg_names(methods(test_opt_kw)) == Symbol[:d, :e, :f, :g, :h]

    @test kwarg_names(methods(test_kw, (Signed,Signed,))) == Symbol[:d, :e]

    @test kwarg_names(methods(test_kw, (Unsigned,))) == Symbol[:d]

    @test kwarg_names(methods(test_ta_kw)) == [:a, :b]

    @test [:b, :c, :d] == kwarg_names(methods(test_unionall_method))
end

@testset "kwarg_types" begin
    @test Type[]    == kwarg_types(methods(test_kw, (Int,)))
    @test Type[Any] == kwarg_types(methods(test_kw, (Bool,)))
    @test Type[Int] == kwarg_types(methods(test_kw, (Char,)))
    @test Type[Int] == kwarg_types(methods(test_kw, (Float64, Char,)))
    @test Type[Int] == kwarg_types(methods(test_kw, (AbstractString,Vector,)))
    @test all(Type[Int, Any] .>: kwarg_types(methods(test_kw, (Complex,))))
    @test Type[Int, Float64, AbstractString, Symbol, Bool, Bool] == kwarg_types(methods(test_kw, (Symbol,)))
    @test all(Type[Int, Float64, AbstractString, Symbol, Bool, Bool, Val, AbstractString] .>: kwarg_types(methods(test_kw, (Rational,))))

    if VERSION < v"1.10"
        @test Type[Int, Any] == kwarg_types(methods(test_kw, (Signed,Signed,)))
    else
        @test all(Type[Int, Base.Pairs] .>: kwarg_types(methods(test_kw, (Signed,Signed,))))
    end

    @test Type[Union{Vector{Real},Vector{AbstractString}}] == kwarg_types(methods(test_kw, (Unsigned,)))

    @test Type[Vector{Real}, Tuple{Real, Integer, AbstractString}] == kwarg_types(methods(test_ta_kw))

    @test Type[Union{AbstractString, Symbol, AbstractVector{Any}}, Union{AbstractString, Symbol}, Union{AbstractString, Symbol}] == kwarg_types(methods(test_unionall_method))
end

@testset "arg_types" begin
    # Returns the first method
    @test Type[] == arg_types(methods(test_kw, tuple()))
    @test Type[Char] == arg_types(methods(test_kw, (Char,)).ms[1])
    @test isempty(setdiff(arg_types(methods(test_kw, (Number,))), [Int, Float64, Bool, Rational]))   # The first matching method will differ across Julia versions
    @test isempty(setdiff(arg_types(methods(test_kw, (Real,))), [Int, Float64, Bool, Rational]))   # The first matching method will differ across Julia versions
    @test Type[AbstractString, Any] == arg_types(methods(test_kw, (AbstractString,)))
    @test Rational >: arg_types(methods(test_kw, (Rational,)))[1]
    @test Type[Signed, Signed, Any] == arg_types(methods(test_kw, (Signed,Signed,)))

    @test Type[] == arg_types(methods(test_nokw, tuple()))
    @test Type[Vector{Real},] == arg_types(methods(test_nokw, (Vector{Real},)))
    @test Type[Int, Vector{Any},] == arg_types(methodswith(Int, test_nokw))
    @test Type[Char, Vector{Real},] == arg_types(methodswith(Char, test_nokw))
    @test Type[Float64, Tuple{<:AbstractString,<:Real},] == arg_types(methodswith(Float64, test_nokw))
    @test Type[Bool, Tuple{<:Real,<:Any},] == arg_types(methodswith(Bool, test_nokw))
    @test Type[Unsigned, Tuple{<:Real,Any,<:AbstractFloat},] == arg_types(methodswith(Unsigned, test_nokw))

    @test Type[Signed, Any] == arg_types(methods(test_nokw, (Signed,)))

    @test Type[Union{Vector{Complex{Real}},Vector{AbstractString}}] == arg_types(methods(test_nokw, (Vector{Complex},)))

    @test Type[] == arg_types(methods(test_ta_kw))

    @test Type[Vector{Tuple{Real, Real}}] == arg_types(methods(test_unionall_method))
end

@testset "arg_names" begin
    @test Symbol[] == arg_names(methods(test_kw, tuple()))
    @test Symbol[:a] == arg_names(methods(test_kw, (Char,)).ms[1])
    @test [:a] == arg_names(methods(test_kw, (Number,)))
    @test [:a] == arg_names(methods(test_kw, (Real,)))
    @test [:a, :b] == arg_names(methods(test_kw, (AbstractString,)))
    @test [:a] == arg_names(methods(test_kw, (Rational,)))
    @test [:a, :b, :c] == arg_names(methods(test_kw, (Signed,Signed,)))

    @test Symbol[] == arg_names(methods(test_nokw, tuple()))
    @test [:a] == arg_names(methods(test_nokw, (Vector,)))
    @test [:a, :b,] == arg_names(methodswith(Int, test_nokw))
    @test [:a, :b,] == arg_names(methodswith(Char, test_nokw))
    @test [:a, :b,] == arg_names(methodswith(Float64, test_nokw))
    @test [:a, :b,] == arg_names(methodswith(Bool, test_nokw))
    @test [:a, :b,] == arg_names(methodswith(Unsigned, test_nokw))

    @test [:a] == arg_names(methods(test_nokw, (Vector{Complex},)))

    @test Symbol[] == arg_names(methods(test_ta_kw))

    @test [:a] == arg_names(methods(test_unionall_method))
end

end
