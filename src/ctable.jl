"""
    CTable(x, meta = Dict())

Construct a columnar table from an object `x` that satisfies the Tables.jl interface,
optionally with metadata `meta`.

# Example

    CTable([(x=1,y=2), (x=3,y=4)])

    using CSV
    path = joinpath(dirname(pathof(AtomicTables)), "..", "data", "diamonds.csv")
    CTable(CSV.File(path))
"""
struct CTable{T, C<:ColumnTable} <: AbstractVector{T}
    columns::C
    meta::Dict
    function CTable(x, meta = Dict())
        c = columns(x)
        T = NamedTuple{keys(c), Tuple{map(eltype, c)...}}
        new{T, typeof(c)}(c, meta)
    end
end

Base.getindex(t::CTable, i::Integer) = map(x -> x[i], columns(t))
Base.getindex(t::CTable, i::AbstractVector{<:Integer}) = CTable(map(x -> x[i], columns(t)))
function Base.setindex!(t::CTable, val, i::Integer)
    for (c, v) in zip(columns(t), val)
        c[i] = v
    end
    val
end
Base.deleteat!(t::CTable, i) = (map(x -> deleteat!(x, i), columns(t)); t)
Base.size(t::CTable) = size(first(columns(t)))
Base.isempty(t::CTable) = all(isempty, columns(t))
Base.length(t::CTable) = isempty(t) ? 0 : length(first(columns(t)))
Base.getproperty(t::CTable, ky::Symbol) = columns(t)[ky]
Base.hcat(a::CTable, b::CTable) = CTable(merge(columns(a), columns(b)))

function Base.push!(t::CTable, collection)
    for (col, item) in zip(columns(t), collection)
        push!(col, item)
    end
    t
end
function Base.append!(t::CTable{T}, t2::CTable{T}) where {T}
    for (c1, c2) in zip(columns(t), columns(t2))
        append!(c1, c2)
    end
    t
end

nrows(t::CTable) = length(t)
ncols(t::CTable) = length(columns(t))

head(t::CTable, n=10) = t[1:min(length(t), n)]
tail(t::CTable, n=10) = t[max(1, end-n):end]

colnames(t::CTable) = keys(columns(t))

"Create a new CTable with each column `collect`-ed."
collectall(t::CTable) = CTable(map(collect, columns(t)))

# How does fallback method compare to this?
# Base.filter(f::Base.Callable, t::CTable; sel=All()) = t[findall(f, select(t, sel))]

function dropmissing(t::CTable; sel=All())
    t2 = select(t, sel)
    nms = findall(T -> Missing <: T, map(eltype, columns(t2)))
    isempty(nms) && return t
    t3 = select(t2, Tuple(nms))
    idxs = findall(x -> any(ismissing,x), t3)
    t4 = t[setdiff(1:length(t), idxs)]
    CTable(map(x -> convert(Vector{Base.nonmissingtype(eltype(x))}, x), columns(t4)))
end

#-----------------------------------------------------------------------# Tables
Tables.istable(::Type{<:CTable}) = true
Tables.columnaccess(::Type{<:CTable}) = true
Tables.columns(c::CTable) = getfield(c, :columns)
Tables.rowaccess(::Type{<:CTable}) = true
Tables.rows(c::CTable) = c
Tables.schema(c::CTable) = Tables.schema(columns(c))
Tables.materializer(c::CTable) = CTable

#-----------------------------------------------------------------------# show
function Base.show(io::IO, ::MIME"text/plain", t::CTable)
    println(io, "CTable ($(nrows(t)) rows × $(ncols(t)) columns)")
    print_table(io, t)
end


#-----------------------------------------------------------------------# generate data
function fakedata(n = 100)
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

#-----------------------------------------------------------------------# groupreduce
function groupreduce(f::Base.Callable, t::CTable, by; sel=Not(by), init=nothing)
    a = select(t, by)
    b = select(t, sel)
    # b = sel isa Symbol ? columns(t)[sel] : select(t, sel)
    T = Union{typeof(f(b[1], b[2])), typeof(b[1])}
    out = OrderedDict{eltype(a), T}()
    for (grouprow, row) in zip(a, b)
        if haskey(out, grouprow)
            out[grouprow] = f(out[grouprow], row)
        else
            out[grouprow] = isnothing(init) ? row : f(init, row)
        end
    end
    groups = CTable(collect(keys(out)))
    vals = collect(values(out))
    groups, vals
end

reducername(f) = Symbol("$f($sel)")