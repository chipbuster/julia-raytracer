module Materials

# Datatypes used for images: RGB is a 3-vector describing RGB values
# N0f8 is a Normalized rational using 0 integer bits and 8 fractional bits
# (essentially an 8-bit uint normalized to [0,1])
using Images: RGB, N0f8
using ....RayHelper

export MaterialParameter, MappedParameter, FixedParameter, getMappedValue, Material

"""
Represents information about how a material reflects/absorbs/refracts light.

May be constant for a given material (a `FixedParameter`) or vary over the 
material based on some mapping (a `MappedParameter`)
"""
abstract type MaterialParameter end

"""A material parameter which varies over the material. Implicitly backed by image data."""
struct MappedParameter <: MaterialParameter
    filename::String
    width::Int
    height::Int
    data::Array{RGB{N0f8},2}
end

"""A material parameter which is constant over the material."""
struct FixedParameter <: MaterialParameter
    val::SVec3
end
# N.B.: Julia creates an implicit constructor which accepts an SVec3

"""Create a MappedParameter given the path to an image file which represents the map."""
MappedParameter(fname::String) = begin
    img = load(fname)
    w,h = size(img)
    MappedParameter(fname, w, h, img)
end

# Currently, these next two functions will break because images are 
# not SVec3s but N0f8 (uint8 normalized to [0,1] by implicit division by 255)
# This will need to be fixed before these functions can be called
function getPixelAt(tmap::MappedParameter, x, y)::SVec3
    xMod = clamp(x,0,tmap.width-1)
    yMod = clamp(y,0,tmap.height-1)

    tmap.data[yMod,xMod]
end

"""
Get the mapped value at a particular uv-coordinate.

Assume that the input loc is a vector in [0,1] x [0,1]. Use bilinear interp
to look up the pixed value on the texture."""
function getMappedValue(tmap::MappedParameter, loc::SVec2)::SVec3
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

# Easier version
function getMappedValue(tmap::FixedParameter, loc::SVec2)::SVec3
    return tmap.val
end

# Material properties determined by parameters
mutable struct Material
    k_e::MaterialParameter   # Emissivity
    k_a::MaterialParameter   # Ambient
    k_s::MaterialParameter   # Specular
    k_d::MaterialParameter   # Diffuse (Lambertian)
    k_r::MaterialParameter   # Reflective
    k_t::MaterialParameter   # Transmissive
    shiny::MaterialParameter # Shininess
    index::MaterialParameter # Index of refraction
    refl::Bool                # Specular reflector?
    trans::Bool               # Specular transmissive?
    spec::Bool                # Is specular?
end

# Define some convenience constructors
# Constructor for the matte black object
Material() = Material(
    FixedParameter(zeros(SVec3)),
    FixedParameter(zeros(SVec3)),
    FixedParameter(zeros(SVec3)),
    FixedParameter(zeros(SVec3)),
    FixedParameter(zeros(SVec3)),
    FixedParameter(zeros(SVec3)),
    FixedParameter(zeros(SVec3)),
    FixedParameter(ones(SVec3)),
    false, false, false
)

# Constructor for an object with specified parameter, shininess, and index
Material(e::SVec3, a::SVec3,s::SVec3,d::SVec3,r::SVec3,t::SVec3, sh::Float64, in::Float64) =
begin
    _refl = iszero(r)
    _trans = iszero(t)
    _spec = _refl || iszero(s)
    Material(FixedParameter(e),FixedParameter(a),FixedParameter(s),
        FixedParameter(d),FixedParameter(r),FixedParameter(t),
        SVec3(sh,sh,sh), SVec3(in,in,in), _refl, _trans, _spec)
end

end