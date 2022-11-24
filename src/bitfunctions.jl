"""
    tobits(x)

Get bitarray representation from x.

This method must be implemented for a type to be part of a BitStruct.
"""
function tobits end


"""
    frombits(T, b)

Get T object from its bitarray representation b.

This method must be implemented for a type to be part of a BitStruct.
"""
function frombits end


"""
    bitlength(x)

Get length of tobits(x) result.

x must implement a BitSizeType trait. By default, UnknownBitSize is assigned.
"""
bitlength(x::T) where T = bitlength(bitlengthtype(T), x)
bitlength(::Type{T}) where T = bitlength(bitlengthtype(T), T)
_bitlength(x::T, l) where T = _bitlength(bitlengthtype(T), x, l)
_bitlength(t::Type{T}, l) where T = _bitlength(bitlengthtype(T), t, l)

# Default type implementations
# UnknownBitSize
bitlength(::UnknownBitLength, ::Type{T}) where T = throw(ArgumentError("Implement BitSizeType trait for type $(T)."))
bitlength(::UnknownBitLength, x::T) where T = throw(ArgumentError("Implement BitSizeType trait for type $(T)."))
_bitlength(::UnknownBitLength, x::Type{T}, _)  where T = throw(ArgumentError("Implement BitSizeType trait for type $(T)."))
_bitlength(::UnknownBitLength, x::T, _)  where T = throw(ArgumentError("Implement BitSizeType trait for type $(T)."))

# VariableBitSize
bitlength(::VariableBitLength, ::Type{T}) where T = throw(ArgumentError("$(T) has a variable bit size. Call bitlength over an instance instead of its type."))
bitlength(::VariableBitLength, x) = length(tobits(x))
# _bitlength(::VariableBitSize, ::Type, l::Int64) = l
_bitlength(::VariableBitLength, _, l::Int64) = l # This method captures both behaviors

# FixedBitSize
_bitlength(f::FixedBitLength, ::Type{T}, l::Int64) where T = (bitlength(f, T) == l) ? l : throw(ArgumentError("Supplied length $l does not match bitlength of $(T)"))
_bitlength(::FixedBitLength, l::Int64) = l