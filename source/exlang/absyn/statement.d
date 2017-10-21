/**
 * Exlang statements
 */

module exlang.absyn.statement;

/**
 * Abstract statement class
 */

abstract class Statement
{

}

/**
 * Let statement
 */

class LetStatement : Statement
{
    import exlang.absyn.expression;

    /**
     * The identifier
     */

    string ident;

    /**
     * The value expression
     */

    Expression exp;

    /**
     * Constructor:
     *
     * Params:
     *      ident = The identifier
     *      exp = The expression
     */

    this ( string ident, Expression exp )
    {
        this.ident = ident;
        this.exp = exp;
    }

    /**
     * Convert to string
     *
     * Returns:
     *      The string representation of this statement
     */

    override string toString ( )
    {
        import std.format;

        return format("let %s = %s;", this.ident, this.exp.toString());
    }
}

/**
 * Return statement
 */

class RetStatement : Statement
{
    import exlang.absyn.expression;

    /**
     * The expression
     */

    Expression exp;

    /**
     * Constructor
     *
     * Params:
     *      exp = The expression
     */

    this ( Expression exp )
    {
        this.exp = exp;
    }

    /**
     * Convert to string
     *
     * Returns:
     *      The string representation of this statement
     */

    override string toString ( )
    {
        import std.format;

        return format("ret %s;", this.exp.toString());
    }
}

/**
 * If statement
 */

class IfStatement : Statement
{
    import exlang.absyn.expression;

    /**
     * The condition
     */

    Expression cond;

    /**
     * The statement list
     */

    Statement[] stmts;

    /**
     * Optional elif clauses
     */

    struct ElifClause
    {
        /**
         * The condition
         */

        Expression cond;

        /**
         * The statement list
         */

        Statement[] stmts;
    }
    ///ditto
    ElifClause[] elifs;

    /**
     * Optional else clause
     */

    Statement[] else_stmts;

    /**
     * Constructor
     *
     * Params:
     *      cond = The condition
     *      stmts = The statements
     *      elifs = The else if clauses
     *      else_stmts = The optional else clause
     */

    this ( Expression cond, Statement[] stmts, ElifClause[] elifs, Statement[] else_stmts )
    {
        this.cond = cond;
        this.stmts = stmts;
        this.elifs = elifs;
        this.else_stmts = else_stmts;
    }

    /**
     * Convert to string
     *
     * Returns:
     *      The string representation of this statement
     */

    override string toString ( )
    {
        import std.format;

        string result;

        result ~= format("if %s:\n", this.cond);

        foreach ( stmt; this.stmts )
        {
            result ~= format("%s\n", stmt);
        }

        foreach ( elif; this.elifs )
        {
            result ~= format("elif %s:\n", elif.cond);

            foreach ( stmt; elif.stmts )
            {
                result ~= format("%s\n", stmt);
            }
        }

        if ( this.else_stmts.length > 0 )
        {
            result ~= format("else:\n");

            foreach ( stmt; this.else_stmts )
            {
                result ~= format("%s\n", stmt);
            }
        }

        result ~= format("end;");

        return result;
    }
}

/**
 * For statement
 */

class ForStatement : Statement
{
    import exlang.absyn.expression;

    /**
     * The iterator identifier
     */

    IdentExpression iter_ident;

    /**
     * The expression to iterate
     */

    Expression iter_exp;

    /**
     * The statements
     */

    Statement[] stmts;

    /**
     * Constructor
     *
     * Params:
     *      iter_ident = The iterator identifier
     *      iter_exp = The expression to iterate
     *      stmts = The statements
     */

    this ( IdentExpression iter_ident, Expression iter_exp, Statement[] stmts )
    {
        this.iter_ident = iter_ident;
        this.iter_exp = iter_exp;
        this.stmts = stmts;
    }

    /**
     * Convert to string
     *
     * Returns:
     *      The string representation of this statement
     */

    override string toString ( )
    {
        import std.format;

        string result;

        result ~= format("for %s in %s:\n", this.iter_ident, this.iter_exp);

        foreach ( stmt; this.stmts )
        {
            result ~= format("%s\n", stmt);
        }

        result ~= "end;\n";

        return result;
    }
}

/**
 * Expression statement
 */

class ExpStatement : Statement
{
    import exlang.absyn.expression;

    /**
     * The expression
     */

    Expression exp;

    /**
     * Constructor:
     *
     * Params:
     *      exp = The expression
     */

    this ( Expression exp )
    {
        this.exp = exp;
    }

    /**
     * Convert to string
     *
     * Returns:
     *      The string representation of this statement
     */

    override string toString ( )
    {
        import std.format;

        return format("%s;", this.exp.toString());
    }
}
