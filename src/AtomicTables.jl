module AtomicTables

using NamedTupleTools
using OrderedCollections: OrderedDict

import NamedTupleTools: select

export 
    CTable, 
    # Selectors
    Col, Not, Before, After, FromTo, And,
    # Functions
    cols, schema, head, tail, nrows, ncols, rename, inner_join, left_join, select

#-----------------------------------------------------------------------# utils
const ColumnTable = NamedTuple{names,T} where T<:Tuple{Vararg{AbstractArray{S,D} where S,N}} where names where D where N

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

#-----------------------------------------------------------------------------# Selectors
struct Col{T} 
    sel::T 
end

struct All end 
select(t, ::All) = t

struct Not{T}
    sel::T 
end
Not(args...) = Not(args)

struct Before{T}
    sel::T
end

struct After{T}
    sel::T
end

struct FromTo{T, S}
    first::T 
    last::S
end

struct And{T}
    sel::T
end 

#-----------------------------------------------------------------------# ctable
include("ctable/ctable.jl")
include("ctable/select.jl")
include("ctable/join.jl")

end # module
