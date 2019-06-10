# A literal
function parseMaterial(tokens::Vector{Token}, parent::Material)
    tok = Peek!(tokens)
    if tok isa IdentToken
        return tok.ident
    end

    Read!(tokens, LBRACE)
    reflective = false

    mat = deepcopy(parent)
    hasName = false
    while true
        tok = Peek(tokens)
        if isSymbolToken(tok)
            if tok.kind == EMISSIVE
                mat.k_e = parseVec3dMaterialParameter(tokens)
            elseif tok.kind == AMBIENT
                mat.k_a = parseVec3dMaterialParameter(tokens)
            elseif tok.kind == SPECULAR
                mat.k_s = parseVec3dMaterialParameter(tokens)
            elseif tok.kind == DIFFUSE
                mat.k_d = parseVec3dMaterialParameter(tokens)
            elseif tok.kind == REFLECTIVE
                mat.k_r = parseVec3dMaterialParameter(tokens)
                mat.refl = true
            elseif tok.kind == TRANSMISSIVE
                mat.k_t = parseVec3dMaterialParameter(tokens)
            elseif tok.kind == INDEX
                mat.index = parseVec3dMaterialParameter(tokens)
            elseif tok.kind == SHININESS
                mat.shiny = parseVec3dMaterialParameter(tokens)
            elseif tok.kind == NAME
                # This is a named material parameter--will store it later
                Read!(tokens, NAME)
                matName = Get!(tokens).ident
                Read!(tokens, SEMICOLON)
                hasName = true
            elseif tok.kind == RBRACE
                Read!(tokens,RBRACE)
                if namedMaterial
                    if !haskey(namedMaterials, matName)
                        namedMaterials[matName] = mat
                    else
                        throw(MethodError("Tried to redefine material " + matName))
                    end
                end
                return mat
            else
                throw(MethodError("Unexpected token in parseMaterial"))
            end
        else
            throw(MethodError("Expected symboltoken but got something else"))
        end
    end
end

# Key-values
function parseMaterialExpression(tokens::Vector{Token}, parent::Material)
    Read!(tokens, MATERIAL)
    Read!(tokens, EQUALS)
    mat = parseMaterial(tokens, parent)
    CondRead!(tokens, SEMICOLON)
    return mat
end

function parseVec3dMaterialParameter(tokens::Vector{Token})::MaterialParameter
    _ = Get!(tokens)
    Read!(tokens,EQUALS)
    if CondRead!(tokens,MAP)
        Read!(tokens, LPAREN)
        # May need to add basePath formalisms here
        filename = parseIdent(tokens)
        Read!(tokens, RPAREN)
        CondRead!(tokens, SEMICOLON)
        return MappedMaterial(filename)
    else
        value = parseVec3d(tokens)
        CondRead!(tokens, SEMICOLON)
        return FixedParameter(value)
    end
end

function parseScalarMaterialParameter(tokens::Vector{Token})::MaterialParameter
    _ = Get!(tokens)
    Read!(tokens, EQUALS)
    if isSymbolToken(Peek(tokens)) && Peek(tokens).kind == MAP
        Read!(tokens, MAP)
        Read!(tokens, LPAREN)
        fname = parseIdent(tokens)
        Read!(tokens,RPAREN)
        CondRead!(tokens, SEMICOLON)
        return MappedParameter(fname)
    else
        value = parseScalar(tokens)
        CondRead!(tokens, SEMICOLON)
        return FixedParameter(SVec3(value,value,value))
    end
end