include("parsescene.jl")

import .RayParse.RayLex: tokenizeProgram
import .RayParse: parseScene

function read_rayfile(fname::AbstractString)
    open(fname) do f
        firstline = readline(f)
        if firstline != "SBT-raytracer 1.0"
                error(fname * " is not a valid ray file.")
            else
                return parse_raycontents(f,fname)
        end
    end
end

function parse_raycontents(contents::IOStream, fname::AbstractString)
    tokens = tokenizeProgram(contents, fname)
#    out = parseScene(tokens)
print(tokens)
    println(out)
end

#read_rayfile(ARGS[1])