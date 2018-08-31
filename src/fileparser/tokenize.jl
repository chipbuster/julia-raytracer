# The code responsible for tokenization of the raytracer scenes
# Tokenization borrowed from C++ code in UT CS 386G (Graphics)
# Input file format specification available at
# http://www.cs.cmu.edu/afs/cs.cmu.edu/academic/class/15864-s04/www/assignment4/format.html

import Base.IOStream
import Base.Strings

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

function scanprogram(fcontents::AbstractString)::Vector{Token}
"""Scan program, generating a list of tokens for parsing"""
    tokenlist = Vector{Token}()
    current::Char = ' '

    T = SymbolToken(SBT_RAYTRACER)
    push!(tokenlist, T)
    while !isEOF(T)
        fcontents = skipWhitespace(fcontents)
        T,fcontents = getToken(fcontents)
        push!(tokenlist,T)
    end
    return tokenlist
end


function getToken(fcontents::AbstractString)::Tuple{Token,AbstractString}
    """Process the next token in the filestream"""
    if fcontents == ""
        return (SymbolToken(EOFSYM), fcontents)
    elseif isletter(fcontents[1]) || fcontents[1] == '_'
        getIdent(fcontents)
    elseif fcontents[1] == '"'
        return getQuotedIdent(fcontents)
    elseif isdigit(fcontents[1]) || fcontents[1] == '-' || fcontents[1] == '.'
        return getScalar(fcontents)
    else
        return getPunctuation(fcontents)
    end
end

function getIdent(fcontents::AbstractString)::Tuple{Token,AbstractString}
"""Read either an identifier or a reserved word token"""
    s = ""
    j = 1
    flength = length(fcontents)
    while j <= flength && (isletter(fcontents[j]) 
                                    || isdigit(fcontents[j]) 
                                    || fcontents[j] == '_' 
                                    || fcontents[j] == '-')
        s *= fcontents[j]
        j += 1
        flength -= 1
    end
    newcontents = fcontents[j+1:end]

    # Which token type to use?
    if s in keys(reservedWords)
        (SymbolToken(reservedWords[s]), newcontents)
    else
        (IdentToken(s), newcontents)
    end
end

function getQuotedIdent(fcontents::AbstractString)::Tuple{Token,AbstractString}
"""Read either an identifier or a reserved word token"""
    s = ""
    j = 2
    flength = length(fcontents)
    while j <= flength && fcontents[j] != '"'
        if fcontents[j] == '\n' error("Unterminated string constant") end
        s *= fcontents[j]
        j += 1
        flength -= 1
    end
    newcontents = fcontents[j+1:end]

    # Which token type to use?
    if s in keys(reservedWords)
        (SymbolToken(reservedWords[s]), newcontents)
    else
        (IdentToken(s), newcontents)
    end
end

function getScalar(fcontents::AbstractString)::Tuple{NumericToken,AbstractString}
    s = ""
    j = 1
    while isdigit(fcontents[j]) || fcontents[j] == '-' || fcontents[j] == '.' ||
          fcontents[j] == 'e'
        s *= fcontents[j]
        j += 1
    end
    newcontents = fcontents[j+1:end]
    val = parse(Float64, s)

    NumericToken(val), newcontents
end

function getPunctuation(fcontents::AbstractString)::Tuple{SymbolToken,AbstractString}
    if fcontents[1] == '('
        SymbolToken(LPAREN), fcontents[2:end]
    elseif fcontents[1] == ')'
        SymbolToken(RPAREN), fcontents[2:end]
    elseif fcontents[1] == '{'
        SymbolToken(LBRACE), fcontents[2:end]
    elseif fcontents[1] == '}'
        SymbolToken(RBRACE), fcontents[2:end]
    elseif fcontents[1] == ','
        SymbolToken(COMMA), fcontents[2:end]
    elseif fcontents[1] == '='
        SymbolToken(EQUALS), fcontents[2:end]
    elseif fcontents[1] == ';'
        SymbolToken(SEMICOLON), fcontents[2:end]
    else
        error("Unexpected symbol in lex " * fcontents[1:min(end,100)])
    end
end

function skipWhitespace(fcontents::AbstractString)
"""Strip all leading whitespace from string, including comments"""
    # Strip ordinary whitespace
    finishStrip = false
    while !finishStrip
        fcontents = lstrip(fcontents)

        # Early return candidates
        if length(fcontents) == 0 || length(fcontents) == 1
            return fcontents
        end

        if fcontents[1] == '/' && fcontents[2] == '/'
            fcontents = dropLineComment(fcontents)
        elseif fcontents[1] == '/' && fcontents[2] == '*'
            fcontents = dropBlockComment(fcontents)
        else
            finishStrip = true
        end
    end
    return fcontents
end

function dropLineComment(s::AbstractString)
    m = match(r"\n",s)
    s[m.offset+1:end]
end

function dropBlockComment(s::AbstractString)
    m = match(r"\*/",s)
    if m === nothing
        error("Unterminated Block Comment " * s[1:min(end,100)])
    end
    s[m.offset+2:end]
end

isEOF(T::Token) = isa(T,SymbolToken) && T.kind == EOFSYM
