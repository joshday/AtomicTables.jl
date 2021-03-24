function join(left::CTable, right::CTable; on=first(keys(left)) => first(keys(right)))
end