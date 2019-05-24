abstract type Material end
abstract type MaterialParameter end

struct TextureMap <: MaterialParameter
    filename::String
    width::Int
    height::Int
    data::Array{RGB{N0f8},2}
end

# Since we can get all the data from the image file, create an outer constructor
# which only requires the filename to populate all the fields
TextureMap(fname::String) = begin
    img = load(fname)
    w,h = size(img)
    TextureMap(fname, w, h, img)
end

struct VectorParameter <: MaterialParameter
    val::SVec3
end

# Currently, these next two functions will break because images are 
# not SVec3s but N0f8 (uint8 normalized to [0,1] by implicit division by 255)
# This will need to be fixed before these functions can be called
function getPixelAt(tmap::TextureMap, x, y)::SVec3
    xMod = clamp(x,0,tmap.width-1)
    yMod = clamp(y,0,tmap.height-1)

    tmap.data[yMod,xMod]
end

"""Assume that the input loc is a vector in [0,1] x [0,1]. Use bilinear interp
   to look up the pixed value on the texture."""
function getMappedValue(tmap::TextureMap, loc::SVec2)::SVec3
    xRaw, yRaw = loc
    @assert (0 <= xRaw <= 1 && 0 <= yRaw <= 1)
    xScaled = xRaw * (tmap.width - 1)
    yScaled = yRaw * (tmap.height - 1)

    i = floor(Int,xScaled)
    j = floor(Int,yScaled)

    x = xScaled - floor(xScaled)
    y = yScaled - floor(yScaled)

    @assert (0 <= x <= 1 && 0 <= y <= 1)
    @assert (abs(x + i - xScaled) <= 1e-4)
    @assert (abs(y + j - yScaled) <= 1e-4)

    ul = getPixelAt(tmap,i,j)
    ur = getPixelAt(tmap,i,j)
    ll = getPixelAt(tmap,i,j)
    lr = getPixelAt(tmap,i,j)

    u_interp = (1-x) * ul + x * ur
    l_interp = (1-x) * ll + x * lr
    m_interp = (1-y) * u_interp + y * l_interp

    m_interp
end

function getMappedValue(tmap::VectorParameter, loc::SVec2)::SVec3

end

# Material properties determined by parameters
struct ParamMaterial <: Material
    k_e::SVector{3,Float64}   # Emissivity
    k_a::SVector{3,Float64}   # Ambient
    k_s::SVector{3,Float64}   # Specular
    k_d::SVector{3,Float64}   # Diffuse (Lambertian)
    k_r::SVector{3,Float64}   # Reflective
    k_t::SVector{3,Float64}   # Transmissive
    shiny::SVector{3,Float64} # Shininess
    refl::Bool                # Specular reflector?
    trans::Bool               # Specular transmissive?
    spec::Bool                # Is specular?
    index::Float64            # Index of refraction
end

# Material properties determined by texture mapping
struct MappedMaterial <: Material
    tmap::TextureMap
end
MappedMaterial(fname::String) = MappedMaterial(TextureMap(fname))

