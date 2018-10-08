include("parsescene.jl")

function read_rayfile(fname::AbstractString)
    open(fname) do f
        firstline = readline(f)
        if firstline != "SBT-raytracer 1.0"
                error(fname * " is not a valid ray file.")
            else
                return parse_raycontents(f)
        end
    end
end

function parse_raycontents(contents::IOStream)
    tokens = scanprogram(contents)
    out = parseScene(tokens)
    println(out)
end
