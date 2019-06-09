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

function parseGroup(tokens::Vector{Token}, transform::TransformStack, mat::Material)
    newMat = nothing::Union{Nothing,Material}
    objs = Vector{SceneObject}()
    Read!(tokens,LBRACE)
    while true:
        t = Peek(tokens)
        if t.kind in [SPHERE,BOX,SQUARE,CYLINDER,CONE,TRIMESH,TRANSLATE,ROTATE,
                    SCALE,TRANSFORM, LBRACE]
            newobjs = parseTransformableElement(tokens, transform, mat == missing ? newMat : mat)
            append!(objs,newobjs)
        elseif t.kind == RBRACE
            Read!(tokens, RBRACE)
            return objs
        elseif t.kind == MATERIAL
            mat = parseMaterialExpression(tokens,mat)
        else
            error("Expected '}' or geometry, got " * string(tok))
        end
    end
end

function parseGeometry(tokens::Vector{Token}, transform::TransformStack, mat::Material)
    tok = Peek!(tokens)
    if !(tok isa SymbolToken)
        error("Expected a symbol token but got " * string(tok))
    end

    if tok.kind == SPHERE
        return parseSphere(tokens,transform,mat)
    elseif tok.kind == BOX
        return parseBox(tokens,transform,mat)
    elseif tok.kind == SQUARE
        return parseSquare(tokens,transform,mat)
    elseif tok.kind == CYLINDER
        return parseCylinder(tokens,transform,mat)
    elseif tok.kind == CONE
        return parseCone(tokens,transform,mat)
    elseif tok.kind == TRIMESH
        return parseTrimesh(tokens,transform,mat)
    elseif tok.kind == TRANSLATE
        return parseTranslate(tokens,transform,mat)
    elseif tok.kind == ROTATE
        return parseRotate(tokens,transform,mat)
    elseif tok.kind == SCALE
        return parseScale(tokens,transform,mat)
    elseif tok.kind == TRANSFORM
        return parseTransform(tokens,transform,mat)
    else
        error("Unrecognized geometry type.")
    end
end

