using VerilogTemp
using Documenter

DocMeta.setdocmeta!(VerilogTemp, :DocTestSetup, :(using VerilogTemp); recursive=true)

makedocs(;
    modules=[VerilogTemp],
    authors="Guilhem Ribeill <guilhem.ribeill@gmail.com> and contributors",
    repo="https://github.com/gribeill/VerilogTemp.jl/blob/{commit}{path}#{line}",
    sitename="VerilogTemp.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://gribeill.github.io/VerilogTemp.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/gribeill/VerilogTemp.jl",
    devbranch="master",
)
