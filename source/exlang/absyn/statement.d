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

class RetStatement: Statement
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
