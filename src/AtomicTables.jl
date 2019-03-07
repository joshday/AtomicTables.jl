module AtomicTables

using Markdown

using OrderedCollections: OrderedDict
using Tables: columns, ColumnTable

import Tables


export rows, columns, select, nrows, ncols, head, tail, collectall, colnames,
    CTable, All, Not, Between

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

#-----------------------------------------------------------------------# includes
include("tables_extensions.jl")
include("ctable.jl")

end # module
