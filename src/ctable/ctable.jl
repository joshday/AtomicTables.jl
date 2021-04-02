
#-----------------------------------------------------------------------------# CTable 
"""
A Columnar data table.  It is a simple wrapper around a NamedTuple of AbstractVectors (See 
`Tables.ColumnTable`).  By default, ranges (e.g. `1:10`) will be `collect`-ed.

## Examples 

    x = 1:10
    y = rand(10)

    # With field names:
    CTable((field1 = x, field2 = y))
    CTable(field1= x , field2 = y)
    
    # Auto-named:
    CTable((x, y))
    CTable(x, y)
    CTable([x y])
"""
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
function CTable(t::Tuple{Vararg{<:AbstractVector}}; kw...) 
    CTable(namedtuple(tuple((Symbol("x$i") for i in 1:length(t))...), t); kw...)
end
CTable(; kw...) = CTable(namedtuple(kw))
CTable(args...) = CTable(args)
CTable(x::AbstractMatrix) = CTable(eachcol(x)...)

cols(t::CTable) = getfield(t, :cols)

schema(t::CTable) = CTable((
    field = collect(names(t)), 
    type = collect(map(typeof, cols(t))),
    eltype = collect(map(eltype, cols(t)))
))

check(t::ColumnTable) = all(x -> length(x) == length(first(t)), t) || error("Columns have different lengths: $(map(length, t))")
nrows(t::CTable) = length(cols(t)[1])
ncols(t::CTable) = length(cols(t))
head(t::CTable, n=10) = t[1:min(length(t), n)]
tail(t::CTable, n=10) = t[max(1, end-n):end]

function rename(t::CTable, old_new::Pair...)
    for old_new in old_new
        old_key = field_name(t, old_new[1])
        new_key = field_name(t, old_new[2])
        names = collect(names(t))
        i = findfirst(==(old_key), names)
        names[i] = new_key
        t = CTable(namedtuple(names, cols(t)))
    end
    return t
end

#-----------------------------------------------------------------------------# Base
Base.summary(t::CTable) = "CTable ($(nrows(t)) × $(ncols(t)))"
Base.length(t::CTable) = isempty(t) ? 0 : length(cols(t)[1])

Base.names(t::CTable) = keys(cols(t))
Base.size(t::CTable) = (nrows(t), ncols(t))
Base.size(t::CTable, i::Integer) = size(t)[i]
Base.copy(t::CTable) = CTable(map(copy, cols(t)))
Base.keys(t::CTable) = Base.LinearIndices(Base.OneTo(length(t)))

Base.deleteat!(t::CTable, i) = (map(x -> deleteat!(x, i), cols(t)); t)
Base.isempty(t::CTable) = all(isempty, cols(t))
Base.hcat(a::CTable, b::CTable) = CTable(merge(cols(a), cols(b)))

function Base.vcat(a::CTable, b::CTable; cols=false)
    all(in.(names(a), Ref(names(b)))) || error("Cannot vcat")
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
    for (k,v) in pairs(cols(t))
        v[i] = val[k]
    end
    val
end
Base.lastindex(t::CTable) = nrows(t)

Base.getproperty(t::CTable, x::Symbol) = cols(t)[x]
function Base.setproperty!(t::CTable, val, x::Symbol)
    for (k, v) in pairs(cols(t))
        v[i] = getproperty(val, k)
    end
    val
end

Base.iterate(t::CTable, i=1) = i > length(t) ? nothing : (t[i], i + 1)
Base.eltype(t::CTable) = NamedTuple{names(t), Tuple{map(eltype, cols(t))...}}

Base.merge(a::CTable, b::CTable) = CTable(merge(cols(a), cols(b)))

function Base.sort!(a::CTable, sel=All())
end

function fake(::Type{CTable}, n = 10_000)
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

#-----------------------------------------------------------------------------# filter
Base.filter(f, t::CTable, sel=All()) = filter!(f, copy(t), sel)

function Base.filter!(f, t::CTable, sel=All())
    idx = map(!f, select(t, sel))
    map(x -> deleteat!(x, idx), cols(t))
    t
end

#-----------------------------------------------------------------------------# drop missing
Base.filter!(::Not{Missing}, t::CTable, sel=All()) = error("No filter! method.  Did you mean filter?")

function Base.filter(f::Not{Missing}, t::CTable, sel=All())
    temp = select(t, sel)
    idx = map(x -> !any(ismissing, x), temp)
    temp2 = temp[idx]
    new_cols = map(cols(temp2)) do col 
        T = eltype(col)
        if Missing <: T
            new_col = similar(col, nonmissingtype(T))
            new_col[:] = col 
            new_col
        else
            col
        end
    end
    CTable(merge(cols(t[idx]), new_cols))
end


#-----------------------------------------------------------------------------# show
function Base.show(io::IO, t::CTable)
    n = length(t)
    printstyled(io, "CTable ", bold=true)
    printstyled(io, "($n × $(ncols(t)))"; color=:light_black)

    isempty(t) && return

    nr, nc = displaysize(io)
    println(io)
    
    rows_omitted = length(t) - nr + 6

    cols2show = Vector{String}[]

    width = 0
    for (k,v) in pairs(cols(t))
        vals = string.(vcat(k, v[1:min(n, nr - 6 - (rows_omitted > 0))]))
        width += maximum(length, vals) + 2
        width <= nc - 2 ? push!(cols2show, vals) : break
    end

    for c in cols2show 
        w = maximum(length, c) + 1
        h = c[1]
        printstyled(io, "|"; color = :light_black)
        printstyled(io, " $h"; color = :light_green)
        printstyled(io, ' ' ^ (w - length(h)); color = :light_green)
    end
    printstyled(io, " |"; color = :light_black)

    println(io)

    for c in cols2show 
        w = maximum(length, c) + 1
        h = c[1]
        printstyled(io, "|" * '-' ^ (w + 1); color = :light_black)
    end
    printstyled(io, "-|"; color = :light_black)

    println(io)

    for i in 2:length(cols2show[1])
        for c in cols2show 
            w = maximum(length, c)
            printstyled(io, "|"; color = :light_black)
            print(io, " $(c[i]) ")
            print(io, ' ' ^ (w -= length(c[i])))
        end
        printstyled(io, " |"; color = :light_black)
        println(io)
    end

    rows_omitted > 0 && printstyled(io, "  (Rows Omitted: ", rows_omitted, ")", color=:cyan)

    cols_omitted = length(cols(t)) - length(cols2show)

    cols_omitted > 0 && printstyled(io, "  (Cols Omitted: ", cols_omitted, ")", color=:cyan)
end
