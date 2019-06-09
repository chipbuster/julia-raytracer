# Functions for parsing lights

function parsePointLight(tokens::Vector{Token})::PointLight
    position = @SVector [0,0,0]
    color = @SVector [0,0,0]

    constantAttenCoeff = 0.0
    linearAttenCoeff = 0.0
    quadAttenCoeff = 1.0

    hasPos, hasCol = false,false

    Read!(tokens, POINT_LIGHT)
    Read!(tokens, LBRACE)

    # Enter parse loop until error or finish
    while true
        t = Peek(tokens)
        if t.kind == POSITION
            if hasPos
               error("Repeated position attribute in point light") 
            end
            position = parseVec3dExpression(tokens)
            hasPos = true
        elseif t.kind == COLOR
            if hasCol
                error("Repeated color attribute in point light")
            end
            color = parseVec3dExpression(tokens)
            hasCol = true
        elseif t.kind == CONSTANT_ATTENUATION_COEFF
            constantAttenCoeff = parseScalarExpression(tokens)
        elseif t.kind == LINEAR_ATTENUATION_COEFF
            linearAttenCoeff = parseScalarExpression(tokens)
        elseif t.kind == QUADRATIC_ATTENUATION_COEFF
            quadAttenCoeff = parseScalarExpression(tokens)
        elseif t.kind == RBRACE
            _ = Get!(tokens) #Consume the brace first, then decide what to do
            if(!hasCol)
                error("Attempted to get PointLight without color")
            elseif(!hasPos)
                error("Attempted to get PointLight without position")
            else
                break
            end
        else
            error("Unexpected token in PointLight: " * string(t))
        end
    end
    return PointLight(color,position,
                      (constant = constantAttenCoeff,
                       linear = linearAttenCoeff,
                       quadratic = quadAttenCoeff))
end

# Final project implementation--ignore
function parseAreaLight()
    error("What are you calling this for, nerd?")
end

function parseDirectionalLight(tokens::Vector{Token})::DirectionalLight
    direction = @SVector [0,0,0]
    color = @SVector [0,0,0]

    hasDir, hasCol = false,false

    Read!(tokens, DIRECTIONAL_LIGHT)
    Read!(tokens, LBRACE)

    # Enter parse loop until error or finish
    while true
        t = Peek(tokens)
        if t.kind == DIRECTION
            if hasDir
               error("Repeated direction attribute in directional light") 
            end
            direction = parseVec3dExpression(tokens)
            hasDir = true
        elseif t.kind == COLOR
            if hasCol
                error("Repeated color attribute in directional light")
            end
            color = parseVec3dExpression(tokens)
            hasCol = true
        elseif t.kind == RBRACE
            _ = Get!(tokens) #Consume the brace first, then decide what to do
            if(!hasCol)
                error("Attempted to get DirectionalLight without color")
            elseif(!hasDir)
                error("Attempted to get DirectionalLight without direction")
            else
                break
            end
        else
            error("Unexpected token in PointLight: " * string(t))
        end
    end
    return DirectionalLight(color,direction)
end

function parseAmbientLight(tokens::Vector{Token})::AmbientLight
    _ = Read!(tokens,AMBIENT_LIGHT)
    _ = Read!(tokens,LBRACE)
    if Peek(tokens).kind != COLOR
        error("Expected COLOR token in AmbientLight")
    end
    color = parseVec3dExpression(tokens)
    _ = Read!(tokens,RBRACE)

    return AmbientLight(color)
end