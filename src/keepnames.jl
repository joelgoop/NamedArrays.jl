## index.jl  methods for NamedArray that keep the names (some checking may be done)

## (c) 2013, 2014 David A. van Leeuwen

## This code is licensed under the MIT license
## See the file LICENSE.md in this distribution

# Keep names for consistently named vectors, or drop them
function Base.hcat(N::NamedVecOrMat...)
    keepnames=true
    N1=N[1]
    firstnames = names(N1,1)
    for i=2:length(N)
        keepnames &= names(N[i],1)==firstnames
    end
    a = hcat(map(a -> a.array, N)...)
    if keepnames
        colnames = defaultnamesdict(size(a,2))
        NamedArray(a, (N1.dicts[1], colnames), (N1.dimnames[1], :hcat))
    else
        NamedArray(a)
    end
end

function Base.vcat(N::NamedMatrix...)
    keepnames=true
    N1=N[1]
    firstnames = names(N1,2)
    for i=2:length(N)
        keepnames &= names(N[i],2)==firstnames
    end
    a = vcat(map(a -> a.array, N)...)
    if keepnames
        rownames = defaultnamesdict(size(a,1))
        NamedArray(a, (rownames, N1.dicts[2]), (:vcat, N1.dimnames[2]))
    else
        NamedArray(a)
    end
end

function Base.vcat(N::NamedVector...)
    a = vcat(map(n -> n.array, N)...)
    anames = vcat(map(n -> names(n, 1), N)...)
    if length(unique(anames)) == length(a)
        return NamedArray(a, (anames,), (:vcat,))
    else
        return NamedArray(a, (defaultnamesdict(length(a)),), (:vcat,))
    end
end

## broadcast
Base.Broadcast.broadcast_t(f, T, n::NamedArray, As...) = broadcast!(f, similar(n, T, Base.Broadcast.broadcast_shape(n, As...)), n, As...)

## reorder names
import Base: sort, sort!
function sort!(v::NamedVector; kws...)
    i = sortperm(v.array; kws...)
    newnames = names(v, 1)[i]
    empty!(v.dicts[1])
    for (ind, k) in enumerate(newnames)
        v.dicts[1][k] = ind
    end
    v.array = v.array[i]
    return v
end

sort(v::NamedVector; kws...) = sort!(copy(v); kws...)

## Note: I can't think of a sensible way to define sort!(a::NamedArray, dim>1)

## drop name of sorted dimension, as each index along that dimension is sorted individually
function sort(n::NamedArray, dim::Integer; kws...)
    if ndims(n)==1 && dim==1
        return sort(n; kws...)
    else
        nms = names(n)
        nms[dim] = [string(i) for i in 1:size(n, dim)]
        return NamedArray(sort(n.array, dim; kws...), tuple(nms...), n.dimnames)
    end
end
