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

end