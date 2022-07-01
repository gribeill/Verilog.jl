#wire.jl - defines the Wire type.  Wires are stored under the hood as bitvectors.

struct UnassignedError   <: Exception; end
struct AssignedError     <: Exception; end
struct SizeMismatchError <: Exception; end


"""
  `Wire{R}`

  is the basic type for Verilog operations.  R specifies a "unit range" of integers.
  Use the "v" suffix to enable verilog-style ranging.

  Wire{3:0v} declares a four-digit verilog wire with indices spanning from 0->3;
  Wire{6:2v} declares a five-bit verilog wire with indices spanning from
  2->6.
"""
struct Wire{R}
  values::BitVector
  assigned::BitVector

  function Wire{R}(bv1, bv2) where {R}
    isa(R, VerilogRange) || throw(TypeError(:Wire, "specifier must be a VerilogRange", VerilogRange, typeof(R)))
    (R.start <= R.stop) || throw(TypeError(:Wire, "constructor range direction failed", R, "backwards"))
    (length(bv1) == length(bv2) == length(R)) || throw(SizeMismatchError())
    new{R}(bv1, bv2)
  end
end

################################################################################
## Aliased naked constructors.
(::Type{Wire})(bv::Bool)               = Wire{0:0v}(BitArray([bv]),trues(1))
(::Type{Wire})(N::Signed)              = Wire{(N-1):0v}(BitVector(undef, N), falses(N))
(::Type{Wire})(R::VerilogRange)        = Wire{R}(BitVector(undef, length(R)), falses(length(R)))
(::Type{Wire})(bv::BitVector)          = Wire{(length(bv)-1):0v}(bv, trues(length(bv)))
#allow initialization of wire with an array, but remember to reverse it.
(::Type{Wire})(wa::Vector{Wire{R}}) where {R}      = Wire(vcat(map((w) -> w.values, reverse(wa))...))
(::Type{Wire})(ws::Wire...)                        = Wire(collect(Wire, ws))

#declaration with an unsigned integer
function (::Type{Wire})(N::Unsigned, l::Integer = 0)
  #override an unspecified length.
  l = (l == 0) ? sizeof(N) * 8 : l
  #mask out crap we don't want.
  Wire(N, range(l))
end
function (::Type{Wire})(N::Unsigned, r::VerilogRange)
  Wire{r}(N)
end

function (::Type{Wire{R}})(N::Unsigned) where {R}
  #instantiate a bitarray.
  l = length(R)
  ba = BitVector(length(R))

  N = (l < 64) ? (UInt64(N) & ((1 << l) - 1)) : UInt64(N)
  ba.chunks[1] = N
  #pass this to the bitarray-based constructor.
  Wire{R}(ba, trues(l))
end

function (::Type{Wire{R}})() where {R}
  Wire{R}(falses(length(R)), falses(length(R)))
end

struct UnsignedBigInt <: Unsigned
  value::BitArray
end

################################################################################
# conversion away from wires - necessary for integer reintepretation of verilog
# wire definitons

function Base.convert(::Type{Unsigned}, w::Wire{R}) where {R}
  if length(R) <= 64
    return w.values.chunks[1]
  else
    return UnsignedBigInt(w.values)
  end
end

# also allow conversion from wire tuples - will be automatically triggered during
# integer reinterpretations.

function Base.convert(::Type{Unsigned}, wt::Tuple)::Unsigned
  for el in wt
    !isa(el, Wire) && throw(ArgumentError("Tuple must be a wire tuple"))
  end
  Wire(wt...)  #expand the tuple.  will be autoconverted to unsigned.
end


################################################################################

#useful helper functions
import Base: length, range

length(w::Wire{R}) where {R} = length(R)
range(w::Wire{R})  where {R} = R
assigned(w::Wire) = (&)(w.assigned...)

################################################################################
# getters and setters
import Base: getindex, setindex!

function getindex(w::Wire{R}, n::Integer) where {R}
  (n in R) || throw(BoundsError(w, n))
  #adjust for array indexing.
  access_idx = n + 1 - R.start
  #gets the relevant index, if it's been defined.
  w.assigned[access_idx] || throw(UnassignedError())
  Wire(w.values[access_idx])
end

getindex(w::Wire{R}, ::Type{msb}) where {R}    = getindex(w, R.stop)
getindex(w::Wire{R}, ridx::msb)   where {R}    = getindex(w, R.stop - ridx.value)

function getindex(w::Wire{R}, r::VerilogRange) where {R}
  #returns a wire with the relevant selected values.
  issubset(r, R) || throw(BoundsError(w, r))
  rr = ((r.stop >= r.start) ? (r.start:r.stop) : (r.start:-1:r.stop))
  (&)(w.assigned[rr + 1 - R.start]...) || throw(UnassignedError())
  Wire(w.values[rr + 1 - R.start])
end

getindex(w::Wire{R}, r::RelativeRange) where {R} = getindex(w, parse_msb(r, R))

################################################################################
## setters

function setindex!(dst::Wire{R}, src::Wire{0:0v}, n::Integer) where {R}
  (n in R) || throw(BoundsError(dst, n))
  offset_idx = n - R.start + 1

  #chcek that the src value exists.
  src.assigned[1] || throw(UnassignedError())
  dst.assigned[offset_idx] && throw(AssignedError())
  dst.assigned[offset_idx] = true
  dst.values[offset_idx] = src.values[1]
  nothing
end

setindex!(dst::Wire{R}, src::Wire{0:0v}, ::Type{msb}) where {R} = setindex!(dst, src, R.stop)
setindex!(dst::Wire{R}, src::Wire{0:0v}, m::msb)      where {R} = setindex!(dst, src, R.stop - m.value)

#you can dereference things as stepranges, but you can't dereference things
#as stepranges.
function Base.setindex!(dst::Wire{RD}, src::Wire{RS}, r::VerilogRange) where {RD, RS}
  #check for size mismatch.
  (r.stop >= r.start) || throw(ArgumentError("only forward VerilogRanges allowed for setting"))
  (length(r) == length(RS)) || throw(SizeMismatchError())
  (issubset(r, RD)) || throw(BoundsError(dst, r))

  #the range offset to where they're actually stored in the destination array
  offset_range = r - RD.start + 1
  for idx in 1:length(r)
    dst.assigned[offset_range[idx]] && throw(AssignedError())
    src.assigned[idx]               || throw(UnassignedError())
  end

  for idx in 1:length(r)
    dst.assigned[offset_range[idx]] = true
    dst.values[offset_range[idx]]   = src.values[idx]
  end

  nothing
end

Base.setindex!(dst::Wire{RD}, src::Wire{RS}, r::RelativeRange) where {RD, RS} = setindex!(dst, src, parse_msb(r, RD))

#it's useful to declare a single wire shorthand
const SingleWire = Wire{0:0v}

const OptionalWire{R}    = Union{Nothing, Wire{R}} where R
const OptionalSingleWire = Union{Nothing, SingleWire}

export Wire, SingleWire, OptionalWire, OptionalSingleWire
