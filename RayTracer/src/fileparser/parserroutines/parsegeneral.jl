## General parsing utilities for the token stream

# Define utility functions to abstract away vector-of-tokens
# We may need to change the internal representation (e.g. via reversing) later
"""Destructively read and return next token"""
function Get!(stream::Vector{T})::T where {T}
    return popfirst!(stream)
end

"""Non-destructively look at next token (it remains on stream)"""
function Peek(stream::Vector{T})::T where {T}
    return stream[1]
end

"""Consume a SymbolToken of the specified kind, destryoing it.

This function should only be called if it is "known" that the 
next token has this kind, as it will error otherwise."""
function Read!(stream::Vector{Token}, tokt::TokType)::Token
    head = popfirst!(stream)
    if tokIsKind(head, tokt)
        return head
    else
        error("Token was not of expected type: expected a " * string(tokt) * "
              but got a " * string(head.kind))
    end
end

"""Read a token only if it's a symbol token matching the specified
kind, otherwise leaving the stream untouched."""
function CondRead!(stream::Vector{Token}, tokt::TokType)::Token
    head = Peek(stream)
    if tokIsKind(head, tokt)
        popfirst!(stream)
        return true
    else
        return false
    end
end

"""Check to see if a token is a SymbolToken of the specified kind"""
function tokIsKind(tok::Token, tokt::TokType)::Bool
    tok isa SymbolToken && tok.kind == tokt
end



# Define a transformation stack as a set of 4x4 matrices
TMat = SMatrix{4,4}
TStack = Vector{TMat}
TInfo = Tuple{TStack, TMat}