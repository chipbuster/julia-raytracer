include("rayHelpers.jl")
module SceneObjects

export Material, ParamMaterial, MappedMaterial
export SceneObject, GeomObject, RealGeometry, OrgGeometry
export Box, Cone, Cylinder, Sphere, Square, Trimesh
export Light, DirectionalLight, PointLight, AmbientLight
export Camera

using StaticArrays
using ..RayHelper
import FileIO: load

#################
### Materials ###
#################

include("materials.jl")

#####################
### Scene Objects ###
#####################

abstract type SceneObject end

# Real Geometries: these are what get rendered by the raytracer, and
# organizations of such objects (e.g. kdtrees, bounding boxes)
abstract type GeomObject <: SceneObject end

abstract type RealGeometry <: GeomObject end # Geometries that can be rendered
abstract type OrgGeometry <: GeomObject end # Cannot be rendered

### Real Geometries

struct Box <: RealGeometry
    min::SVector{3,Float64}
    max::SVector{3,Float64}
    mat::Material
    transform::SMat4
end

# TODO: update to be inline with main parser
struct Cone <: RealGeometry
    center::SVector{3,Float64}
    dir::SVector{3,Float64}
    radius::Float64
    height::Float64
    mat::Material
    capped::Bool
    transform::SMat4
end

struct Cylinder <: RealGeometry
    cent1::SVector{3,Float64}  # Center of one face
    cent2::SVector{3,Float64}  # Center of other face
    radius::Float64
    mat::Material
    capped::Bool
    transform::SMat4
end

struct Sphere <: RealGeometry
    center::SVector{3,Float64}
    radius::Float64
    mat::Material
    transform::SMat4
end

struct Square <: RealGeometry
    center::SVector{3,Float64}
    normal::SVector{3,Float64}
    sidelength::Float64
    mat::Material
    transform::SMat4
end

struct Trimesh <: RealGeometry
    points::Matrix{Float64}
    normals::Matrix{Float64}
    edges::Vector{Tuple{Int64,Int64}}
    mat::Material
    transform::SMat4
end

# These are things that a director might change to get a better shot
# Included in these are things like lights, cameras, and skyboxen
abstract type InvisObject <: SceneObject end

# Lights! Very important to lighting a scene.
abstract type Light <: InvisObject end

struct PointLight <: Light
    color::SVector{3, Float64}
    position::SVector{3, Float64}
    attenCoeffs::NamedTuple{(:constant,:linear,:quadratic),
                 Tuple{Float64,Float64,Float64}}
end

struct DirectionalLight <: Light
    color::SVec3
    direction::SVec3
end

struct AmbientLight <: Light
    color::SVec3
end

# Cameras, used for specifying camera locations
mutable struct Camera <: InvisObject
    m::MMat3 # Rotation matrix for camera
    normalizedHeight::Float64
    aspectRatio::Float64

    eye::MVec3 # Eye of the camera (its the thrill of the fight)
    look::MVec3 # direction of looking
    u::MVec3
    v::MVec3
end

end