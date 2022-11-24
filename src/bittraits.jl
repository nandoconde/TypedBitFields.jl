
# TODO Docstrings and example
"""
"""
abstract type BitLengthType end

# TODO Docstrings and example
"""
"""
struct UnknownBitLength <: BitLengthType end

# TODO Docstrings and example
"""
"""
struct FixedBitLength <: BitLengthType end

# TODO Docstrings and example
"""
"""
struct VariableBitLength <: BitLengthType end


# TODO Docstring and example
"""
"""
bitlengthtype(x)

# Default trait
bitlengthtype(x) = UnknownBitLength()

## --------------------------
#            NOTE
## --------------------------
# This trait should be defined for each type in the same file and just before as its 
# bitlength and tobits implementation.