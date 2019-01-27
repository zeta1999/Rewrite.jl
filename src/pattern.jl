export Variable, Pattern
export Substitution
export match


mutable struct Variable end


struct Substitution <: AbstractDict{Variable,Term}
    dict::Dict{Variable,Term}
end
Substitution() = Substitution(Dict{Variable,Term}())
(σ::Substitution)(t) = replace(t, σ)
Base.length(σ::Substitution) = length(σ.dict)
Base.iterate(σ::Substitution) = iterate(σ.dict)
Base.iterate(σ::Substitution, state) = iterate(σ.dict, state)
Base.keys(σ::Substitution) = keys(σ.dict)
Base.getindex(σ::Substitution, keys...) = getindex(σ.dict, keys...)
Base.setindex!(σ::Substitution, val, keys...) = (setindex!(σ.dict, val, keys...); σ)
Base.get(σ::Substitution, key, default) = get(σ.dict, key, default)


Base.replace(t::Term, σ::AbstractDict) = convert(Term, _replace(t, σ))
_replace(t, σ) = isa(root(t), Variable) ? get(σ, root(t), t) : map(x -> replace(x, σ), t)


"""
    match(pattern::Term, subject::Term) -> σ::Union{Substitution, Nothing}

Syntactically match term `subject` to `pattern`, producing a `Substitution` such that
`σ(pattern) == subject` if the process succeeds and `nothing` otherwise.

# Examples
```jldoctest
julia> x = Variable()
Variable()

julia> pattern = @term(x + abs(x)));

julia> subject1 = @term(-6 + abs(-6));

julia> σ = match(pattern, subject1);

julia> σ[x]
@term(-6)

julia> σ(subject1) == subject1
true

julia> subject2 = @term(-6 + abs(-5));

julia> match(pattern, subject2)
```
"""
Base.match(pattern::Term, subject::Term) = _match!(Substitution(), pattern, subject)

function _match!(σ::Substitution, p::Term, s::Term)
    if isa(p.head, Variable)
        x = p.head
        haskey(σ, x) && return isequal(σ[x], s) ? σ : nothing
        return setindex!(σ, s, x)  # σ[x] = s
    end

    p.head === s.head                || return
    length(p.args) == length(s.args) || return

    for (x, y) ∈ zip(p.args, s.args)
        σ′ = _match!(σ, x, y)
        σ′ === nothing && return
        σ = σ′
    end

    return σ
end
