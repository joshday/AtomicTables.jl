#-----------------------------------------------------------------------# print_table
function print_table(io, t)
    maxh, maxw = displaysize(io)
    n = min(maxh - 8, length(t))
    s = ""
    i = ncols(t)
    for nc in 1:ncols(t)
        s = Markdown.plain(markdowntable(t, tuple(1:nc...), nrows=n))
        findfirst("\n", s)[1] > maxw && (i=nc-1; break)
    end
    if i == ncols(t)
        print(io, s)
    else
        printstyled(io, "$(ncols(t) - i) columns missing from printout\n", color=:yellow)
        print(io, Markdown.plain(markdowntable(t, tuple(1:i...), nrows=n)))
    end
    n < length(t) && print(io, "  ⋮")
end

function markdowntable(t, sel = All(); nrows::Int=20, types=true)
    t2 = head(select(t, sel), nrows)
    nc = ncols(t2)
    nms = string.(collect(colnames(t2)))
    if types
        nms = [nms[i] * "::$(eltype(x))" for (i,x) in enumerate(columns(t2))]
    end
    out = [nms, [collect(t2[i]) for i in 1:length(t2)]...]
    Markdown.Table(out, fill(:l, length(out[1])))
end

#-----------------------------------------------------------------------------# printnames
function printnames(io::IO, t)
    
end

printnames(t) = printnames(stdout, t)

#-----------------------------------------------------------------------# select
# Every selection needs a getkeys method that returns a tuple of Symbols

"""
    select(t, sel)
    select(t, sel, sink)

Select a column or columns from table `t` via `sel`, optionally put into `sink`.

`sel` can take many possible values:

- `Integer` -- Return the `sel`-th column.
- `Symbol` -- Return the column with name `sel`.
- `Between(first,last)` -- Return columns placed between `first` and `last`
- `Type` -- Return columns with `eltype(<col>) <: sel`
- `String` or `Regex` -- Return columns where `occursin(sel, <colname>)`.
- `Not(items...)` -- Return columns that are not selected by `items`.
- `Tuple` (of any of the above types) -- Return the union of selections.

# Examples

    using AtomicTables

    t = AtomicTables.fakedata(100)

    select(t, 1)
    select(t, :x2)
"""
select(t::ColumnTable, sel::NTuple{N,Symbol}) where {N} = NamedTuple{sel}(t)
select(t, sel, sink=Tables.materializer(t)) = sink(select(Tables.columntable(t), sel))
select(t::ColumnTable, sel) = select(t, getkeys(t, sel))

# Transform selector to keys of the table
getkeys(t::ColumnTable, sel::Tuple) = Tuple(union(map(x -> getkeys(t, x), sel)...))
getkeys(t::ColumnTable, sel::Integer) = tuple(keys(t)[sel])
getkeys(t::ColumnTable, sel::Symbol) = tuple(sel)
getkeys(t::ColumnTable, sel::Type) = Tuple(findall(x -> eltype(x) <: sel, t))
getkeys(t::ColumnTable, sel::Nothing) = tuple()
function getkeys(t::ColumnTable, sel::Union{String, Regex})
    inds = findall(x -> occursin(sel, string(x)), keys(t))
    Tuple(collect(keys(t))[inds])
end

#-----------------------------------------------------------------------# Selectors
struct All end
getkeys(t, sel::All) = keys(t)

struct Not{T}
    items::T
end
Not(sel::Union{Symbol, Type, String, Regex}) = Not(tuple(sel))
Not(sel...) = Not(sel)
function getkeys(t, sel::Not)
    kys = getkeys(t, Tuple(sel.items))
    Tuple(setdiff(keys(t), kys))
end

struct Between
    first::Symbol
    last::Symbol
end
function getkeys(t, sel::Between)
    kys = collect(keys(t))
    while first(kys) != sel.first
        popfirst!(kys)
    end
    while last(kys) != sel.last
        pop!(kys)
    end
    tuple(kys...)
end
