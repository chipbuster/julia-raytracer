#= The code responsible for tokenization of the raytracer scenes
 Tokenization borrowed from C++ code in UT CS 386G (Graphics)
 Input file format specification available at
 http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15864-s04/www/assignment4/format.html

 Notable similarities: our token types, token names, and reservedWords list
 remain unchanged from the C++ version. The algorithm for scanning the program
 to lex tokens is also surprisingly similar, although it returns a Vector of 
 Tokens instead of lazily generating tokens on request.
 
 Notable differences: In Julia, we cannot subtype a concrete type. This means 
 that most of our types must be abstract, and leads to some implementations that 
 differ from the C++ code. In this file, our class hierarchy looks slightly
 different from what is used in the C++ code. We use a separate SymbolToken 
 type to represent the C++ base Token, while IdentToken and ScalarToken (in 
 this code, NumericToken) remain more-or-less in place.

 N.B. This relies on Base.peek() being specialized for IOStreams to run at 
 any appreciable speed. Implementing peek() via mark-read-reset causes the
 lexer to take quite a few minutes to complete its job.
=#

import Base.IOStream

module RayLex

export TokType
export Token, SymbolToken, IdentToken, NumericToken
export tokenizeProgram

# An enumeration of the nonparametrized tokens allowed within ray files
@enum TokType begin
    UNKNOWN
    EOFSYM
    SBT_RAYTRACER

    SYMTRUE
    SYMFALSE

    LPAREN
    RPAREN
    LBRACE
    RBRACE
    COMMA
    EQUALS
    SEMICOLON

    CAMERA       # Camera primitive
    POINT_LIGHT  # Lights
    DIRECTIONAL_LIGHT
    AMBIENT_LIGHT
    AREA_LIGHT

    CONSTANT_ATTENUATION_COEFF   # Terms affecting the intensity dropoff
    LINEAR_ATTENUATION_COEFF     # of point lights
    QUADRATIC_ATTENUATION_COEFF
    LIGHT_RADIUS

    SPHERE  # primitives
    BOX
    SQUARE
    CYLINDER
    CONE
    TRIMESH

    POSITION  # keywords affecting primitives
    VIEWDIR
    UPDIR
    ASPECTRATIO
    FOV
    COLOR
    DIRECTION
    CAPPED
    HEIGHT
    BOTTOM_RADIUS
    TOP_RADIUS
    QUATERNION  # FTFY

    POLYPOINTS   # keywords affecting polygons
    NORMALS
    MATERIALS
    FACES
    GENNORMALS

    TRANSLATE  # Transformations
    SCALE
    ROTATE
    TRANSFORM

    MATERIAL  # Material settings
    EMISSIVE
    AMBIENT
    SPECULAR
    REFLECTIVE
    DIFFUSE
    TRANSMISSIVE
    SHININESS
    INDEX
    NAME
    MAP
end

mutable struct FileLocInfo
    fname  :: AbstractString
    lineno :: Int
    colno  :: Int
end

"""
Lines start at 1, but columns start at zero because we always increment
the column counter before we let the user see the counter
"""
FileLocInfo(fname) = FileLocInfo(fname,1,0)

function recordNewLine(f::FileLocInfo)
    f.lineno += 1
    f.colno = 1
end

function copy(f::FileLocInfo)::FileLocInfo
    return FileLocInfo(f.fname, f.lineno, f.colno)
end

# In theory this shouldn't be needed...but I'm a little drunk and I keep mixing
# lines and columns here :(
recordChar(f::FileLocInfo) = f.colno += 1

struct Token{T}
    data::T
    floc::FileLocInfo
end

SymbolToken = Token{TokType}
IdentToken = Token{String}
NumericToken = Token{Float64}

isSymbolToken(a::Token{TokType}) = true
isSymbolToken(a::Token{T}) where {T} = false
isIdentToken(a::Token{String}) = true
isIdentToken(a::Token{T}) where {T} = false
isNumericToken(a::Token{Float64}) = true
isNumericToken(a::Token{T}) where {T} = false

# This is technically bad because you cannot generate an instance of FileLocInfo
# from a shown instance...but I doubt anyone will really want to do that.
function Base.show(io::IO, m::FileLocInfo)
    compact = get(io, :compact, false)

    if !compact
        print(io, "in file ", m.fname," on line ",m.lineno,", column ",m.colno)
    else
        print(io, m.fname, ":", m.lineno, ":" , m.colno)
    end
end

const tokenNames = Dict{TokType, String}(
    EOFSYM => "EOF",
    SBT_RAYTRACER => "SBT-raytracer",
    SYMTRUE => "true",
    SYMFALSE => "false",
    LPAREN => "Left paren",
    RPAREN => "Right paren",
    LBRACE => "Left brace",
    RBRACE => "Right brace",
    COMMA => "Comma",
    EQUALS => "Equals",
    SEMICOLON => "Semicolon",
    CAMERA => "camera",
    AMBIENT_LIGHT => "ambient_light",
    POINT_LIGHT => "point_light",
    DIRECTIONAL_LIGHT => "directional_light",
    AREA_LIGHT => "area_light",
    CONSTANT_ATTENUATION_COEFF => "constant_attenuation_coeff",
    LINEAR_ATTENUATION_COEFF => "linear_attenuation_coeff",
    QUADRATIC_ATTENUATION_COEFF => "quadratic_attenuation_coeff",
    LIGHT_RADIUS => "light_radius",
    SPHERE => "sphere",
    BOX => "box",
    SQUARE => "square",
    CYLINDER => "cylinder",
    CONE => "cone",
    TRIMESH => "trimesh",
    POSITION => "position",
    VIEWDIR => "viewdir",
    UPDIR => "updir",
    ASPECTRATIO => "aspectratio",
    COLOR => "color",
    DIRECTION => "direction",
    CAPPED => "capped",
    HEIGHT => "height",
    BOTTOM_RADIUS => "bottom_radius",
    TOP_RADIUS => "top_radius",
    QUATERNION => "quaternion",
    POLYPOINTS => "points",
    HEIGHT => "height",
    NORMALS => "normals",
    MATERIALS => "materials",
    FACES => "faces",
    TRANSLATE => "translate",
    SCALE => "scale",
    ROTATE => "rotate",
    TRANSFORM => "transform",
    MATERIAL => "material",
    EMISSIVE => "emissive",
    AMBIENT => "ambient",
    SPECULAR => "specular",
    REFLECTIVE => "reflective",
    DIFFUSE => "diffuse",
    TRANSMISSIVE => "transmissive",
    SHININESS => "shininess",
    INDEX => "index",
    NAME => "name",
    MAP => "map"
)

const reservedWords = Dict{String, TokType}(
    "ambient_light" => AMBIENT_LIGHT,
    "ambient" => AMBIENT,
    "area_light" => AREA_LIGHT,
    "aspectratio" => ASPECTRATIO,
    "bottom_radius" => BOTTOM_RADIUS,
    "box" => BOX,
    "camera" => CAMERA,
    "capped" => CAPPED,
    "color" => COLOR,
    "colour" => COLOR,
    "cone" => CONE,
    "constant_attenuation_coeff" =>
        CONSTANT_ATTENUATION_COEFF,
    "cylinder" => CYLINDER,
    "diffuse" => DIFFUSE,
    "direction" => DIRECTION,
    "directional_light" => DIRECTIONAL_LIGHT,
    "emissive" => EMISSIVE,
    "faces" => FACES,
    "false" => SYMFALSE,
    "fov" => FOV,
    "gennormals" => GENNORMALS,
    "height" => HEIGHT,
    "index" => INDEX,
    "linear_attenuation_coeff" => LINEAR_ATTENUATION_COEFF,
    "light_radius" => LIGHT_RADIUS,
    "material" => MATERIAL,
    "materials" => MATERIALS,
    "map" => MAP,
    "name" => NAME,
    "normals" => NORMALS,
    "point_light" => POINT_LIGHT,     "points" => POLYPOINTS,     "polymesh" => TRIMESH,
    "position" => POSITION,
    "quadratic_attenuation_coeff" =>
        QUADRATIC_ATTENUATION_COEFF,
    "quaternion" => QUATERNION,
    "reflective" => REFLECTIVE,
    "rotate" => ROTATE,
    "SBT-raytracer" => SBT_RAYTRACER,
    "scale" => SCALE,
    "shininess" => SHININESS,
    "specular" => SPECULAR,
    "sphere" => SPHERE,
    "square" => SQUARE,
    "top_radius" => TOP_RADIUS,
    "transform" => TRANSFORM,
    "translate" => TRANSLATE,
    "transmissive" => TRANSMISSIVE,
    "trimesh" => TRIMESH,
    "true" => SYMTRUE,
    "updir" => UPDIR,
    "viewdir" => VIEWDIR,
)

function tokenizeProgram(fcontents::IOStream, fname::AbstractString)::Vector{Token}
"""Scan program, generating a list of tokens for parsing"""
    tokenlist = Vector{Token}()
    current::Char = ' '

    # Generate our initial FileLocInfo
    flocinfo = FileLocInfo(fname)

    T = SymbolToken(SBT_RAYTRACER, copy(flocinfo))
    push!(tokenlist, T)
    recordNewLine(flocinfo)

    while !eof(fcontents)
        skipWhitespace(fcontents, flocinfo)
        T = getToken(fcontents, flocinfo)
        push!(tokenlist,T)
    end
    return tokenlist
end


function getToken(fcontents::IOStream, flocinfo::FileLocInfo)::Token
    """Process the next token in the filestream"""
    if eof(fcontents)
        return SymbolToken(EOFSYM)
    end

    next = Char(Base.peek(fcontents))
    if isletter(next) || next == '_'
        getIdent(fcontents, flocinfo)
    elseif next == '"'
        return getQuotedIdent(fcontents, flocinfo)
    elseif isdigit(next) || next == '-' || next == '.'
        return getScalar(fcontents, flocinfo)
    else
        return getPunctuation(fcontents, flocinfo)
    end
end

function getIdent(fcontents::IOStream, flocinfo::FileLocInfo)::Token
"""Read either an identifier or a reserved word token"""
    s = ""
    while !eof(fcontents)
        c = Char(Base.peek(fcontents))
        if (isletter(c) || isdigit(c) || c == '_' || c == '-')
            read(fcontents,Char)
            recordChar(flocinfo)
            s *= c
        else
            break
        end
    end

    # Which token type to use?
    if s in keys(reservedWords)
        SymbolToken(reservedWords[s], copy(flocinfo))
    else
        IdentToken(s, copy(flocinfo))
    end
end

function getQuotedIdent(fcontents::IOStream, flocinfo::FileLocInfo)::Token
"""Read either an identifier or a reserved word token"""
    s = ""
    while !eof(fcontents)
        c = read(fcontents,Char)
        recordChar(flocinfo)
        if c == '\n'
            error("Unterminated string constant")
        elseif c == '"'
            break
        else
            s *= c
        end
    end

    # Which token type to use?
    if s in keys(reservedWords)
        SymbolToken(reservedWords[s], copy(flocinfo))
    else
        IdentToken(s, copy(flocinfo))
    end
end

function getScalar(fcontents::IOStream,flocinfo::FileLocInfo)::NumericToken
    s = ""
    while true
        c = Char(Base.peek(fcontents))
        if isdigit(c) || c == '-' || c == '.' || c == 'e'
            s *= c
            read(fcontents,Char)
            recordChar(flocinfo)
        else
            break
        end
    end
    val = parse(Float64, s)

    NumericToken(val, copy(flocinfo))
end

function getPunctuation(fcontents::IOStream, flocinfo::FileLocInfo)::SymbolToken
    c = read(fcontents,Char)
    recordChar(flocinfo)
    if c == '('
        SymbolToken(LPAREN, copy(flocinfo))
    elseif c == ')'
        SymbolToken(RPAREN, copy(flocinfo))
    elseif c == '{'
        SymbolToken(LBRACE, copy(flocinfo))
    elseif c == '}'
        SymbolToken(RBRACE, copy(flocinfo))
    elseif c == ','
        SymbolToken(COMMA, copy(flocinfo))
    elseif c == '='
        SymbolToken(EQUALS, copy(flocinfo))
    elseif c == ';'
        SymbolToken(SEMICOLON, copy(flocinfo))
    else
        error("Unexpected symbol in lex " * read(fcontents,String))
    end
end

"""Strip all leading whitespace from string, including comments."""
function skipWhitespace(fcontents::IOStream, flocinfo::FileLocInfo)
    while !eof(fcontents)
        c = Char(Base.peek(fcontents))
        if isspace(c)
            if c == '\n'
                print("cnline")
                recordNewLine(flocinfo)
            else
                recordChar(flocinfo)
            end
            read(fcontents,Char)
        elseif c == '/' && Char(Base.peek(fcontents)) == '/'
            dropLineComment(fcontents, flocinfo)
        elseif c == '/' && Char(Base.peek(fcontents)) == '*'
            dropBlockComment(fcontents, flocinfo)
        else
            break
        end
    end
end

function dropLineComment(s::IOStream, f::FileLocInfo)
    c = read(s,Char)
    recordChar(f)
    while !eof(s) && Char(c) != '\n'
        c = read(s,Char)
        recordChar(f)
    end
    if Char(c) == '\n' 
        recordNewLine(f)
    end
end

function dropBlockComment(s::IOStream, f::FileLocInfo)
    c = read(s,Char)
    recordChar(f)
    while !eof(s)
        if c == '\n'
            recordNewLine(f)
        elseif c == '*' && Char(Base.peek(s)) == '/'
            c = read(s,Char)
            recordChar(f)
            break
        end
        c = read(s,Char)
        recordChar(f)
    end
end

end