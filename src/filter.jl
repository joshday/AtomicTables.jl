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
