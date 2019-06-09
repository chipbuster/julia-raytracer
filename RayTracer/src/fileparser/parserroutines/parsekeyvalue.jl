# Functions for parsing expressions of the form `key = val`

function parseScalarExpression(tokens::Vector{Token})
    _ = Get!(tokens) # Throw out first token, which precedes the = sign
    _ = Read!(tokens, EQUALS)
    val = parseScalar(tokens)
    _ = Read!(tokens, SEMICOLON)
    return val
end

function parseVec3dExpression(tokens::Vector{Token})
    _ = Get!(tokens)
    _ = Read!(tokens, EQUALS)
    vec = parseVec3d(tokens)
    Read!(tokens, SEMICOLON)
    return vec
end

function parseVec4dExpression(tokens::Vector{Token})
    _ = Get!(tokens) # Eat the name--we don't really care
    _ = Read!(tokens, EQUALS)
    vec = parseVec4d(tokens)
    Read!(tokens, SEMICOLON)
    return vec
end

function parseBooleanExpression(tokens::Vector{Token})
    _ = Get!(tokens)
    _ = Read!(tokens, EQUALS)
    val = parseBoolean(tokens)
    _ = Read!(tokens, SEMICOLON)
    return val
end

function parseIdentExpression(tokens::Vector{Token})
    _ = Get!(tokens)
    _ = Read!(tokens,EQUALS)
    val = parseIdent(tokens)
    _ = Read!(tokens, SEMICOLON)
    return val
end