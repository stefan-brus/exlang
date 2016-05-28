/**
 * Exlang expressions
 */

module exlang.absyn.expression;

/**
 * Abstract expression class
 */

abstract class Expression
{

}

/**
 * Identifier expression
 */

class IdentExpression : Expression
{
    /**
     * The identifier
     */

    string ident;

    /**
     * Constructor
     *
     * Params:
     *      ident = The identifier
     */

    this ( string ident )
    {
        this.ident = ident;
    }

    /**
     * Convert to string
     *
     * Returns:
     *      The string representation of this expression
     */

    override string toString ( )
    {
        return this.ident;
    }
}

/**
 * Function call expression
 */

class CallExpression : Expression
{
    /**
     * The identifier
     */

    string ident;

    /**
     * The argument expressions
     */

    Expression[] arg_exps;

    /**
     * Constructor
     *
     * Params:
     *      ident = The identifier
     *      arg_exps = The argument expressions
     */

    this ( string ident, Expression[] arg_exps )
    {
        this.ident = ident;
        this.arg_exps = arg_exps;
    }

    /**
     * Convert to string
     *
     * Returns:
     *      The string representation of this expression
     */

    override string toString ( )
    {
        string result;

        result ~= this.ident;
        result ~= "(";

        foreach ( i, exp; this.arg_exps )
        {
            result ~= exp.toString();
            if ( i != this.arg_exps.length - 1 ) result ~= ", ";
        }

        result ~= ")";

        return result;
    }
}

/**
 * Addition expression
 */

class AddExpression : Expression
{
    /**
     * The left expression
     */

    Expression left;

    /**
     * The right expression
     */

    Expression right;

    /**
     * Constructor
     *
     * Params:
     *      left = The left expression
     *      right = The right expression
     */

    this ( Expression left, Expression right )
    {
        this.left = left;
        this.right = right;
    }

    /**
     * Convert to string
     *
     * Returns:
     *      The string representation of this expression
     */

    override string toString ( )
    {
        import std.format;

        return format("%s + %s", this.left, this.right);
    }
}

/**
 * Integer expression
 */

class IntExpression : Expression
{
    /**
     * The value
     */

    ulong value;

    /**
     * Constructor
     *
     * Params:
     *      value = The value
     */

    this ( ulong value )
    {
        this.value = value;
    }

    /**
     * Convert to string
     *
     * Returns:
     *      The string representation of this expression
     */

    override string toString ( )
    {
        import std.conv;

        return to!string(this.value);
    }
}

/**
 * Character liteeral expression
 */

class CharLitExpression : Expression
{
    /**
     * The value
     */

    char value;

    /**
     * Constructor
     *
     * Params:
     *      value = The value
     */

    this ( char value )
    {
        this.value = value;
    }

    /**
     * Convert to string
     *
     * Returns:
     *      The string representation of this expression
     */

    override string toString ( )
    {
        import std.conv;

        return to!string(this.value);
    }
}
