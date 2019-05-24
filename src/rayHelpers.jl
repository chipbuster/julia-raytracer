module RayHelper

export SMat4, SMat3, MMat4, MMat3
export SVec4, SVec3, MVec4, MVec3

using StaticArrays
using LinearAlgebra
#= Helper functions and types useful across the raytracer =#

###########################
## Convienience Typedefs ##
###########################

# Unfortunately, the nature of macros means that we cannot define macros on
# these types, e.g. @SMat4 will never be a valid macro for construction

# Matrix typedefs
SMat4 = SMatrix{4,4,Float64}
SMat3 = SMatrix{3,3,Float64}
MMat4 = MMatrix{4,4,Float64}
MMat3 = MMatrix{3,3,Float64}

# Vector typedefs
SVec4 = SVector{4,Float64}
SVec3 = SVector{3,Float64}
SVec2 = SVector{2,Float64}
MVec4 = SVector{4,Float64}
MVec3 = SVector{3,Float64}
MVec2 = SVector{2,Float64}

###############################
### Homegrown GLM Functions ###
###############################

#= A surprising number of GLM functions are available in Julia's Base module.
e.g. glm::clamp, as well as dot/cross products.
However, things like rotation construction or more complex quaternion operations
do not yet exist. We implement those missing functions as helpers here. =#

"""Create a projective matrix which translates the points by w"""
function glmTranslate(w::SVec3)
    return @SMatrix [
        0 0 0 w[1];
        0 0 0 w[2];
        0 0 0 w[3];
        0 0 0 1.;
    ])
end

"""Create a projective matrix which rotates points by w rads around the axis"""
function glmRotate(w::Float64, axis::SVec3)
    # Thanks to Wikipedia for the immediate formula
    # https://en.wikipedia.org/wiki/Rotation_matrix#Conversion_from_and_to_axis%E2%80%93angle
    x,y,z = normalize(axis)
    cw = cos(w)
    sw = sin(w)
    return @SMatrix [
        cw+x^2*(1-cw)     x*y*(1-cw)-z*sw      x*z*(1-cw)+y*sw    0;
        y*x*(1-cw)+z*sw   cw+y^2*(1-cw)        y*z*(1-cw)-x*sw    0;
        z*x*(1-cw)-y*sw   z*y*(1-cw)+x*sw      cw+z^2*(1-cw)      0;
        0                 0                    0                  1;
    ]
end

"""Create a projective matrix which scales the space by the specified vector"""
function glmScale(axis::SVec3)
    x,y,z = axis
    return @SMatrix [
        x 0 0 0;
        0 y 0 0;
        0 0 z 0;
        0 0 0 1.;
    ]
end

end