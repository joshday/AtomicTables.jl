module AtomicTables

using NamedTupleTools

import NamedTupleTools: select

export 
    CTable, 
    # Selectors
    Col, Not, Before, After, Between, And,
    # Functions
    cols, schema, head, tail, nrows, ncols, rename

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

#-----------------------------------------------------------------------# ctable
include("ctable/ctable.jl")
include("ctable/select.jl")
include("ctable/join.jl")

end # module
