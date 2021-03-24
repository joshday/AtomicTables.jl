# Fallback: Collection of selections
select(t::CTable, sel) = mapreduce(x -> select(t, x), merge, sel)

#-----------------------------------------------------------------------------# field name/index
field_name(t::CTable, sel) = error("Selection $sel returns multiple field names.")
field_name(t::CTable, sel::Symbol) = sel
field_name(t::CTable, sel::String) = Symbol(sel)
field_name(t::CTable, sel::Integer) = keys(t)[sel]

field_index(t::CTable, sel) = error("Selection $sel returns multiple field indexes.")
field_index(t::CTable, sel::Symbol) = findfirst(==(sel), keys(t))
field_index(t::CTable, sel::String) = field_index(t, Symbol(sel))
field_index(t::CTable, sel::Integer) = sel

# selections that return a single column
select(t::CTable, sel::Union{Symbol, String, Integer}) = CTable(select(cols(t), [field_name(t, sel)]))

select(t::CTable, sel::Type) = select(t, keys(t)[collect(map(x -> eltype(x) <: sel, cols(t)))])

select(t::CTable, sel::Regex) = select(t, filter(x -> occursin(sel, string(x)), keys(t)))




#-----------------------------------------------------------------------------# Not 
struct Not{T}
    sel::T 
end
Not(args...) = Not(args)
select(t::CTable, not::Not) = CTable(delete(cols(t), keys(select(t, not.sel))))

#-----------------------------------------------------------------------------# Before
struct Before{T}
    sel::T
end
field_index(t::CTable, b::Before) = field_index(t, b.sel) - 1
function select(t::CTable, b::Before)
    i = field_index(t, b)
    i < 1 ? error("Attempted to select 0-th field.") : select(t, i)
end

#-----------------------------------------------------------------------------# After
struct After{T}
    sel::T
end
field_index(t::CTable, a::After) = field_index(t, a.sel) + 1
function select(t::CTable, a::After) 
    i = field_index(t, a)
    i > length(ncols(t)) ? 
        error("Attempted to select $i-th field when only $(ncols(t)) fields exist.") : 
        select(t, i)
end

#-----------------------------------------------------------------------------# Between 
struct Between{T, S}
    first::T 
    last::S
end
select(t::CTable, b::Between) = select(t, field_index(t, b.first):field_index(t, b.last))