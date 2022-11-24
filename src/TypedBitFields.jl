module TypedBitFields

using Expronicon

include("bittraits.jl")
include("bitfunctions.jl")
# include("bitsequence.jl")
include("fieldtypes.jl")
include("bitstruct.jl")


export bitlength, tobits, frombits


end # module TypedBitFields
