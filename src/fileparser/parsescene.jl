include("../sceneObjects.jl")

module RayParse

using StaticArrays
using LinearAlgebra

using DataStructures: Stack
using Main.RayHelper
using Main.SceneObjects

include("tokenize.jl")
using .RayLex
using ..SceneObjects

# Import the TokType enum values so we can use them to parse...

import .RayLex: UNKNOWN,EOFSYM,SBT_RAYTRACER,SYMTRUE,SYMFALSE,LPAREN,RPAREN,
   LBRACE,RBRACE,COMMA,EQUALS,SEMICOLON,CAMERA,POINT_LIGHT,DIRECTIONAL_LIGHT,
   AMBIENT_LIGHT,AREA_LIGHT,CONSTANT_ATTENUATION_COEFF,LINEAR_ATTENUATION_COEFF,
   QUADRATIC_ATTENUATION_COEFF,LIGHT_RADIUS,SPHERE,BOX,SQUARE,CYLINDER,CONE,
   TRIMESH,POSITION,VIEWDIR,UPDIR,ASPECTRATIO,FOV,COLOR,DIRECTION,CAPPED,HEIGHT,
   BOTTOM_RADIUS,TOP_RADIUS,QUATERNION,POLYPOINTS,NORMALS,MATERIALS,FACES,
   GENNORMALS,TRANSLATE,SCALE,ROTATE,TRANSFORM,MATERIAL,EMISSIVE,AMBIENT,
   SPECULAR,REFLECTIVE,DIFFUSE,TRANSMISSIVE,SHININESS,INDEX,NAME,MAP

#=
Notes about parsing: A lot of the functions have been broken into smaller
files and scattered throughout the assembling directory because I hate dealing
with 2k+ line files.

While the functions in parsegeneral are correctly named, most functions in the
parsing code are not. Nearly every single function takes a stream (Vector) of
tokens and consumes part of it, returning some additional set of sceneObjects to
be added into the scene. Because of this, in principle every single parsing 
function should have a ! in the name, but I named *all* of these things before
realizing.

Not having class methods is pretty annoying for translating code, though it's
honestly not that much worse doing it procedurally. One spot in which we differ
massively from the C++ implementation is in how transformations are tracked: in
C++, it's easier to create a tree and DFS it, but in Julia, we use a stack with
a cached transformation (see the TransformStack for details)
=#

# Keeps track of the transformations so far: the stack contains the individual
# transformations, while the transform caches the product of all transformations
# on the stack so far.

mutable struct TransformStack
    xform::SMat4
    stack::Stack{SMat4}
end

function pushTransform!(s::TransformStack, t::SMat4)
    s.xform = s.xform * t
    push!(s.stack, t)
end

function popTransform!(s::TransformStack)
    t = pop!(s)
    s.xform = s.xform * inv(t)  #Safe? Accumulating error?
end

TransformStack() = TransformStack(SMat4(I),
                    begin
    s = Stack{SMat4}()
    push!(s, SMat4(I))
    s
end)

include("parserroutines/parsegeneral.jl")
include("parserroutines/parseliterals.jl")
include("parserroutines/parsekeyvalue.jl")
include("parserroutines/parsematerials.jl")
include("parserroutines/parselight.jl")
include("parserroutines/parsetransform.jl")
include("parserroutines/parsegeometry.jl")
include("parserroutines/parsetoplevel.jl")

function parseScene(tokens::Vector{Token})::Vector{SceneObject}
    Read!(tokens, RayLex.SBT_RAYTRACER)

    objs = Vector{SceneObject}()
    sTransStack = TransformStack() #Transformation stack of the scene
    mat = nothing::Union{Nothing,Material}
    camera = Camera(MMatrix{3,3}(Matrix{Float64}(I, 3, 3)), 1, 1,
                    @MVector(zeros(3)), @MVector(zeros(3)),
                    @MVector(zeros(3)), @MVector(zeros(3)))
    while !isempty(tokens)
        t = Peek(tokens)
        if t.kind in [SPHERE,BOX,SQUARE,CYLINDER,CONE,TRIMESH,TRANSLATE
                         ,ROTATE,SCALE,TRANSFORM,LBRACE]
            elems = parseTransformableElement(tokens, objs, sTransStack, mat)
        elseif t.kind == POINT_LIGHT
            push!(objs, parsePointLight(tokens))
        elseif t.kind == AREA_LIGHT
            push!(objs, parseAreaLight(tokens))
        elseif t.kind == DIRECTIONAL_LIGHT
            push!(objs, parseDirectionalLight(tokens))
        elseif t.kind == AMBIENT_LIGHT
            push!(objs, parseAmbientLight(tokens))
        elseif t.kind == CAMERA
            parseCamera!(tokens, camera) #parseCamera mutates camera in-place
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

end