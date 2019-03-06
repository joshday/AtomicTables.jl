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
Base.size(t::CTable) = size(first(columns(t)))
Base.isempty(t::CTable) = all(isempty, columns(t))
Base.length(t::CTable) = isempty(t) ? 0 : length(first(columns(t)))
Base.getproperty(t::CTable, ky::Symbol) = columns(t)[ky]

nrows(t::CTable) = length(t)
ncols(t::CTable) = length(columns(t))

head(t::CTable, n=10) = t[1:min(length(t), n)]
tail(t::CTable, n=10) = t[max(1, end-n):end]

colnames(t::CTable) = keys(columns(t))

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
    xs = (x1 = 1:n, x2 = rand(n), x3 = rand(Bool, n))
    ys = (y1 = rand(1f0:10f0, n), y2 = rand(["A","B","C"], n), y3 = rand(1:10, n))
    zs = (z1 = [rand(Bool) ? missing : rand() for i in 1:n],)
    CTable(reduce(merge, [xs, ys, zs]))
end