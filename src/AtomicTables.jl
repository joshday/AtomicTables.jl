module AtomicTables

const ColumnTable = NamedTuple{names,T} where T<:Tuple{Vararg{AbstractArray{S,D} where S,N}} where names where D where N

export CTable

#-----------------------------------------------------------------------# utils
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
        all(x -> length(x) == length(first(t)), t) || error("Columns have different lengths: $(map(length, t))")
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

nrows(t::CTable) = length(cols(t)[1])
ncols(t::CTable) = length(cols(t))
cols(t::CTable) = getfield(t, :cols)

#-----------------------------------------------------------------------------# Base
Base.summary(t::CTable) = "CTable ($(nrows(t)) × $(ncols(t)))"
Base.length(t::CTable) = length(cols(t)[1])
Base.pairs(t::CTable) = pairs(cols(t))
Base.keys(t::CTable) = keys(cols(t))

Base.getindex(t::CTable, i::Integer) = map(x -> x[i], cols(t))
Base.getindex(t::CTable, i::AbstractVector{<:Integer}) = CTable(map(x -> x[i], cols(t)))
Base.getindex(t::CTable, x::Symbol) = cols(t)[x]
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

#-----------------------------------------------------------------------------# iterate 
Base.iterate(t::CTable, i=1) = i > length(t) ? nothing : (t[i], i + 1)

#-----------------------------------------------------------------------# includes
# include("tables_extensions.jl")
# include("ctable.jl")
include("show.jl")

end # module
