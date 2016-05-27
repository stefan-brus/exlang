/**
 * Annotated statements
 */

module exlang.annotated.statement;

/**
 * Abstract annotated statement class
 */

abstract class AnnStatement
{

}

/**
 * Annotated let statement
 */

class AnnLetStatement : AnnStatement
{
    import exlang.annotated.expression;

    /**
     * The identifier
     */

    string ident;

    /**
     * The value expression
     */

    AnnExpression exp;

    /**
     * Constructor:
     *
     * Params:
     *      ident = The identifier
     *      exp = The expression
     */

    this ( string ident, AnnExpression exp )
    {
        this.ident = ident;
        this.exp = exp;
    }
}

/**
 * Annotated return statement
 */

class AnnRetStatement : AnnStatement
{
    import exlang.annotated.expression;

    /**
     * The expression
     */

    AnnExpression exp;

    /**
     * Constructor
     *
     * Params:
     *      exp = The expression
     */

    this ( AnnExpression exp )
    {
        this.exp = exp;
    }
}

/**
 * Annotated expression statement
 */

class AnnExpStatement : AnnStatement
{
    import exlang.annotated.expression;

    /**
     * The expression
     */

    AnnExpression exp;

    /**
     * Constructor:
     *
     * Params:
     *      exp = The expression
     */

    this ( AnnExpression exp )
    {
        this.exp = exp;
    }
}
