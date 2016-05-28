/**
 * Exlang parser
 */

module exlang.parse.parser;

/**
 * Parse exception
 */

class ParseException : Exception
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
 * The exlang parser
 */

class Parser
{
    import exlang.absyn.declaration;
    import exlang.absyn.expression;
    import exlang.absyn.statement;
    import exlang.parse.lexer;
    import exlang.parse.token;

    /**
     * The lexer instance
     */

    private Lexer lexer;

    /**
     * Constructor
     */

    this ( )
    {
        this.lexer = new Lexer();
    }

    /**
     * Parse a string into a list of declarations
     *
     * Params:
     *      str = The string to parse
     *
     * Returns:
     *      The list of parsed declarations
     *
     * Throws:
     *      ParseException on parse error
     */

    Declaration[] parse ( string str )
    {
        Declaration[] result;

        this.lexer.reset(str);

        while ( this.lexer.peekToken().type != TokType.EOF )
        {
            result ~= this.parseDeclaration();
        }

        return result;
    }

    /**
     * Parse a declaration from the lexer
     *
     * Returns:
     *      The parsed declaration
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private Declaration parseDeclaration ( )
    out ( decl )
    {
        debug ( ParserDebug )
        {
            import std.stdio;

            writefln("PARSER DECLARATION ident: %s type: %s", decl.ident, decl.type_id);
        }
    }
    body
    {
        this.expect!(TokType.Def)();
        auto ident = this.expect!(TokType.Identifier)().str;
        this.expect!(TokType.LParen)();

        ArgDeclaration[] args;
        while ( this.lexer.peekToken().type != TokType.RParen )
        {
            auto arg_ident = this.expect!(TokType.Identifier)().str;
            this.expect!(TokType.Colon)();
            auto arg_type = this.expect!(TokType.Identifier)().str;
            args ~= new ArgDeclaration(arg_ident, arg_type);
            if ( this.lexer.peekToken().type != TokType.RParen ) this.expect!(TokType.Comma)();
        }

        this.expect!(TokType.RParen)();
        auto type_id = this.expect!(TokType.Identifier)().str;
        this.expect!(TokType.Colon)();

        Statement[] stmts;
        auto next_type = this.lexer.peekToken().type;
        while ( next_type != TokType.Def && next_type != TokType.EOF )
        {
            stmts ~= this.parseStatement();
            next_type = this.lexer.peekToken().type;
        }

        return new FuncDeclaration(ident, type_id, args, stmts);
    }

    /**
     * Parse a statement from the lexer
     *
     * All statements end with semi-colons, so that token is
     * expected by this method
     *
     * Returns:
     *      The parsed statement
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private Statement parseStatement ( )
    out ( stmt )
    {
        debug ( ParserDebug )
        {
            import std.stdio;

            writefln("PARSER STATEMENT");
        }
    }
    body
    {
        Statement result;

        switch ( this.lexer.peekToken().type )
        {
            case TokType.Let:
                result = this.parseLetStatement();
                break;

            case TokType.Ret:
                result = this.parseRetStatement();
                break;

            default:
                result = this.parseExpStatement();
        }

        this.expect!(TokType.Semicolon)();

        return result;
    }

    /**
     * Parse a let statement
     *
     * Returns:
     *      The parsed statement
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private LetStatement parseLetStatement ( )
    {
        this.expect!(TokType.Let)();
        auto ident = this.expect!(TokType.Identifier)().str;
        this.expect!(TokType.Equals)();
        auto exp = this.parseExpression();

        return new LetStatement(ident, exp);
    }

    /**
     * Parse a return statement
     *
     * Returns:
     *      The parsed statement
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private RetStatement parseRetStatement ( )
    {
        this.expect!(TokType.Ret)();
        auto exp = this.parseExpression();

        return new RetStatement(exp);
    }

    /**
     * Parse an expression statement
     *
     * Returns:
     *      The parsed statement
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private ExpStatement parseExpStatement ( )
    {
        auto exp = this.parseExpression();

        return new ExpStatement(exp);
    }

    /**
     * Parse an expression
     *
     * Params:
     *      left = The previously parsed expression, if any
     *
     * Returns:
     *      The parsed expression
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private Expression parseExpression ( Expression left = null )
    {
        import std.conv;
        import std.exception;
        import std.format;

        auto tok = this.lexer.popToken();
        auto next_type = this.lexer.peekToken().type;
        Expression result;

        with ( TokType ) switch ( tok.type )
        {
            case Identifier: switch ( next_type )
            {
                // Expression terminated
                case Comma:
                case RParen:
                case Semicolon:
                    return new IdentExpression(tok.str);

                // Function call
                case LParen:
                    return this.parseCallExpression(tok.str);

                // Binary expressions
                case Plus:
                    return this.parseExpression(new IdentExpression(tok.str));

                default:
                    throw new ParseException(format("Invalid token following Identifier: '%s' of type %s", tok.str, to!string(next_type)));
            }

            case IntLit: switch ( next_type )
            {
                case Semicolon:
                    return new IntExpression(to!ulong(tok.str));

                default:
                    throw new ParseException(format("Invalid token following IntLit: '%s' of type %s", tok.str, to!string(next_type)));
            }

            case SingleQuote:
                return this.parseCharLitExpression();

            case Plus:
                enforce!ParseException(left !is null, "Invalid token: Plus");
                return this.parseAddExpression(left);

            default:
                throw new ParseException(format("Invalid expression token '%s' of type %s", tok.str, to!string(next_type)));
        }
    }

    /**
     * Parse a call expression
     *
     * Params:
     *      ident = The identifier
     *
     * Returns:
     *      The parsed expression
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private CallExpression parseCallExpression ( string ident )
    {
        this.expect!(TokType.LParen)();

        Expression[] arg_exps;
        while ( this.lexer.peekToken().type != TokType.RParen )
        {
            arg_exps ~= this.parseExpression();
            if ( this.lexer.peekToken().type != TokType.RParen ) this.expect!(TokType.Comma)();
        }

        this.expect!(TokType.RParen)();

        return new CallExpression(ident, arg_exps);
    }

    /**
     * Parse an add expression
     *
     * Params:
     *      left = The left expression
     *
     * Returns:
     *      The parsed expression
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private AddExpression parseAddExpression ( Expression left )
    in
    {
        assert(left !is null);
    }
    body
    {
        auto right = this.parseExpression();

        return new AddExpression(left, right);
    }

    /**
     * Parse a character literal expression
     *
     * Returns:
     *      The parsed expression
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private CharLitExpression parseCharLitExpression ( )
    {
        import std.exception;
        import std.format;

        // This may seem a bit redundant but is necessary to escape things like letters
        enum ESCAPABLE_CHARACTERS = [
            '\'': '\'',
            '"': '\"',
            '\\': '\\',
            'n': '\n',
            'r': '\r',
            't': '\t',
            'b': '\b',
            'f': '\f',
            'v': '\v',
            '0': '\0'
        ];

        CharLitExpression result;

        auto tok1 = this.lexer.popToken();

        if ( tok1.type == TokType.Backslash )
        {
            auto tok2 = this.lexer.popToken();

            enforce!ParseException(tok2.str.length == 1, "Character literal expression must be 2 characters if escaped with backslash");
            enforce!ParseException(tok2.str[0] in ESCAPABLE_CHARACTERS, format("%s is not an escapable character", tok2.str));

            result = new CharLitExpression(ESCAPABLE_CHARACTERS[tok2.str[0]]);
        }
        else
        {
            enforce!ParseException(tok1.str.length == 1, "Character literal expression must be 1 character if not escaped with backslash");
            result = new CharLitExpression(tok1.str[0]);
        }

        this.expect!(TokType.SingleQuote)();

        return result;
    }

    /**
     * Expect a token of the given type
     *
     * Template_params:
     *      Type = The token type to expect
     *
     * Returns:
     *      The next token
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private Token expect ( TokType Type ) ( )
    {
        static assert(Type != TokType.Invalid);

        import std.conv;
        import std.format;

        if ( this.lexer.peekToken().type != Type )
        {
            throw new ParseException(format("Expected token of type: %s", to!string(Type)));
        }

        return this.lexer.popToken();
    }
}
