
# Shorter error definitions
@noinline argerr(x) = throw(ArgumentError(x))

"""
    struct BitField

Represents the bitfields of a bitstruct before evaluation.

# Fields

- `name::Symbol`
- `type::Union{Symbol,Expr}`
- `bitlength::Union{Int,Nothing}`: length of bit representation
- `doc::Union{String,Nothing`
"""
struct BitField
    name::Symbol
    type::Union{Symbol,Expr}
    bitlength::Union{Int,Nothing}
    doc::Union{String,Nothing}
end

_BitField(ex) = _BitField(nothing, ex)

function _BitField(doc, ex)
    # Doc is checked on BitField construction
    # Check if valid field definition
    Meta.isexpr(ex, :(::)) || argerr("$(ex) is not a valid bitfield definition")
    name = ex.args[1]
    if Meta.isexpr(ex.args[2], :ref)
        L = ex.args[2].args[2]
        # Check if valid field length provided
        isa(L, Int) || argerr("Bitfield length $L is not a valid integer.")
        return BitField(name, ex.args[2].args[1], L, doc)
    else
        return BitField(name, ex.args[2], nothing, doc)
    end
end

"""
    @BitField "Docstring for field" field1::Type1[[BitLength1]]
    @BitField field1::Type1[[BitLength1]]

Convenience macro for BitField constructor. Same syntax as in regular structs is used, but:
    - A docstring may be provided as first argument
    - Bitlength can be provided
bitlength can optionally be appended within square brackets (the outer pair of brackets is
there only to convey the opt-in nature of the feature, not as syntax), and a docstring may 
be provided as first argument

# Usage

Since it returns the expression for a BitField, bind the result to a variable:
```
julia> f1 = @BitField
```
"""
macro BitField(args...)
    L = length(args)
    if L < 1 
        argerr("Provide at least 1 argument.")
    elseif L == 1
        return _BitField(nothing, only(args))
    elseif L == 2
        return _BitField(args[1], args[2])
    else
        argerr("Provide only 1 or 2 arguments.")
    end
end



"""
    mutable struct BitStruct

Represents the structure of a bitstruct before evaluation.

    BitStruct(;kw...)

Create a BitStruct instance.

# Struct Fields and Available Keyword Arguments

The only required keyword argument for constructor is `name`, the rest have defaults and may
be added after creation.

- `name::Symbol`
- `supertype`
- `fields::Vector{BitFields}`
- `doc::Union{String,Nothing}`
- `bitholder::Symbol`
"""
mutable struct BitStruct
    name::Symbol
    supertype::Union{Nothing,Symbol,Expr}
    fields::Vector{BitField}
    doc::Union{Nothing,String}
    bitholder::Symbol
end
function BitStruct(; 
    name::Symbol,  
    supertype=nothing, 
    fields=BitField[], 
    doc=nothing, 
    bitholder=:_bits_)
    return BitStruct(name, supertype, fields, doc, bitholder)
end

function validate_bitstruct(m::Module, bs::BitStruct)

end




macro generate_bitstruct(args...)
    # Error handling
    length(args) < 1 && argerr("Provide at least 1 argument.")
    while isa(args[1], LineNumberNode)
        popfirst!(args)
    end
    bitstruct = getfield(__module__, args[1])
    isa(bitstruct, BitStruct) || argerr("Provide a bitstruct as first argument")

    # Analyze BitStruct provided
    N = length(bitstruct.fields)
    name = bitstruct.name
    header = isnothing(bitstruct.supertype) ? bitstruct.name : Expr(:(<:), Any[bitstruct.name, bitstruct.supertype])
    arguments = [s.name for s in bitstruct.fields]
    bitlengths = map(bitstruct.fields) do s
        t = s.type
        if Meta.isexpr(t, :ref)
            T = @eval(__module__, $(t.args[1]))
            return _bitlength(T, t.args[2])
        else
            T = @eval(__module__, $(t))
            return bitlength(T)
        end
    end
    indices = accumulate((a, b) -> (a[2] + 1, a[2] + b), bitlengths, init=(0,0))
    L = t_idx[end][2]
    
    # Struct definition and inner constructor
    ex_struct = quote
        Base.@__doc__ struct $(header)
            "Bitholder for $(name)"
            $(bitholder)::BitVector
            # Inner constructor that checks length
            function $(name)(b)
                length(b) == $(L) || argerr("$(name) has $(L) bits, not $(length(b))")
                return new(b)
            end # inner constructor
        end # struct
    end # quote

    # Outer constructor (using fields)
    ex_oc = JLFunction(;
        head=:function, 
        name=name, 
        args=arguments, 
        doc=_bitfield_constructor_docs(name, arguments))
        # Convert arguments to supposed types
        # Convert supposed types to bitvectors
        # vcat bitvectors
        # Create and return bitstruct

    # Getter (typed fields)

    # Getter (bits)

    # Setter (typed fields)

    # Setter (bits)

    # Set bit traits for new type (in case it needs be composed with other BitStructs)

    # TODO Document "inner fields" (see Julia internals for docs)
    

    # Escape everything in return quote block
    ex = quote end # quote
    push!(ex.args, ex_struct.args...)
    return ex
    

end









# @bit
"""
    @bit StructName <: SuperType
        "Possible docstring for bitfield1"
        bitfield1::BitType1[length1]
        bitfield2::BitType2[length2]
        ...
    end [bitholder=_bits_] [no_constructor] [no_getters] [no_setters] [autodocs]

Create and eval code for given bitstruct. It runs at compile time?

# Optional arguments

- `bitholder`: specifies a name for BitStruct bitholder field. It defaults to `_bits_`
- `no_constructor`: default constructor by fields is not to be generated
- `no_getters`: field- and vector-like getters are not to be generated
- `no_setters`: field- and vector-like setters are not to be generated
- `autodocs`: procedural docstring is to be generated
"""
macro bit(args...)
    # Capture module and forward to lower functions.
    return esc(bit_m(__module__, args))
end

# parse arguments and generate code
function bit_m(m::Module, args)
    args = macroexpand.(m, args)
    (bitstruct, add_c, add_g, add_s, add_d) = parse_bitstruct_args(args)
    return codegen_bitstruct(m, bitstruct, add_c, add_g, add_s, add_d)
end

# codegen functions
# TODO

function codegen_bitstruct(m::Module, bs::BitStruct, add_c::Bool, add_g::Bool, add_s::Bool, add_d::Bool)
    # preprocess bitstruct (note, this evals code)
    validate_bitstruct(m, bs)
    # add_field_defaults!(m, bs)

    # Define return expression
    ex = Expr(:block)

    # Type expressions and docstrings

    # Field-by-field constructor (optional)
    add_c && append!(ex.args, codegen_constructor(m, bs).args)
    # Getters (optional)
    add_g && append!(ex.args, codegen_getters(m, bs).args)
    # Setters (optional)
    add_s && append!(ex.args, codegen_setters(m, bs).args)
    # Return nothing as last call to macro
    push!(ex.args, :nothing)
    # # 
    # quote
    #     $(codegen_bitstruct_type(m, bs))
    #     Core.@__doc__ $(def.name)
    #     $(codegen_create(def))
    #     $(codegen_is_option(def))
    #     $(codegen_convert(def))
    #     $(codegen_field_default(def))
    #     $(codegen_type_alias(def))
    #     $(codegen_isequal(def))
    #     $(codegen_from_dict_specialize(def))
    #     nothing
    # end
end

function codegen_bitstruct_type(mod::Module, bs::BitStruct, add_d::Bool=False)
    # Generate Expr/Symbol for header (inherently type unstable, either Symbol or Expr)
    header = isnothing(bs.supertype) ? bs.name : :($(bs.name) <: $(bs.supertype))
    if add_d
        quote

        end
    else
        quote
            Base.@__doc__ struct $(header)
                "Bitholder for $(name)"
                $(bitholder)::BitVector
                # Inner constructor that checks length
                function $(name)(b)
                    length(b) == $(L) || argerr("$(name) has $(L) bits, not $(length(b))")
                    return new(b)
                end # inner constructor
            end # struct
        end # quote
    end # if
end # function

function codegen_constructor(mod::Module, bs::BitStruct, add_c::Bool=false)
    
end

function codegen_getters(mod::Module, bs::BitStruct)

end

function codegen_setters(mod::Module, bs::BitStruct)

end


# argument parsers
"""
    parse_bitstruct_args(args)

Parse arguments to `@bit` macro.

# Arguments
- `args::Vector{Any}`: arguments to `@bit` macro. See [@bit](bit)

# Returns
- `b::BitStruct`: BitStruct representation of type
- `add_constructor::Bool = true`: `false` if default constructor by fields is not to be generated
- `add_getters::Bool = true`: `false` if field- and vector-like getters are not to be generated
- `add_setters::Bool = true`: `false` if field- and vector-like setters are not to be generated
- `add_docs::Bool = false`: `true` if procedural docstring is to be generated
"""
function parse_bitstruct_args(args)
    # Find struct location
    i = findfirst(Meta.isexpr.(args, :struct))
    isnothing(i) && argerr("Provide a struct")
    # Parse bitstruct
    bitstruct = parse_bitstruct(args[i])
    # Look for flags
    add_constructor = !(:no_constructor ∈ args)
    add_getters = !(:no_getters ∈ args)
    add_setters = !(:no_setters ∈ args)
    add_docs = :autodocs ∈ args
    # Change bitholder name if desired
    j = findfirst(Meta.isexpr.(args, :(=)))
    if !isnothing(j)
        !isa(args[j].args[2], Symbol) && argerr("Provide a valid name for bitholder")
        bitstruct.bitholder = args[j].args[2]
    end
    # Return
    return (bitstruct, add_constructor, add_getters, add_setters, add_docs)
end

"""
    parse_bitstruct(ex)

Parses the given `Expr` (of type `:struct`) to a BitStruct object. It does not check 
bitfield lengths associated to types. See format of bitfields in [@bit](bit)
"""
function parse_bitstruct(ex::Expr)
    # _mutable = ex.args[1] # TODO?
    _name = isa(ex.args[2], Symbol) ? ex.args[2] : ex.args[2].args[1]
    _supertype = isa(ex.args[2], Symbol) ? nothing : ex.args[2].args[2]
    _fields = BitField[]
    for f in ex.args[3]
        # Discard line numbers
        isa(f, LineNumberNode) && continue
        # Process fields
        push!(_fields, BitField(f))
    end
    return BitStruct(_name, _supertype, _fields, nothing, :_bits_)
end


# docstring generators
# BitStruct constructor by fields
function _bitfield_constructor_docs(name, arguments)
    return """
        $(name)($(join(arguments, ", ")))

    Create a $(name) instance given its fields.
    """
end



