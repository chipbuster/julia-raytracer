# Functions for parsing geometry
# The general parseloop looks like this: parse the necessary information
# out of the sha

function parseSphere(tokens::Vector{Token}, trans::TransformStack, mat::Material)
    _ = Read!(SPHERE)
    _ = Read!(LBRACE)
    haveNewMat = false

    while true
        tok = Peek(tokens)
        if !isSymbolToken(tok)
            error("Expected a symbol token, but got " * string(tok))
        end

        if tok.kind == MATERIAL
            newMat = parseMaterialExpression(tokens, mat)
            haveNewMat = true
        elseif tok.kind == NAME
            _ = parseIdentExpression(tokens)
        elseif tok.kind == RBRACE
            _ = Read!(tokens, RBRACE)
            return Sphere(haveNewMat ? newMat : mat, trans.xform)
        else
            error("Expected a sphere attribute, but got " * string(tok))
        end
    end
end
function parseBox()
    _ = Read!(tokens, BOX)
    _ = Read!(tokens, LBRACE)

    while true
        tok = Peek(tokens)
        if !isSymbolToken(tok)
            error("Expected a symbol token, but got " * string(tok))
        end

        if tok.kind == MATERIAL
            newMat = parseMaterialExpression(tokens, mat)
            haveNewMat = true
        elseif tok.kind == NAME
            _ = parseIdentExpression(tokens)
        elseif tok.kind == RBRACE
            _ = Read!(tokens, RBRACE)
            return Box(haveNewMat ? newMat : mat, trans.xform)
        else
            error("Expected a Box attribute, but got " * str(tok))
        end
    end


end
function parseSquare()
    _ = Read!(tokens, SQUARE)
    _ = Read!(tokens, LBRACE)

    while true
        tok = Peek(tokens)
        if !(isSymbolToken(tok))
            error("Expected a symbol token, but got " * str(tok))
        end

        if tok.kind == MATERIAL
            newMat = parseMaterialExpression(tokens, mat)
            haveNewMat = true
        elseif tok.kind == NAME
            _ = parseIdentExpression(tokens)
        elseif tok.kind == RBRACE
            _ = Read!(tokens, RBRACE)
            return Square(haveNewMat ? newMat : mat, trans.xform)
        else
            error("Expected a Box attribute, but got " * str(tok))
        end
    end
end

function parseCylinder()
    _ = Read!(tokens, CYLINDER)
    _ = Read!(tokens, LBRACE)

    while true
        tok = Peek(tokens)
        if !isSymbolToken(tok)
            error("Expected a symbol token, but got " * str(tok))
        end

        if tok.kind == MATERIAL
            newMat = parseMaterialExpression(tokens, mat)
            haveNewMat = true
        elseif tok.kind == NAME
            _ = parseIdentExpression(tokens)
        elseif tok.kind == RBRACE
            _ = Read!(tokens, RBRACE)
            return Square(haveNewMat ? newMat : mat, trans.xform)
        else
            error("Expected a Box attribute, but got " * str(tok))
        end
    end

end
function parseCone()
    error("Not implemented")
end
function parseTrimesh()
    error("Not implemented")
end
function parseFaces()
    error("Not implemented")
end