include("tokenize.jl")
include("../sceneObjects.jl")

using StaticArrays
using LinearAlgebra

#= Note: almost all parsing functions within this module modify their inputs.
#        I forgot to follow naming conventions until it was too late. Since
#        most functions aren't exported, this shouldn't affect the outside
#        world, but if you're modifying this file, remember that essentially
#        every function here except Peek() is expected to modify its input. =#

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
    camera = Camera(MMatrix{3,3}(Matrix{Float64}(I,3,3)), 1, 1,
                    @MVector zeros(3), @MVector zeros(3),
                    @MVector zeros(3), @MVector zeros(3))
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
                parseCamera(tokens, camera) #parseCamera mutates camera in-place
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

function parsePointLight(tokens::Vector{Token})::PointLight
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

# Final project implementation--ignore
function parseAreaLight()
    error("What are you calling this for, nerd?")
end

function parseDirectionalLight(tokens::Vector{Token})::DirectionalLight
    direction = @SVector [0,0,0]
    color = @SVector [0,0,0]

    hasDir, hasCol = false,false

    Read!(tokens, DIRECTIONAL_LIGHT)
    Read!(tokens, LBRACE)

    # Enter parse loop until error or finish
    while true
        t = Peek(tokens)
        if t.kind == DIRECTION
            if hasDir
               error("Repeated direction attribute in directional light") 
            end
            direction = parseVec3dExpression(tokens)
            hasDir = true
        elseif t.kind == COLOR
            if hasCol
                error("Repeated color attribute in directional light")
            end
            color = parseVec3dExpression(tokens)
            hasCol = true
        elseif t.kind == RBRACE
            _ = Get!(tokens) #Consume the brace first, then decide what to do
            if(!hasCol)
                error("Attempted to get DirectionalLight without color")
            elseif(!hasDir)
                error("Attempted to get DirectionalLight without direction")
            else
                break
            end
        else
            error("Unexpected token in PointLight: " * string(t))
        end
    end
    return DirectionalLight(color,direction)
end

function parseAmbientLight(tokens::Vector{Token})::AmbientLight
    _ = Read!(tokens,AMBIENT_LIGHT)
    _ = Read!(tokens,LBRACE)
    if Peek(tokens).kind != COLOR
        error("Expected COLOR token in AmbientLight")
    end
    color = parseVec3dExpression(tokens)
    _ = Read!(tokens,RBRACE)

    return AmbientLight(color)
end

function parseMaterial()
    error("Not implemented")
end

function parseCamera(tokens::Vector{Token}, camera::Camera)
    hasViewDir, hasUpDir = false,false
    viewDir = Vector{Float64}([0,0,0])
    upDir = Vector{Float64}([0,0,0])

    Read!(tokens,CAMERA)
    Read!(tokens,LBRACE)

    # Loop in camera parsing until rbrace found
    while true
        t = Peek(tokens)
        q = @SVector zeros(4)
        if t.kind == POSITION
            pos = parseVec3dExpression(tokens)
            camera.eye = pos
        elseif t.kind == FOV
            fov = parseScalarExpression(tokens)
            #TODO: Set FOV of camera
        elseif t.kind == QUATERNIAN
            q = SVector{4,Float64}(parseVec4dExpression)
            #TODO: Set look from q
        elseif t.kind == ASPECTRATIO
            asp = parseScalarExpression(tokens)
            #TODO: Set aspect ratio from asp
        elseif t.kind == VIEWDIR
            viewDir = parseVec3dExpression(tokens)
            hasViewDir = true
        elseif t.kind == UPDIR
            upDir = parseVec3dExpression(tokens)
            hasUpDir = true
        elseif t.kind == RBRACE
            # Check to make sure we have both viewdir and updir
            if hasViewDir
                if !hasUpdir
                    error("Expected updir when parsing camera")
                end
            else
                if hasUpDir
                    error("Expected viewdir when parsing camera")
                end
            end
            _ = Read!(tokens, RBRACE)
            #TODO: Update camera internal parameters consistently
        else
            error("Encountered unexpected token while parsing camera: " *
              string(t)) 
        end

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

function parseVec4dExpression(tokens::Vector{Token})
    _ = Get!(tokens) # Eat the name--we don't really care
    _ = Read!(tokens, EQUALS)
    vec = parseVec4d(tokens)
    Read!(tokens, SEMICOLON)
    return vec
end

function parseVec4d(tokens::Vector{Token})
    _ = Read!(tokens, LPAREN)
    a = Get!(tokens).value
    _ = Read!(tokens, COMMA)
    b = Get!(tokens).value
    _ = Read!(tokens, COMMA)
    c = Get!(tokens).value
    _ = Read!(tokens, COMMA)
    d = Get!(tokens).value
    _ = Read!(tokens, RPAREN)

    return @SVector [a,b,c,d]
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

function parseBooleanExpression(tokens::Vector{Token})
    _ = Get!(tokens)
    _ = Read!(tokens, EQUALS)
    val = parseBoolean(tokens)
    _ = Read!(tokens, SEMICOLON)
    return val
end

function parseBoolean(tokens::Vector{Token})::Bool
    t = Get!(tokens)
    if t.kind == SYMTRUE
        return true
    elseif t.kind == SYMFALSE
        return false
    else
        error("Expected boolean token but got " * string(t))
    end
end

function parseIdentExpression(tokens::Vector{Token})::AbstractString
    _ = Get!(tokens)
    _ = Read!(tokens,EQUALS)
    val = parseIdent(tokens)
    _ = Read!(tokens, SEMICOLON)
end

function parseIdent(tokens)
    return Get!(tokens).ident
end
