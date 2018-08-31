import Base.IOStream
import Base.Strings

include("tokenize.jl")


function read_rayfile(fname::AbstractString)
    open(fname) do f
        firstline = readline(f)
        if firstline != "SBT-raytracer 1.0"
                error(fname * " is not a valid ray file.")
            else
                contents = read(f,String)
                return parse_raycontents(contents)
        end
    end
end

function parse_raycontents(contents::AbstractString)
    tokens = scanprogram(contents)
end
