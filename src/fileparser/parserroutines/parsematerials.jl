# A literal
function parseMaterial()
    error("Not implemented")
end

# Key-values
function parseMaterialExpression()
    error("Not implemented")
end

function parseVec3dMaterialParameter()
    error("Not implemented")
end

function parseScalarMaterialParameter(tokens::Vector{Token})::union{Material,SVec3}
    _ = Get!(tokens)
    Read!(tokens, EQUALS)
    if Peek(tokens) isa SymbolToken && Peek(tokens).kind == MAP
        Read!(tokens, MAP)
        Read!(tokens, LPAREN)
        fname = parseIdent(tokens)
        Read!(tokens,RPAREN)
        CondRead!(tokens, SEMICOLON)
        return MappedMaterial(fname)
    else
        value = parseScalar(tokens)
        CondRead!(tokens, SEMICOLON)
        return @SVector [value value value]
    end
end