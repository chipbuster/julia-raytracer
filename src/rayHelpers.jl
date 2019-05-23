module RayHelper

export SMat4, SMat3, MMat4, MMat3
export SVec4, SVec3, MVec4, MVec3

using StaticArrays
using LinearAlgebra
#= Helper functions and types useful across the raytracer =#

# Matrix typedefs
SMat4 = SMatrix{4,4,Float64}
SMat3 = SMatrix{3,3,Float64}
MMat4 = MMatrix{4,4,Float64}
MMat3 = MMatrix{3,3,Float64}

# Vector typedefs
SVec4 = SVector{4,Float64}
SVec3 = SVector{3,Float64}
MVec4 = SVector{4,Float64}
MVec3 = SVector{3,Float64}

# GLM replacement functions
function glmTranslate(w::SVec3)
    return SMat4([
        0, 0, 0, w[1];
        0, 0, 0, w[2];
        0, 0, 0, w[3];
        0, 0, 0, 1
    ])
end

function glmRotate(w::Float64, inputAxis::SVec3)
    # Thanks to Wikipedia for the immediate formula
    # https://en.wikipedia.org/wiki/Rotation_matrix#Conversion_from_and_to_axis%E2%80%93angle
    axis = normalize(inputAxis)
    x,y,z = axis
    cw = cos(w)
    sw = sin(w)
    return @SMatrix [
        cw+x^2*(1-cw)     x*y*(1-cw)-z*sw      x*z*(1-cw)+y*sw    0;
        y*x*(1-cw)+z*sw   cw+y^2*(1-cw)        y*z*(1-cw)-x*sw    0;
        z*x*(1-cw)-y*sw   z*y*(1-cw)+x*sw      cw+z^2*(1-cw)       0;
        0                 0                    0                  1;
    ]
end

function glmScale(axis::SVec3)
    x,y,z = axis
    return @SMatrix [
        x 0 0 0
        0 y 0 0 
        0 0 z 0
        0 0 0 1
    ]
end

end