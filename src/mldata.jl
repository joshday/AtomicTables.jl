#-----------------------------------------------------------------------# Matrix
function Base.Matrix(t::AbstractTable)
    T = mapreduce(eltype, promote_type, columns(t))
    x = Matrix{T}(undef, nrows(t), ncols(t))
    for (i, col) in enumerate(columns(t))
        @inbounds x[:, i] .= col
    end
    x
end
function Base.Matrix{T}(t::AbstractTable) where {T}
    x = Matrix{T}(undef, nrows(t), ncols(t))
    for (i, col) in enumerate(columns(t))
        @inbounds x[:, i] .= col
    end
    x
end

#-----------------------------------------------------------------------# MLData
struct MLData{
        X <: Union{AbstractArray,  Nothing},
        Y <: Union{AbstractArray,  Nothing},
        W <: Union{AbstractVector, Nothing}
    }
    x::X
    y::Y
    w::W
    function MLData(x::X, y::Y, w::W) where {X,Y,W}
        nx, ny, nw = _nobs(x), _nobs(y), _nobs(w)
        n = max(nx, ny, nw)
        nx == ny == 0 && error("At least one of x or y must be provided.")
        all(x -> x==n || x==0, (nx, ny, nw)) || error("Components have different nobs.")
        new{X,Y,W}(x, y, w)
    end
end

_nobs(x::AbstractArray) = size(x, 1)
_nobs(x::Nothing) = 0

mldata(;x=nothing, y=nothing, w=nothing) = MLData(x, y, w)

function mldata(t::AbstractTable; x=nothing, y=nothing, w=nothing)
    X = ml_format(select(t, x))
    Y = ml_format(select(t, y))
    W = ml_format(select(t, w))
    mldata(x=X, y=Y, w=W)
end

ml_format(x::AbstractTable) = Matrix(x)
ml_format(x::AbstractVector) = x
ml_format(x::Nothing) = nothing

function Base.show(io::IO, o::MLData)
    s = (o.x != nothing && o.y != nothing) ? "supervised" : "unsupervised"
    print(io, "MLData ($s)\n  ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬")
    o.x != nothing && print(io, "\n  > x: ", summary(o.x))
    o.y != nothing && print(io, "\n  > y: ", summary(o.y))
    o.w != nothing && print(io, "\n  > w: ", summary(o.w))
end

xy(o::MLData) = o.x, o.y
xyw(o::MLData) = o.x, o.y, o.w

nobs(o::MLData{<:AbstractArray}) = size(o.x, 1)
nobs(o::MLData{Nothing, <:AbstractArray}) = size(o,y, 1)

npredictors(o::MLData{<:AbstractArray}) = size(o.x, 2)
npredictors(o::MLData{Nothing}) = 0