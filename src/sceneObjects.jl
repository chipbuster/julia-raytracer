#################
### Materials ###
#################

abstract type Material end

# Material properties determined by parameters
struct ParamMaterial <: Material
    k_e::Vector{Float64}   # Emissivity
    k_a::Vector{Float64}   # Ambient
    k_s::Vector{Float64}   # Specular
    k_d::Vector{Float64}   # Diffuse (Lambertian)
    k_r::Vector{Float64}   # Reflective
    k_t::Vector{Float64}   # Transmissive
    shiny::Vector{Float64} # Shininess
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

# These are things that a director might change to get a better shot
# Included in these are things like lights, cameras, and skyboxen
abstract type InvisObject <: SceneObject end
