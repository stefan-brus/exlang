/**
 * Annotated expression
 */

module exlang.annotated.expression;

/**
 * Abstract annotated expression
 */

abstract class AnnExpression
{
    import exlang.symtab.symbol;

    /**
     * The type of this expression
     */

    Type type;

    /**
     * Constructor
     *
     * Params:
     *      type = The expression type
     */

    this ( Type type )
    {
        this.type = type;
    }
}

/**
 * Annotated identifier expression
 */

class AnnIdentExpression : AnnExpression
{
    import exlang.symtab.symbol;

    /**
     * The identifier
     */

    string ident;

    /**
     * Constructor
     *
     * Params:
     *      type = The expression type
     *      ident = The identifier
     */

    this ( Type type, string ident )
    {
        super(type);

        this.ident = ident;
    }
}

/**
 * Annotated function call expression
 */

class AnnCallExpression : AnnExpression
{
    import exlang.symtab.symbol;

    /**
     * The identifier
     */

    string ident;

    /**
     * The argument expressions
     */

    AnnExpression[] arg_exps;

    /**
     * Constructor
     *
     * Params:
     *      type = The expression type
     *      ident = The identifier
     *      arg_exps = The argument expressions
     */

    this ( Type type, string ident, AnnExpression[] arg_exps )
    {
        super(type);

        this.ident = ident;
        this.arg_exps = arg_exps;
    }
}

/**
 * Annotated addition expression
 */

class AnnAddExpression : AnnExpression
{
    import exlang.symtab.symbol;

    /**
     * The left expression
     */

    AnnExpression left;

    /**
     * The right expression
     */

    AnnExpression right;

    /**
     * Constructor
     *
     * Params:
     *      type = The expression type
     *      left = The left expression
     *      right = The right expression
     */

    this ( Type type, AnnExpression left, AnnExpression right )
    {
        super(type);

        this.left = left;
        this.right = right;
    }
}

/**
 * Annotated integer expression
 */

class AnnIntExpression : AnnExpression
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
        import exlang.symtab.env;

        super(cast(Type)Env.global["Int"]);

        this.value = value;
    }
}
