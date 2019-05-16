include("tokenize.jl")
include("../sceneObjects.jl")

using StaticArrays
using LinearAlgebra

include("parserroutines/parsegeneral.jl")
include("parserroutines/parseliterals.jl")
include("parserroutines/parsekeyvalue.jl")
include("parserroutines/parsematerials.jl")
include("parserroutines/parselight.jl")
include("parserroutines/parsetransform.jl")
include("parserroutines/parsegeometry.jl")
include("parserroutines/parsetoplevel.jl")

function parseScene(tokens::Vector{Token})::Vector{SceneObject}
    Read!(tokens,SBT_RAYTRACER)

    objs = Vector{SceneObject}()
    scenetrans = SMatrix{3,3}(Matrix{Float64}(I,3,3)) #Used to track transformation of the element
    mat = nothing::Union{Nothing, Material}
    camera = Camera(MMatrix{3,3}(Matrix{Float64}(I,3,3)), 1, 1,
                    @MVector(zeros(3)), @MVector(zeros(3)),
                    @MVector(zeros(3)), @MVector(zeros(3)))
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