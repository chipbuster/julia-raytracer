# Top level parsing functions

function parseCamera!(tokens::Vector{Token}, camera::Camera)
    hasViewDir, hasUpDir = false,false
    viewDir = Vector{Float64}([0,0,0])
    upDir = Vector{Float64}([0,0,0])

    Read!(tokens,CAMERA)
    Read!(tokens,LBRACE)

    # Loop in camera parsing until rbrace found
    while true
        t = Peek(tokens)
        q = @SVector zeros(4)
        if t.kind == POSITION
            pos = parseVec3dExpression(tokens)
            camera.eye = pos
        elseif t.kind == FOV
            fov = parseScalarExpression(tokens)
            #TODO: Set FOV of camera
        elseif t.kind == QUATERNIAN
            q = SVector{4,Float64}(parseVec4dExpression)
            #TODO: Set look from q
        elseif t.kind == ASPECTRATIO
            asp = parseScalarExpression(tokens)
            #TODO: Set aspect ratio from asp
        elseif t.kind == VIEWDIR
            viewDir = parseVec3dExpression(tokens)
            hasViewDir = true
        elseif t.kind == UPDIR
            upDir = parseVec3dExpression(tokens)
            hasUpDir = true
        elseif t.kind == RBRACE
            # Check to make sure we have both viewdir and updir
            if hasViewDir
                if !hasUpdir
                    error("Expected updir when parsing camera")
                end
            else
                if hasUpDir
                    error("Expected viewdir when parsing camera")
                end
            end
            _ = Read!(tokens, RBRACE)
            #TODO: Update camera internal parameters consistently
        else
            error("Encountered unexpected token while parsing camera: " *
              string(t)) 
        end
    end
end

#TODO: update to allow correct pushing of multiple elements
function parseTransformableElement(tokens::Vector{Token}, transform::TransformStack,
                                   mat::Material)::Vector{SceneObject}
    t = Peek(tokens)
    if t.kind in [SPHERE,BOX,SQUARE,CYLINDER,CONE,TRIMESH,TRANSLATE,ROTATE,
                 SCALE,TRANSFORM]
        return parseGeometry(tokens,transform,mat)
    elseif t.kind == LBRACE
        return parseGroup(tokens,transform,mat)
    else
        error("Expected transformable element")
    end
end

function parseGroup(tokens::Vector{Token}, transform::TInfo, mat::Material)
    newMat = missing::Union{Missing,Material}
    Read!(tokens,LBRACE)
    t = Peek(tokens)
    if t.kind in [SPHERE,BOX,SQUARE,CYLINDER,CONE,TRIMESH,TRANSLATE,ROTATE,
                  SCALE,TRANSFORM, LBRACE]
        parseTransformableElement(tokens, transform, mat == missing ? newMat : mat)
    end
    if t.kind == RBRACE
        Read!(tokens, RBRACE)
    end

end

function parseGeometry()
    error("Not implemented")
end

