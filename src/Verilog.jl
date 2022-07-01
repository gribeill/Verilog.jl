module Verilog

  #support for -v suffixed verilog-style ranges.
  #support for python-style range() indexing
  include("verilog_ranges.jl")

  include("Wire.jl")
  include("wire-display.jl")

  include("booleanops.jl")
  include("arithmeticops.jl")

  #the magical verilog macro
  include("verilog_macro.jl")

  #verigen - where verilog generation happens
  include("Verigen.jl")
  #verilog generation passes these objects around.
  include("WireObject.jl")

  #codegen contains resources to create .v files and verilate them.
  using Base.Sys: islinux
  if islinux()
    include("codegen.jl")
    include("verilator-adapter.c.jl")
  end

end # module
