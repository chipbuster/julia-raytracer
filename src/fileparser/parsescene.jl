include("tokenize.jl")
include("../sceneObjects.jl")

using StaticArrays
using LinearAlgebra

# Define utility functions to abstract away vector-of-tokens
# We may need to change the internal representation (e.g. via reversing) later
"""Destructively read and return next token"""
function Get!(stream::Vector{T})::T where {T}
    return popfirst!(stream)
end

"""Non-destructively look at next token (it remains on stream)"""
function Peek(stream::Vector{T})::T where {T}
    return stream[1]
end

"""Get the next token and check that it's of the expected type"""
function Read!(stream::Vector{Token}, tokt::TokType)::Token
    head = popfirst!(stream)
    if head isa SymbolToken && head.kind == tokt
        return head
    else
        error("Token was not of expected type: expected a " * string(tokt) * "
              but got a " * string(head.kind))
    end
end

function parseScene(tokens::Vector{Token})::Vector{SceneObject}
    Read!(tokens,SBT_RAYTRACER)

    objs = Vector{SceneObject}()
    scenetrans = SMatrix{3,3}(Matrix{Float64}(I,3,3)) #Used to track transformation of the element
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
                Read!(tokens, SEMICOLON)
            elseif t.kind == EOFSYM
                return objs
            else
                error("Unexpected token in stream " * string(t))
            end
    end
end

function parseTransformableElement()
    error("Not implemented")
end

function parsePointLight(tokens::Vector{Token})
    position = @SVector [0,0,0]
    color = @SVector [0,0,0]

    constantAttenCoeff = 0.0
    linearAttenCoeff = 0.0
    quadAttenCoeff = 1.0

    hasPos, hasCol = false,false

    Read!(tokens, POINT_LIGHT)
    Read!(tokens, LBRACE)

    # Enter parse loop until error or finish
    while true
        t = Peek(tokens)
        if t.kind == POSITION
            if hasPos
               error("Repeated position attribute in point light") 
            end
            position = parseVec3dExpression(tokens)
            hasPos = true
        elseif t.kind == COLOR
            if hasCol
                error("Repeated color attribute in point light")
            end
            color = parseVec3dExpression(tokens)
            hasCol = true
        elseif t.kind == CONSTANT_ATTENUATION_COEFF
            constantAttenCoeff = parseScalarExpression(tokens)
        elseif t.kind == LINEAR_ATTENUATION_COEFF
            linearAttenCoeff = parseScalarExpression(tokens)
        elseif t.kind == QUADRATIC_ATTENUATION_COEFF
            quadAttenCoeff = parseScalarExpression(tokens)
        elseif t.kind == RBRACE
            _ = Get!(tokens) #Consume the brace first, then decide what to do
            if(!hasCol)
                error("Attempted to get PointLight without color")
            elseif(!hasPos)
                error("Attempted to get PointLight without position")
            else
                break
            end
        else
            error("Unexpected token in PointLight: " * string(t))
        end
    end
    return PointLight(color,position,
                      (constant = constantAttenCoeff,
                       linear = linearAttenCoeff,
                       quadratic = quadAttenCoeff))
end

function parseVec3dExpression(tokens::Vector{Token})
    _ = Get!(tokens)
    _ = Read!(tokens, EQUALS)
    vec = parseVec3d(tokens)
    Read!(tokens, SEMICOLON)
    return vec
end

function parseVec3d(tokens::Vector{Token})
    _ = Read!(tokens, LPAREN)
    a = Get!(tokens).value
    _ = Read!(tokens, COMMA)
    b = Get!(tokens).value
    _ = Read!(tokens, COMMA)
    c = Get!(tokens).value
    _ = Read!(tokens, RPAREN)

    return @SVector [a,b,c]
end

function parseScalarExpression(tokens::Vector{Token})
    _ = Get!(tokens) # Throw out first token, which precedes the = sign
    _ = Read!(tokens, EQUALS)
    val = parseScalar(tokens)
    _ = Read!(tokens, SEMICOLON)
    return val
end

function parseScalar(tokens::Vector{Token})
    return Get!(tokens).value
end

function parseAreaLight()
    error("Not implemented")
end

function parseDirectionalLight()
    error("Not implemented")
end

function parseAmbientLight()
    error("Not implemented")
end

function parseMaterial()
    error("Not implemented")
end

function parseCamera()
error("Not implemented")
end
