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

# More details on Geometry can be found at 
# https://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15864-s04/www/assignment4/format.html
# The gist is that most shapes have some "canonical" orientation and size, and 
# rely on the transform field to dictate what they actually look like.
#

"""
A unit cube (edgelength = 1) centered on the origin.
"""
struct Box <: RealGeometry
    mat::Material
    transform::SMat4
end

# Default transformation is identity, material must be speceified.
Box(mat; transform = SMat4(I)) = Box(mat, transform)

"""
A generalized cylinder (i.e. the circular faces can have different radiuses). 
The central axis is along the Z-axis and it runs from Z = 0 to Z = height.
Circular faces can be filled in or left missing (controlled by `capped`). This 
the only shape that's actually parameterized (for some reason).
"""
struct Cone <: RealGeometry
    height::Float64
    top_radius::Float64
    bot_radius::Float64
    mat::Material
    capped::Bool
    transform::SMat4
end

Cone(mat; height = 1.0, top_radius = 0.0, bot_radius = 1.0, capped = false,
          transform = SMat4(I)) = 
Cone(height, top_radius, bot_radius, mat, capped, transform)

"""
A cylinder of radius 1, with the longitudinal axis aligned with the Z-axis.
It runs from Z=0 to Z=1 and has a boolean to indicate if the circular faces exist.
"""
struct Cylinder <: RealGeometry
    mat::Material
    capped::Bool
    transform::SMat4
end

"""
A unit sphere (radius = 1) centered on the origin
"""
struct Sphere <: RealGeometry
    mat::Material
    transform::SMat4
end

"""
A unit square (edgelength = 1) at in the XY-plane. Centered at the origin.
"""
struct Square <: RealGeometry
    mat::Material
    transform::SMat4
end

"""
A structure which contains a triangular mesh. Specified by vertices (points
in R^3) and faces (tuples of indices)
"""
struct Trimesh <: RealGeometry
    vertices::Vector{SVec3}
    normals::Vector{SVec3}
    faces::Vector{Tuple{Int,Int,Int}}
    materials::Vector{Material}
    transform::SMat4
end

# These are things that a director might change to get a better shot
# Included in these are things like lights, cameras, and skyboxen
abstract type InvisObject <: SceneObject end

# Lights! Very important to lighting a scene.
abstract type Light <: InvisObject end

struct PointLight <: Light
    color::SVector{3,Float64}
    position::SVector{3,Float64}
    attenCoeffs::NamedTuple{(:constant, :linear, :quadratic),Tuple{Float64,Float64,Float64}}
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