# #=
# Idea:

# Take a formula Expr, e.g.
#     :(y ~ 1 + poly(x,2) + abs(z) + x*z)

# And create the selections associated with each term
#     sel = (:y, ones(length(t)), (:x, :x2 => x -> x^2), :z => abs, (x,z) => x -> *(x...))

# =#



# #-----------------------------------------------------------------------# select
# function select(t::AbstractTable, sel::Expr)
#     sel.args[1] != :~ && error("Expression is not a formula, e.g. :(y ~ x + z)")
#     cols = parse_formula(sel)
#     select(t, cols)
# end

# #-----------------------------------------------------------------------# parse_formula
# function parse_formula(e)
#     if isa(e, Symbol)
#         return nt(e)
#     else
#         parse_formula(e, Val(first(e.args)))
#     end
# end

# # First parse e.g. :(y ~ x + z)
# function parse_formula(e::Expr, ::Val{:~})
#     cols = (y = e.args[2],)
#     for a in e.args[3:end]
#         cols = merge(cols, parse_formula(a))
#     end
#     cols
# end

# function parse_formula(e::Expr, ::Val{:poly})
#     sel = e.args[2]
#     cols = nt(sel)
#     for i in 2:e.args[3]
#         nm = Symbol("$sel ^ $i")
#         cols = merge(cols, NamedTuple{tuple(nm), Tuple{Symbol}}((sel => x -> x^2)))
#     end
# end