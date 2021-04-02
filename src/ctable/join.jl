#-----------------------------------------------------------------------------# find_matches
function find_matches(left_row, right)
    findall(x -> cmp(x, left_row), right)
end

cmp(x, y) = x == y


function check_join_fields(left, right, on)
    on = on isa Col ? field_name(left, on.sel) : on
    on_keys = names(select(left, on))
    lkeys = setdiff(names(left), on_keys)
    rkeys = setdiff(names(right), on_keys)
    for k in lkeys 
        k in rkeys && error("left and right both contain non-key field: $k")
    end
end


#-----------------------------------------------------------------------------# hash_join
function hash_join(left::CTable, right::CTable, on)
    left_on = select(left, on)
    right_on = select(right, on)

    out = merge(
        OrderedDict(k => similar(v, 0) for (k,v) in pairs(cols(left))),
        OrderedDict(k => similar(v, 0) for (k,v) in pairs(cols(right))),
    )
    left_hash_table = OrderedDict(i => hash(row) for (i,row) in enumerate(left_on))
    right_hash_table = OrderedDict(hash(row) => i for (i,row) in enumerate(right_on))

    for (i,h) in pairs(left_hash_table)
        j = get(right_hash_table, h, nothing)
        if !isnothing(j)
            for (k,v) in pairs(cols(left))
                push!(out[k], v[i])
            end
            for (k,v) in pairs(cols(right))
                if on isa Col
                    k != on.sel && push!(out[k], v[j])
                elseif !(k in names(left_on))
                    push!(out[k], v[j])
                end
            end
        end
    end
    return CTable(namedtuple(out))
end

#-----------------------------------------------------------------------------# inner_join
function inner_join(left::CTable, right::CTable, on)
    check_join_fields(left, right, on)
    left_out = CTable(map(x -> similar(x, 0), cols(left)))
    right_out = CTable(map(x -> similar(x, 0), cols(right)))
   
    left_sub = select(left, on)
    right_sub = select(right, on)
    for (i,left_sub_row) in enumerate(left_sub)
        idx = find_matches(left_sub_row, right_sub)
        for j in idx
            push!(left_out, left[i])
            push!(right_out, right[j])
        end
    end
    return CTable(merge(cols(left_out), cols(right_out)))
end

#-----------------------------------------------------------------------------# left_join
function left_join(left::CTable, right::CTable, on)
    check_join_fields(left, right, on)
    out = CTable(merge(
        map(x -> similar(x, 0), cols(left)), 
        map(x -> similar(x, Union{Missing,eltype(x)}, 0), cols(right))
    ))
    keys2add = setdiff(names(right), names(left))
    left_sub = select(left, on)
    right_sub = select(right, on)
    for left_row in left
        idx = find_matches(left_row, right_sub)
        if isempty(idx)
            push!(out, merge(left_row, namedtuple(keys2add, fill(missing, length(keys2add)))))
        else
            for j in idx
                push!(out, merge(left_row, right[j]))
            end
        end
    end
    return out
end