include("parsescene.jl")

import .RayParse.RayLex: tokenizeProgram
import .RayParse: parseScene

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
    tokens = tokenizeProgram(contents)
    out = parseScene(tokens)
    println(out)
end

read_rayfile(ARGS[1])