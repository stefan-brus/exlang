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
 * Annotated if statement
 */

class AnnIfStatement : AnnStatement
{
    import exlang.annotated.expression;

    /**
     * The condition
     */

    AnnExpression cond;

    /**
     * The statement list
     */

    AnnStatement[] stmts;

    /**
     * Optional elif clauses
     */

    struct AnnElifClause
    {
        /**
         * The condition
         */

        AnnExpression cond;

        /**
         * The statement list
         */

        AnnStatement[] stmts;
    }
    ///ditto
    AnnElifClause[] elifs;

    /**
     * Optional else clause
     */

    AnnStatement[] else_stmts;

    /**
     * Constructor
     *
     * Params:
     *      cond = The condition
     *      stmts = The statements
     *      elifs = The else if clauses
     *      else_stmts = The optional else clause
     */

    this ( AnnExpression cond, AnnStatement[] stmts, AnnElifClause[] elifs, AnnStatement[] else_stmts )
    {
        this.cond = cond;
        this.stmts = stmts;
        this.elifs = elifs;
        this.else_stmts = else_stmts;
    }
}

/**
 * Annotated for statement
 */

class AnnForStatement : AnnStatement
{
    import exlang.annotated.expression;

    /**
     * The iterator identifier
     */

    AnnIdentExpression iter_ident;

    /**
     * The expression to iterate
     */

    AnnExpression iter_exp;

    /**
     * The statements
     */

    AnnStatement[] stmts;

    /**
     * Constructor
     *
     * Params:
     *      iter_ident = The iterator identifier
     *      iter_exp = The expression to iterate
     *      stmts = The statements
     */

    this ( AnnIdentExpression iter_ident, AnnExpression iter_exp, AnnStatement[] stmts )
    {
        this.iter_ident = iter_ident;
        this.iter_exp = iter_exp;
        this.stmts = stmts;
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
