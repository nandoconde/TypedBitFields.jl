# Intrinsic primitive numeric types
NumTypes = Union{UInt8,UInt16,UInt32,UInt64,Int8,Int16,Int32,Int64,Int128,Float16,Float32,Float64}
bitlengthtype(::Type{<:NumTypes}) = FixedBitLength()
bitlength(::FixedBitLength, T::Type{<:NumTypes}) = sizeof(T) * 8
bitlength(::FixedBitLength, ::T) where {T<:NumTypes} = bitlength(T)
function tobits(x::T) where T<:Union{UInt8,UInt16,UInt32,UInt64,Int8,Int16,Int64,Int128,Float16,Float32,Float64}
    B = sizeof(T)
    if B == 1
        S = UInt8
    elseif B == 2
        S = UInt16
    elseif B == 4
        S = UInt32
    elseif B == 8
        S = UInt64
    end
    return BitVector(((b >>> i) & 0x01) == 1 for i in 0:(8 * B - 1) for b = Ref(reinterpret(S, x)))
end
function frombits(T::Type{<:NumTypes}, b::BitVector)
    a = zero(T)
    for i in b
        a <<= 1
        a |= T(i)
    end
    return a
end


# Bitarray
bitlength(b::BitArray) = length(b)
tobits(b::BitArray) = reshape(b, length(b))


# Bool
bitlength(::Bool) = 1
bitlength(::Type{<:Bool}) = 1
tobits(b::Bool) = b ? trues(1) : falses(1)


# Dummy
"""
    DummyBits

Struct representing dummy bits ('0') of given length.
"""
struct DummyBits{N} end

bitlength(::DummyBits{N}) where N = N::Int64
bitlength(::Type{DummyBits{N}}) where N = N::Int64
tobits(::DummyBits{N}) where N = falses(N::Int64)