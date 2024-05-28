using Documenter, MethodInspector

makedocs(
    sitename="MethodInspector.jl Documentation",
    format=Documenter.HTML(
        prettyurls = false,
        edit_link="main",
    ),
    modules=[MethodInspector],
)

deploydocs(
    repo = "github.com/bluesmoon/MethodInspector.jl.git",
)
