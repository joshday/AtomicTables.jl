module AtomicTables

using NamedTupleTools

import NamedTupleTools: select

export 
    CTable, 
    # Selectors
    Col, Not, Before, After, Between, And,
    # Functions
    cols, schema, head, tail, nrows, ncols

#-----------------------------------------------------------------------# utils
const ColumnTable = NamedTuple{names,T} where T<:Tuple{Vararg{AbstractArray{S,D} where S,N}} where names where D where N
const TupleOfVectors = Tuple{Vararg{<:AbstractVector}}

# Generate a name different from the provided names
function uniquename(kys::NTuple{N, Symbol}) where {N}
    name = :x1
    i = 1
    while name in kys
        i += 1
        name = Symbol("x$i")
    end
    name
end

#-----------------------------------------------------------------------------# CTable 
struct CTable{T<:ColumnTable} 
    cols::T
    function CTable(t::ColumnTable; allow_ranges=false)
        check(t)
        if allow_ranges
            t2 = t 
        else
            t2 = map(t) do x 
                x isa AbstractRange ? collect(x) : x
            end
        end
        new{typeof(t2)}(t2)
    end
end
CTable(t::TupleOfVectors) = CTable(namedtuple(tuple((Symbol("x$i") for i in 1:length(t))...), t))
CTable(; kw...) = CTable(namedtuple(kw))
CTable(args...) = CTable(args)

cols(t::CTable) = getfield(t, :cols)

schema(t::CTable) = CTable((
    field = collect(keys(t)), 
    type = collect(map(typeof, cols(t))),
    eltype = collect(map(eltype, cols(t)))
))

check(t::ColumnTable) = all(x -> length(x) == length(first(t)), t) || error("Columns have different lengths: $(map(length, t))")
nrows(t::CTable) = length(cols(t)[1])
ncols(t::CTable) = length(cols(t))
head(t::CTable, n=10) = t[1:min(length(t), n)]
tail(t::CTable, n=10) = t[max(1, end-n):end]

#-----------------------------------------------------------------------------# Base
Base.summary(t::CTable) = "CTable ($(nrows(t)) × $(ncols(t)))"
Base.length(t::CTable) = isempty(t) ? 0 : length(cols(t)[1])
Base.pairs(t::CTable) = pairs(cols(t))
Base.keys(t::CTable) = keys(cols(t))
Base.size(t::CTable) = (nrows(t), ncols(t))
Base.size(t::CTable, i::Integer) = size(t)[i]
Base.copy(t::CTable) = CTable(map(copy, cols(t)))

Base.deleteat!(t::CTable, i) = (map(x -> deleteat!(x, i), cols(t)); t)
Base.isempty(t::CTable) = all(isempty, cols(t))
Base.hcat(a::CTable, b::CTable) = CTable(merge(cols(a), cols(b)))

function Base.vcat(a::CTable, b::CTable; cols=false)
    all(in.(keys(a), Ref(keys(b)))) || error("Cann")
    CTable(map((k,v) -> vcat(v, cols(b)[k]), pairs(cols(a))))
end

Base.push!(t::CTable, row) = (foreach(x -> push!(x...), zip(cols(t), row)); t)

function Base.append!(t::CTable{T}, t2::CTable{T}) where {T} 
    map(x -> append!(x...), zip(cols(t), cols(t2)))
    t
end

Base.getindex(t::CTable, i::Integer) = map(x -> x[i], cols(t))
Base.getindex(t::CTable, i::AbstractVector{<:Integer}) = CTable(map(x -> x[i], cols(t)))
Base.getindex(t::CTable, x::Symbol) = cols(t)[x]
Base.getindex(t::CTable, x::AbstractVector{Symbol}) = CTable(select(cols(t), x))
function Base.setindex!(t::CTable, val, i::Integer)
    for (k,v) in pairs(t)
        v[i] = val[k]
    end
    val
end
Base.lastindex(t::CTable) = nrows(t)

Base.getproperty(t::CTable, x::Symbol) = cols(t)[x]
function Base.setproperty!(t::CTable, val, x::Symbol)
    for (k, v) in pairs(t)
        v[i] = getproperty(val, k)
    end
    val
end

Base.iterate(t::CTable, i=1) = i > length(t) ? nothing : (t[i], i + 1)
Base.eltype(t::CTable) = NamedTuple{keys(t), Tuple{map(eltype, cols(t))...}}

Base.merge(a::CTable, b::CTable) = CTable(merge(cols(a), cols(b)))

function fakedata(n = 1000)
    data = (
        x1 = rand(1:10, n),
        x2 = rand(n),
        x3 = rand(Bool, n),
        y1 = rand(1f0:10f0, n),
        y2 = rand(["A","B","C"], n),
        y3 = rand(1:10, n),
        z1 = [rand(Bool) ? missing : rand() for i in 1:n]
    )
    CTable(data)
end

#-----------------------------------------------------------------------# includes
include("show.jl")
include("select.jl")
include("filter.jl")
include("join.jl")

end # module
