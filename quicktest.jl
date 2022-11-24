package_flag = true


using Pkg
if @isdefined package_flag
    Pkg.activate(".")
else
    Pkg.activate(; temp=true)
    Pkg.add("Expronicon")
end
using Expronicon
include("src/bittraits.jl")
include("src/bitfunctions.jl")
# include("src/bitsequence.jl")
include("src/fieldtypes.jl")





s1 = :(
    struct INAV_E1_B
        even_odd_1::Bool
        type::Bool
        data1::BitVector[6]
        tail1::BitSequence[6]
    end
)

ex = :(
    struct Prueba <: Padre
        flag::Bool
        number::UInt64
        shortnumber::Int32[32]
        paramtype::DummyBits{27}
    end
)

f1 = BitField(:flag, :Bool, 1)
f2 = BitField(:number, :UInt64, 64)
f3 = BitField(:shortnumber, :Int32, 32)
f4 = BitField(:paramtype, :DummyBits, 27)



_, t_name, _, t_supertype, _ = split_struct(ex)
ex_jlstruct = JLStruct(ex)
t_fields = ex_jlstruct.fields
N = length(t_fields)
t_typesize = map(t_fields) do s
    t = s.type
    if isa(t, Expr) && t.head == :ref
        T = @eval($(t.args[1]))
        L = t.args[2]
        return(T, _bitlength(T, L))
    else
        T = @eval $(t)
        return (T, bitlength(T))
    end
end
t_indices = accumulate((a, b) -> (a[2] + 1, a[2] + b[2]), t_typesize, init=(0,0))
t_L = t_indices[end][2]

# Create inner constructor that checks if passed BitVector has length t_indices[end][2]
err
ex_ic = JLFunction(;
    head=:function,
    name=t_name,
    args=[:b],
    body=JLIfElse(
            [:(length(b) == $(t_L))], 
            [:(new(b))], 
            :(throw(ArgumentError("$(t_name) needs BitVector of length $(t_L), not $(esc(length(b)))"))))
    )

ex_T = JLStruct(; 
    name=t_name, 
    supertype=t_supertype, 
    fields=[JLField(;name=:__bits__, type=BitVector)])


# Create struct
## Substitute types by bitarray
# Create traits

# Create related functions

# Create getters

# Create setters


