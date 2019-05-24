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

"""Get the next token and check that it's of the expected type"""
function Read!(stream::Vector{Token}, tokt::TokType)::Token
    head = popfirst!(stream)
    if head isa SymbolToken && head.kind == tokt
        return head
    else
        error("Token was not of expected type: expected a " * string(tokt) * "
              but got a " * string(head.kind))
    end
end

"""If the token matches the type, read it and return True. Else don't read it
   and return False"""
function CondRead!(stream::Vector{Token}, tokt::TokType)::Token
    head = Peek(stream)
    if head isa SymbolToken && head.kind == tokt
        popfirst!(stream)
        return true
    else
        return false
    end
end



# Define a transformation stack as a set of 4x4 matrices
TMat = SMatrix{4,4}
TStack = Vector{TMat}
TInfo = Tuple{TStack, TMat}