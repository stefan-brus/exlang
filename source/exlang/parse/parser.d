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

            string arg_type;
            if ( this.lexer.peekToken().type == TokType.LBracket )
            {
                arg_type = this.parseListType();
            }
            else
            {
                arg_type = this.expect!(TokType.Identifier)().str;
            }

            args ~= new ArgDeclaration(arg_ident, arg_type);
            if ( this.lexer.peekToken().type != TokType.RParen ) this.expect!(TokType.Comma)();
        }

        this.expect!(TokType.RParen)();

        string type_id;
        if ( this.lexer.peekToken().type == TokType.LBracket )
        {
            type_id = this.parseListType();
        }
        else
        {
            type_id = this.expect!(TokType.Identifier)().str;
        }

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
     * Helper function to parse a list type
     *
     * Returns:
     *      The list type string
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private string parseListType ( )
    {
        import std.format;

        this.expect!(TokType.LBracket)();
        auto type_str = this.expect!(TokType.Identifier)().str;
        this.expect!(TokType.RBracket)();

        return format("[%s]", type_str);
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

            case TokType.If:
                result = this.parseIfStatement();
                break;

            case TokType.For:
                result = this.parseForStatement();
                break;

            default:
                result = this.parseExpStatement();
                break;
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
     * Parse an if statement
     *
     * Returns:
     *      The parsed statement
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private IfStatement parseIfStatement ( )
    {
        this.expect!(TokType.If)();
        auto cond = this.parseExpression();
        this.expect!(TokType.Colon)();

        Statement[] stmts;
        auto next_type = this.lexer.peekToken().type;
        while ( next_type != TokType.Elif && next_type != TokType.Else && next_type != TokType.End )
        {
            stmts ~= parseStatement();
            next_type = this.lexer.peekToken().type;
        }

        IfStatement.ElifClause[] elifs;
        while ( next_type == TokType.Elif )
        {
            this.expect!(TokType.Elif)();
            auto elif_cond = this.parseExpression();
            this.expect!(TokType.Colon)();

            Statement[] elif_stmts;
            next_type = this.lexer.peekToken().type;
            while ( next_type != TokType.Elif && next_type != TokType.Else && next_type != TokType.End )
            {
                elif_stmts ~= this.parseStatement();
                next_type = this.lexer.peekToken().type;
            }

            elifs ~= IfStatement.ElifClause(elif_cond, elif_stmts);
            next_type = this.lexer.peekToken().type;
        }

        Statement[] else_stmts;
        if ( next_type == TokType.Else )
        {
            this.expect!(TokType.Else)();
            this.expect!(TokType.Colon)();

            next_type = this.lexer.peekToken().type;
            while ( next_type != TokType.End )
            {
                else_stmts ~= this.parseStatement();
                next_type = this.lexer.peekToken().type;
            }
        }

        this.expect!(TokType.End)();

        return new IfStatement(cond, stmts, elifs, else_stmts);
    }

    /**
     * Parse a for statement
     *
     * Returns:
     *      The parsed statement
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private ForStatement parseForStatement ( )
    {
        this.expect!(TokType.For)();
        auto iter_ident = this.expect!(TokType.Identifier)().str;
        this.expect!(TokType.In)();
        auto iter_exp = this.parseExpression();
        this.expect!(TokType.Colon)();

        Statement[] stmts;

        while ( this.lexer.peekToken().type != TokType.End )
        {
            stmts ~= this.parseStatement();
        }

        this.expect!(TokType.End)();

        return new ForStatement(new IdentExpression(iter_ident), iter_exp, stmts);
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
        import exlang.parse.util;

        import std.conv;
        import std.exception;
        import std.format;

        auto tok = this.lexer.popToken();
        auto next = this.lexer.peekToken();
        Expression result;

        with ( TokType ) switch ( tok.type )
        {
            case Identifier: switch ( next.type )
                {
                    // Function call
                    case LParen:
                        result = this.parseCallExpression(tok.str);
                        break;

                    default:
                        result = new IdentExpression(tok.str);
                        break;
                }
                break;

            case IntLit:
                result = new IntExpression(to!ulong(tok.str));
                break;

            case SingleQuote:
                result = this.parseCharLitExpression();
                break;

            case Quote:
                result = this.parseStringLitExpression();
                break;

            case Equals:
                enforce!ParseException(left !is null, "Invalid token: Equals");
                switch ( next.type )
                {
                    case Equals:
                        result = this.parseEqualsExpression(left);
                        break;

                    default:
                        result = this.parseAssignExpression(left);
                }
                break;

            case Plus:
                enforce!ParseException(left !is null, "Invalid token: Plus");
                result = this.parseAddExpression(left);
                break;

            case Dash:
                enforce!ParseException(left !is null, "Invalid token: Dash");
                result = this.parseSubExpression(left);
                break;

            case Star:
                enforce!ParseException(left !is null, "Invalid token: Star");
                result = this.parseMulExpression(left);
                break;

            case Exclamation:
                result = this.parseNotExpression();
                break;

            case Tilde:
                enforce!ParseException(left !is null, "Invalid token: Tilde");
                result = this.parseAppendExpression(left);
                break;

            case LBracket:
                result = this.parseListExpression();
                break;

            default:
                throw new ParseException(format("Invalid expression token '%s' of type %s", tok.str, to!string(tok.type)));
        }

        // Continue parsing expression tree if the next token is a binary operator
        if ( isBinOp(this.lexer.peekToken().type) )
        {
            result = this.parseExpression(result);
        }

        return result;
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
     * Parse an equals expression
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

    private EqualsExpression parseEqualsExpression ( Expression left )
    {
        this.expect!(TokType.Equals)();

        auto right = this.parseExpression();

        return new EqualsExpression(left, right);
    }

    /**
     * Parse an assign expression
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

    private AssignExpression parseAssignExpression ( Expression left )
    in
    {
        assert(left !is null);
    }
    body
    {
        import std.exception;
        import std.format;

        enforce!ParseException(cast(IdentExpression)left !is null,
            format("Can only assign to identifiers, not: %s", left));

        auto exp = this.parseExpression();

        return new AssignExpression((cast(IdentExpression)left).ident, exp);
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
     * Parse a sub expression
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

    private SubExpression parseSubExpression ( Expression left )
    in
    {
        assert(left !is null);
    }
    body
    {
        auto right = this.parseExpression();

        return new SubExpression(left, right);
    }

    /**
     * Parse a mul expression
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

    private MulExpression parseMulExpression ( Expression left )
    in
    {
        assert(left !is null);
    }
    body
    {
        auto right = this.parseExpression();

        return new MulExpression(left, right);
    }

    /**
     * Parse a not expression
     *
     * Returns:
     *      The parsed expression
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private NotExpression parseNotExpression ( )
    {
        auto exp = this.parseExpression();

        return new NotExpression(exp);
    }

    /**
     * Parse an append expression
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

    private AppendExpression parseAppendExpression ( Expression left )
    in
    {
        assert(left !is null);
    }
    body
    {
        auto right = this.parseExpression();

        return new AppendExpression(left, right);
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

        auto tok1 = this.lexer.popToken(false);

        if ( tok1.type == TokType.Backslash )
        {
            auto tok2 = this.lexer.popToken(false);

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
     * Parse a string literal expression
     *
     * Returns:
     *      The parsed expression
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private ListExpression parseStringLitExpression ( )
    {
        string val_buf;
        while ( this.lexer.peekToken(false).type != TokType.Quote )
        {
            auto tok = this.lexer.popToken(false);
            val_buf ~= tok.str;
        }

        Expression[] exps;
        foreach ( c; val_buf )
        {
            exps ~= new CharLitExpression(c);
        }

        this.expect!(TokType.Quote);

        return new ListExpression(exps);
    }

    /**
     * Parse a list expression
     *
     * Returns:
     *      The parsed expression
     *
     * Throws:
     *      ParseException on unexpected token
     */

    private ListExpression parseListExpression ( )
    {
        Expression[] exps;
        while ( this.lexer.peekToken().type != TokType.RBracket )
        {
            exps ~= this.parseExpression();
            if ( this.lexer.peekToken().type != TokType.Comma ) break;
            this.lexer.popToken();
        }

        this.expect!(TokType.RBracket);

        return new ListExpression(exps);
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

        auto next_type = this.lexer.peekToken().type;
        if ( next_type != Type )
        {
            throw new ParseException(format("Expected token of type: %s, got: %s", to!string(Type), to!string(next_type)));
        }

        return this.lexer.popToken();
    }
}
