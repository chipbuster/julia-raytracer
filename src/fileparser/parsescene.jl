include("tokenize.jl")
include("../sceneObjects.jl")

# Define utility functions to abstract away vector-of-tokens
"""Destructively read and return next token"""
function Get(stream::Vector{T})::T where {T}
    return popfirst!(stream)
end

"""Non-destructively look at next token (it remains on stream)"""
function Peek(stream::Vector{T})::T where {T}
    return stream[1]
end

"""Get the next token and check that it's of the expected type"""
function Read(stream::Vector{Token}, tokt::TokType)::Bool
    head = popfirst!(stream)
    if head isa SymbolToken && head.kind == tokt
        return head
    else
        error("Token was not of expected type")
    end
end

function parseScene(tokens::Vector{Token})::Vector{SceneObject}
    Read(tokens,SBT_RAYTRACER)

    objs = Vector{SceneObject}
    scenetrans = eye(SMatrix{3,3}) #Used to track transformation of the element
    mat = nothing::Union{Nothing, Material}
    while !isempty(tokens)
        t = Peek(tokens)
            if t.kind in [SPHERE,BOX,SQUARE,CYLINDER,CONE,TRIMESH,TRANSLATE
                         ,ROTATE,SCALE,TRANSFORM,LBRACE]
                         parseTransformableElement(tokens,objs,scenetrans)
            elseif t.kind == POINT_LIGHT
                push!(objs, parsePointLight(tokens))
            elseif t.kind == AREA_LIGHT
                push!(objs, parseAreaLight(tokens))
            elseif t.kind == DIRECTIONAL_LIGHT
                push!(objs, parseDirectionalLight(tokens))
            elseif t.kind == AMBIENT_LIGHT
                push!(objs, parseAmbientLight(tokens))
            elseif t.kind == CAMERA
                push!(objs, parseCamera(tokens))
            elseif t.kind == MATERIAL
                newmat = parseMaterial(tokens)
                mat = newmat
            elseif t.kind == SEMICOLON
                Read(tokens, SEMICOLON)
            elseif t.kind == EOFSYM
                return objs
            else
                error("Unexpected token in stream")
            end
    end
end
