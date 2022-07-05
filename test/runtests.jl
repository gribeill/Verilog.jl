using Verilog
using Test

#makes life much easier.
macro test_string(string, expr)
  :(@test string($expr) == $string)
end

#test the wire functions
include("test-wires.jl")

#test boolean operations
include("test-boolop.jl")

#test verilog generation
include("test-verigen.jl")

#test multiple outputs
include("test-multioutput.jl")

#test wire arrays
include("test-wirearray.jl")
