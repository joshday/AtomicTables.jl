#-----------------------------------------------------------------------------# show
function Base.show(io::IO, t::CTable)
    n = length(t)
    printstyled(io, "CTable ", bold=true)
    printstyled(io, "($n × $(ncols(t)))"; color=:light_black)

    isempty(t) && return

    nr, nc = displaysize(io)
    println(io)
    
    rows_omitted = length(t) - nr + 6

    cols2show = []

    width = 0
    for (k,v) in pairs(t)
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
