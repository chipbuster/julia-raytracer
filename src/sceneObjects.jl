using StaticArrays

#################
### Materials ###
#################

abstract type Material end

# Material properties determined by parameters
struct ParamMaterial <: Material
    k_e::SVector{3,Float64}   # Emissivity
    k_a::SVector{3,Float64}   # Ambient
    k_s::SVector{3,Float64}   # Specular
    k_d::SVector{3,Float64}   # Diffuse (Lambertian)
    k_r::SVector{3,Float64}   # Reflective
    k_t::SVector{3,Float64}   # Transmissive
    shiny::SVector{3,Float64} # Shininess
    refl::Bool             # Specular reflector?
    trans::Bool            # Specular transmissive?
    spec::Bool             # Is specular?
    index::Float64         # In
end

# Material properties determined by texture mapping
struct MappedMaterial <: Material
    tex::Matrix{UInt8}
    width::Int
    height::Int
    file::AbstractString
end

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
    transform::SMatrix{2,2,Float64}
end

# TODO: update to be inline with main parser
struct Cone <: RealGeometry
    center::SVector{3,Float64}
    dir::SVector{3,Float64}
    radius::Float64
    height::Float64
    mat::Material
    capped::Bool
    transform::SMatrix{2,2,Float64}
end

struct Cylinder <: RealGeometry
    cent1::SVector{3,Float64}  # Center of one face
    cent2::SVector{3,Float64}  # Center of other face
    radius::Float64
    mat::Material
    capped::Bool
    transform::SMatrix{2,2,Float64}
end

struct Sphere <: RealGeometry
    center::SVector{3,Float64}
    radius::Float64
    mat::Material
    transform::SMatrix{2,2,Float64}
end

struct Square <: RealGeometry
    center::SVector{3,Float64}
    normal::SVector{3,Float64}
    sidelength::Float64
    mat::Material
    transform::SMatrix{2,2,Float64}
end

struct Trimesh <: RealGeometry
    points::Matrix{Float64}
    normals::Matrix{Float64}
    edges::Vector{Tuple{Int64,Int64}}
    mat::Material
    transform::SMatrix{2,2,Float64}
end

# These are things that a director might change to get a better shot
# Included in these are things like lights, cameras, and skyboxen
abstract type InvisObject <: SceneObject end
