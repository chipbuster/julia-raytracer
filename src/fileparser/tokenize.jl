# The code responsible for tokenization of the raytracer scenes
# Tokenization borrowed from C++ code in UT CS 386G (Graphics)
# Input file format specification available at
# http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15864-s04/www/assignment4/format.html

import Base.IOStream

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

abstract type Token <: Any end

struct SymbolToken <: Token
    kind::TokType
end

struct IdentToken <: Token
    ident::AbstractString
end

struct NumericToken <: Token
    value::Float64
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

function scanprogram(fcontents::IOStream)::Vector{Token}
"""Scan program, generating a list of tokens for parsing"""
    tokenlist = Vector{Token}()
    current::Char = ' '

    T = SymbolToken(SBT_RAYTRACER)
    push!(tokenlist, T)
    while !eof(fcontents)
        skipWhitespace(fcontents)
        T = getToken(fcontents)
        push!(tokenlist,T)
    end
    return tokenlist
end


function getToken(fcontents::IOStream)::Token
    """Process the next token in the filestream"""
    if eof(fcontents)
        return SymbolToken(EOFSYM)
    end

    next = Char(Base.peek(fcontents))
    if isletter(next) || next == '_'
        getIdent(fcontents)
    elseif next == '"'
        return getQuotedIdent(fcontents)
    elseif isdigit(next) || next == '-' || next == '.'
        return getScalar(fcontents)
    else
        return getPunctuation(fcontents)
    end
end

function getIdent(fcontents::IOStream)::Token
"""Read either an identifier or a reserved word token"""
    s = ""
    while !eof(fcontents)
        c = Char(Base.peek(fcontents))
        if (isletter(c) || isdigit(c) || c == '_' || c == '-')
            read(fcontents,Char)
            s *= c
        else
            break
        end
    end

    # Which token type to use?
    if s in keys(reservedWords)
        SymbolToken(reservedWords[s])
    else
        IdentToken(s)
    end
end

function getQuotedIdent(fcontents::IOStream)::Token
"""Read either an identifier or a reserved word token"""
    s = ""
    while !eof(fcontents)
        c = read(fcontents,Char)
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
        SymbolToken(reservedWords[s])
    else
        IdentToken(s)
    end
end

function getScalar(fcontents::IOStream)::NumericToken
    s = ""
    while true
        c = Char(Base.peek(fcontents))
        if isdigit(c) || c == '-' || c == '.' || c == 'e'
            s *= c
            read(fcontents,Char)
        else
            break
        end
    end
    val = parse(Float64, s)

    NumericToken(val)
end

function getPunctuation(fcontents::IOStream)::SymbolToken
    c = read(fcontents,Char)
    if c == '('
        SymbolToken(LPAREN)
    elseif c == ')'
        SymbolToken(RPAREN)
    elseif c == '{'
        SymbolToken(LBRACE)
    elseif c == '}'
        SymbolToken(RBRACE)
    elseif c == ','
        SymbolToken(COMMA)
    elseif c == '='
        SymbolToken(EQUALS)
    elseif c == ';'
        SymbolToken(SEMICOLON)
    else
        error("Unexpected symbol in lex " * read(fcontents,String))
    end
end

function skipWhitespace(fcontents::IOStream)
"""Strip all leading whitespace from string, including comments"""
    while !eof(fcontents)
        c = Char(Base.peek(fcontents))
        if isspace(c)
            read(fcontents,Char)
        elseif c == '/' && Char(Base.peek(fcontents)) == '/'
            dropLineComment(fcontents)
        elseif c == '/' && Char(Base.peek(fcontents)) == '*'
            dropBlockComment(fcontents)
        else
            break
        end
    end
end

function dropLineComment(s::IOStream)
    c = read(s,Char)
    while !eof(s) && c != '\n'
        c = read(s,Char)
    end
end

function dropBlockComment(s::IOStream)
    c = read(s,Char)
    while !eof(s)
        if c == '*' && Char(Base.peek(s)) == '/'
            c = read(s,Char)
            break
        end
        c = read(s,Char)
    end
end
