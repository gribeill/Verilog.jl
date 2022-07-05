using Verilog
using Documenter

DocMeta.setdocmeta!(Verilog, :DocTestSetup, :(using Verilog); recursive=true)

makedocs(;
    modules=[Verilog],
    authors="Guilhem Ribeill <guilhem.ribeill@gmail.com> and contributors",
    repo="https://github.com/gribeill/Verilog.jl/blob/{commit}{path}#{line}",
    sitename="Verilog.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://gribeill.github.io/Verilog.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/gribeill/Verilog.jl",
    devbranch="master",
)
