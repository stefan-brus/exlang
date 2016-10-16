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
 * Annotated equals expression
 */

class AnnEqualsExpression : AnnExpression
{
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
     *      left = The left expression
     *      right = The right expression
     */

    this ( AnnExpression left, AnnExpression right )
    {
        import exlang.symtab.env;

        super(cast(Type)Env.global["Bool"]);

        this.left = left;
        this.right = right;
    }
}

/**
 * Annotated addition expression
 */

class AnnAddExpression : AnnExpression
{
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

/**
 * Annotated character literal expression
 */

class AnnCharLitExpression : AnnExpression
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
        import exlang.symtab.env;

        super(cast(Type)Env.global["Char"]);

        this.value = value;
    }
}

/**
 * Annotated list expression
 */

class AnnListExpression : AnnExpression
{
    /**
     * The expressions of the list
     */

    AnnExpression[] exps;

    /**
     * Constructor
     *
     * Params:
     *      type = The type contained in the list
     *      exps = The expressions of the list
     */

    this ( Type type, AnnExpression[] exps )
    {
        import exlang.symtab.env;

        auto list_type = "[" ~ type.ident ~ "]";
        super(cast(ArrayType)Env.global.getOrCreate(list_type, new ArrayType(cast(Type)Env.global[type.ident])));

        this.exps = exps;
    }
}
