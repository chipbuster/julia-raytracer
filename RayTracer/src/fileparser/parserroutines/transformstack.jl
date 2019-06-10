"""
Keeps track of the transformations so far: `stack` contains the individual
transformations, while `xform` caches the product of all transformations
on the stack so far.
"""
mutable struct TransformStack
    xform::SMat4
    stack::Stack{SMat4}
end

function pushTransform!(s::TransformStack, t::SMat4)
    s.xform = s.xform * t
    push!(s.stack, t)
end

function popTransform!(s::TransformStack)
    t = pop!(s)
    s.xform = s.xform * inv(t)  #Safe? Accumulating error?
end

TransformStack() = TransformStack(SMat4(I),
                    begin
                        s = Stack{SMat4}()
                        push!(s, SMat4(I))
                        s
                    end
                   )
