function parseScalar(tokens::Vector{Token})::Float64
    # If this doesn't work, bad luck
    return Get!(tokens).value
end

function parseScalarList(tokens::Vector{Token})::Vector{Float64}
    parsedVals = Vector{Float64}()
    Read!(tokens, LPAREN)

    if !isa(Peek(tokens),SymbolToken) || next.kind != RPAREN
        push!(parseScalar(parsedVals))
        while true
            if isSymbolToken(Peek(tokens)) && next.kind != RPAREN
                break
            end

            Read!(tokens, COMMA)
            push!(parseScalar(parsedVals))
        end
    end

    Read!(tokens,RPAREN)
    return parsedVals
end

function parseVec3d(tokens::Vector{Token})
    _ = Read!(tokens, LPAREN)
    a = Get!(tokens).value
    _ = Read!(tokens, COMMA)
    b = Get!(tokens).value
    _ = Read!(tokens, COMMA)
    c = Get!(tokens).value
    _ = Read!(tokens, RPAREN)

    return @SVector [a,b,c]
end

function parseVec4d(tokens::Vector{Token})
    _ = Read!(tokens, LPAREN)
    a = Get!(tokens).value
    _ = Read!(tokens, COMMA)
    b = Get!(tokens).value
    _ = Read!(tokens, COMMA)
    c = Get!(tokens).value
    _ = Read!(tokens, COMMA)
    d = Get!(tokens).value
    _ = Read!(tokens, RPAREN)

    return @SVector [a,b,c,d]
end

function parseBoolean(tokens::Vector{Token})::Bool
    t = Get!(tokens)
    if t.kind == SYMTRUE
        return true
    elseif t.kind == SYMFALSE
        return false
    else
        error("Expected boolean token but got " * string(t))
    end
end

function parseIdent(tokens)
    return Get!(tokens).ident
end



