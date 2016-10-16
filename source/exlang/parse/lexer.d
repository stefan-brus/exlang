/**
 * Exlang lexical analysis
 */

module exlang.parse.lexer;

/**
 * Lexical analysis exception
 */

class LexerException : Exception
{
    /**
     * Constructor
     *
     * Params:
     *      msg = The message
     *      file = The file
     *      line = The line
     */

    this ( string msg, string file = __FILE__, uint line = __LINE__ )
    {
        super(msg, file, line);
    }
}

/**
 * Lexer class
 */

class Lexer
{
    import exlang.parse.token;

    /**
     * The string to go through
     */

    private string str;

    /**
     * The current position in the string
     */

    private size_t pos;

    invariant
    {
        assert(pos <= str.length);
    }

    /**
     * Constructor
     *
     * Params:
     *      str = The string to go through
     */

    this ( string str = null )
    {
        this.str = str;
    }

    /**
     * Reset the lexer with a new string
     *
     * Params:
     *      str = The string to go through
     */

    void reset ( string str )
    {
        this.str = str;
        this.pos = 0;
    }

    /**
     * Peek at the next token
     *
     * Params:
     *      consume = If true, consume whitespace and comments
     *
     * Returns:
     *      The next token
     *
     * Throws:
     *      LexerException on error
     */

    Token peekToken ( bool consume = true )
    {
        auto prev_pos = this.pos;
        scope ( exit ) this.pos = prev_pos;
        return this.popToken(consume);
    }

    /**
     * Consume the next token
     *
     * Params:
     *      consume = If true, consume whitespace and comments
     *
     * Returns:
     *      The next token
     *
     * Throws:
     *      LexerException on error
     */

    Token popToken ( bool consume = true )
    out ( tok )
    {
        debug ( LexerDebug )
        {
            import std.conv;
            import std.stdio;

            writefln("LEXER pos: %d type: %s str: %s", this.pos, to!string(tok.type), tok.str);
        }
    }
    body
    {
        while ( this.pos < this.str.length )
        {
            // Consume whitespace and comments
            if ( consume && (this.consumeWhitespace() || this.consumeComments()) )
            {
                continue;
            }
            // Parse whitespace as tokens
            else if ( !consume )
            {
                auto ws_tok = this.findWhitespace();
                if ( ws_tok !is null )
                {
                    assert(ws_tok in WS_TOKS);
                    this.pos += ws_tok.length;
                    return Token(WS_TOKS[ws_tok], ws_tok);
                }
            }

            // Look for reserved operators/symbols
            auto res_op = this.findResOp();
            if ( res_op !is null )
            {
                assert(res_op in RES_OPS);
                this.pos += res_op.length;
                return Token(RES_OPS[res_op], res_op);
            }

            // Look for reserved words
            auto res_word = this.findResWord();
            if ( res_word !is null )
            {
                assert(res_word in RES_WORDS);
                this.pos += res_word.length;
                return Token(RES_WORDS[res_word], res_word);
            }

            // Look for identifiers
            auto ident = this.findIdent();
            if ( ident !is null )
            {
                this.pos += ident.length;
                return Token(TokType.Identifier, ident);
            }

            // Look for integer literals
            auto int_lit = this.findIntLit();
            if ( int_lit !is null )
            {
                this.pos += int_lit.length;
                return Token(TokType.IntLit, int_lit);
            }

            auto other = this.findOther();
            if ( other !is null )
            {
                this.pos += other.length;
                return Token(TokType.Other, other);
            }

            // No valid token found, throw error
            throw new LexerException("No valid token found");
        }

        this.pos = this.str.length;
        return Token(TokType.EOF);
    }

    /**
     * Find the next whitespace tokens
     *
     * Returns:
     *      The string representation of the whitespace, or null
     */

    private string findWhitespace ( )
    in
    {
        assert(this.pos < this.str.length);
    }
    body
    {
        auto ws_str = this.str[this.pos .. this.pos + 1];
        if ( ws_str in WS_TOKS )
        {
            return ws_str;
        }

        return null;
    }

    /**
     * Find the next reserved operator/symbol
     *
     * Returns:
     *      The string representation of the operator, or null
     */

    private string findResOp ( )
    in
    {
        assert(this.pos < this.str.length);
    }
    body
    {
        auto op_str = this.str[this.pos .. this.pos + 1];
        if ( op_str in RES_OPS )
        {
            return op_str;
        }

        return null;
    }

    /**
     * Find the next reserved word
     *
     * Returns:
     *      The string representation of the word, or null
     */

    private string findResWord ( )
    in
    {
        assert(this.pos < this.str.length);
    }
    body
    {
        import util.array;

        enum MAX_LEN = RES_WORDS.keys.longestLength();
        enum MIN_LEN = 2;

        size_t search_len = MAX_LEN;

        while ( search_len >= MIN_LEN )
        {
            if ( this.pos + search_len <= this.str.length )
            {
                auto word_str = this.str[this.pos .. this.pos + search_len];
                if ( word_str in RES_WORDS )
                {
                    return word_str;
                }
            }

            search_len--;
        }

        return null;
    }

    /**
     * Find the next identifier
     *
     * Returns:
     *      The string representation of the identifier, or null
     */

    private string findIdent ( )
    in
    {
        assert(this.pos < this.str.length);
    }
    body
    {
        import std.ascii;

        if ( !isAlpha(this.str[this.pos]) || this.str[this.pos] == '_' )
        {
            return null;
        }

        auto ident_len = 1;

        while ( this.pos + ident_len <= this.str.length )
        {
            if ( !isAlphaNum(this.str[this.pos + ident_len]) &&
                 this.str[this.pos + ident_len] != '_' )
            {
                break;
            }

            ident_len++;
        }

        assert(this.pos + ident_len <= this.str.length);
        return this.str[this.pos .. this.pos + ident_len];
    }

    /**
     * Find the next integer literal
     *
     * Returns:
     *      The string representation of the int literal, or null
     */

    private string findIntLit ( )
    in
    {
        assert(this.pos < this.str.length);
    }
    body
    {
        import std.ascii;

        if ( !isDigit(this.str[this.pos]) ) return null;

        auto lit_len = 1;

        while ( this.pos + lit_len <= this.str.length )
        {
            if ( !isDigit(this.str[this.pos + lit_len]) ) break;

            lit_len++;
        }

        assert(this.pos + lit_len <= this.str.length);
        return this.str[this.pos .. this.pos + lit_len];
    }

    /**
     * Find an 'other' character
     *
     * Returns:
     *      The string representation of the character
     */

    private string findOther ( )
    in
    {
        assert(this.pos < this.str.length);
    }
    body
    {
        return this.str[this.pos .. this.pos + 1];
    }

    /**
     * Consume whitespace
     *
     * Returns:
     *      True if whitespace was consumed
     */

    private bool consumeWhitespace ( )
    in
    {
        assert(this.pos < this.str.length);
    }
    body
    {
        import std.ascii;

        if ( isWhite(this.str[this.pos]) )
        {
            this.pos++;
            return true;
        }

        return false;
    }

    /**
     * Consume comments
     *
     * Returns:
     *      True if a comment was consumed
     */

    private bool consumeComments ( )
    in
    {
        assert(this.pos < this.str.length);
    }
    body
    {
        import std.string;

        if ( this.pos < str.length - 1 && this.str[this.pos .. this.pos + 2] == "//" )
        {
            auto comment_end = this.str.indexOf('\n', this.pos);

            // No newline found, end of file has been reached
            if ( comment_end == -1 )
            {
                this.pos = this.str.length;
                return true;
            }
            else
            {
                this.pos = comment_end;
                return true;
            }
        }

        return false;
    }
}
