# Function for parsing transformations

function parseTranslate(tokens::Vector{Token}, transform::TransformStack,
                        mat :: Material)::Vector{SceneObject}
    Read!(tokens, TRANSLATE)
    Read!(tokens, LPAREN)
    x = parseScalar(tokens)
    Read!(tokens,COMMA)
    y = parseScalar(tokens)
    Read!(tokens,COMMA)
    z = parseScalar(tokens)
    Read!(tokens,COMMA)

    thisTranslate = glmTranslate(SVec3(x,y,z))
    pushTransform!(transform, thisTranslate)
    objs = parseTransformableElement(tokens, transform, mat)
    popTransform!(transform)

    Read!(tokens,RPAREN)
    Read!(tokens,SEMICOLON)

    return objs
end

function parseRotate(tokens::Vector{Token}, transform::TransformStack,
                    mat::Material)::Vector{SceneObject}
    Read!(tokens, ROTATE)
    Read!(tokens, LPAREN)
    x = parseScalar(tokens)
    Read!(tokens, COMMA)
    y = parseScalar(tokens)
    Read!(tokens, COMMA)
    z = parseScalar(tokens)
    Read!(tokens, COMMA)
    w = parseScalar(tokens)
    Read!(tokens, COMMA)

    thisRotate = glmRotate(w,SVec3(x,y,z))
    pushTransform!(transform, thisRotate)
    objs = parseTransformableElement(tokens, transform, mat)
    popTransform!(transform)

    Read!(tokens,RPAREN)
    Read!(tokens,SEMICOLON)

    return objs
end

function parseScale(tokens::Vector{Token})::Vector{SceneObject}
    Read!(tokens, SCALE)
    Read!(tokens, LPAREN)
    x = parseScalar(tokens)
    Read!(tokens, COMMA)

    if Peek(tokens).kind == SCALAR
        y = parseScalar(tokens)
        Read!(tokens, COMMA)
        z = parseScalar(tokens)
        Read!(tokens, COMMA)
    else
        y = x
        z = x
    end

    thisScale = glmScale(SVec3(x,y,z))
    pushTransform!(transform, thisScale)
    objs = parseTransformableElement(tokens, transform, mat)
    popTransform!(transform)

    Read!(tokens,RPAREN)
    Read!(tokens,SEMICOLON)

    return objs
end

function parseTransform(tokens::Vector{Token})::Vector{SceneObject}
    Read!(tokens, TRANSFORM)
    Read!(tokens, LPAREN)

    row1 = parseVec4d(tokens)
    Read!(tokens,COMMA)
    row2 = parseVec4d(tokens)
    Read!(tokens,COMMA)
    row3 = parseVec4d(tokens)
    Read!(tokens,COMMA)
    row4 = parseVec4d(tokens)
    Read!(tokens,COMMA)

    tmat = transpose(SMat4([row1;row2;row3;row4]))

    pushTransform!(transform, tmat)
    objs = parseTransformableElement(tokens, transform, mat)
    popTransform!(transform)

    Read!(tokens,RPAREN)
    Read!(tokens,SEMICOLON)

    return objs
end