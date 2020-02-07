function Base.show(io::IO, t::AtomicTable{T}) where {T}
    Base.print(io, "$(size(t, 1)) × $(size(t, 2)) AtomicTable{$T}")
    fields = collect(keys(t.data))
    for (i, f) in enumerate(fields)
        println(io)
        print(io, "  x$i | $f")
    end
end