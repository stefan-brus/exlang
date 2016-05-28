/**
 * Exlang lexical tokens
 */

module exlang.parse.token;

/**
 * Possible token types
 */

enum TokType
{
    /**
     * Default token, invalid
     */

    Invalid,

    /**
     * Identifier - alpha/underscore followed by alpha/num/underscores
     */

    Identifier,

    /**
     * Number literals
     */

    IntLit,

    /**
     * Reserved symbols and operators
     */

    LParen,
    RParen,
    Comma,
    Colon,
    Semicolon,
    Equals,
    Plus,
    SingleQuote,
    Backslash,

    /**
     * Reserved words
     */

    Let,
    Def,
    Ret,

    /**
     * End of input
     */

    EOF
}

/**
 * Reserved symbol/operator string table
 */

enum TokType[string] RES_OPS = [
    "(": TokType.LParen,
    ")": TokType.RParen,
    ",": TokType.Comma,
    ":": TokType.Colon,
    ";": TokType.Semicolon,
    "=": TokType.Equals,
    "+": TokType.Plus,
    "'": TokType.SingleQuote,
    "\\": TokType.Backslash
];

/**
 * Reserved word string table
 */

enum TokType[string] RES_WORDS = [
    "let": TokType.Let,
    "def": TokType.Def,
    "ret": TokType.Ret
];

/**
 * Token struct, contains the type and string representation
 */

struct Token
{
    /**
     * The token type
     */

    TokType type;

    /**
     * The token string
     */

    string str;

    /**
     * Format this token to a readable string
     *
     * Returns:
     *      This token as a readable string
     */

    string toString ( )
    {
        import std.conv;
        import std.format;

        return format("%s: %s", to!string(this.type), this.str);
    }
}
