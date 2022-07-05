
import Base.show

function show(io::IO, w::Wire{R}) where {R}
  show(io, typeof(w))
  print(io, "(0b")
  print(io, join([w.assigned[idx] ? (w.values[idx] ? "1" : "0") : "X" for idx = length(w):-1:1],""))
  print(io, ")")
end

function show(io::IO, ::Type{Wire{R}}) where {R}
  print(io, "Wire{",R.stop,":",R.start,"v}")
end
