/**
 * Annotated declarations
 */

module exlang.annotated.declaration;

/**
 * Abstract annotated declaration
 */

abstract class AnnDeclaration
{
    import exlang.symtab.symbol;

    /**
     * The identifier
     */

    string ident;

    /**
     * The type identifier
     */

    Type type;

    /**
     * Constructor
     *
     * Params:
     *      ident = The identifier
     *      type = The type
     */

    this ( string ident, Type type )
    {
        this.ident = ident;
        this.type = type;
    }
}

/**
 * Annotated function argument declaration
 */

class AnnArgDeclaration : AnnDeclaration
{
    import exlang.symtab.symbol;

    /**
     * Constructor
     *
     * Params:
     *      ident = The identifier
     *      type = The type
     */

    this ( string ident, Type type )
    {
        super(ident, type);
    }
}

/**
 * Annotated function declaration
 */

class AnnFuncDeclaration : AnnDeclaration
{
    import exlang.annotated.statement;
    import exlang.symtab.symbol;

    /**
     * The argument identifiers;
     */

    AnnArgDeclaration[] args;

    /**
     * The statement list
     */

    AnnStatement[] statements;

    /**
     * Constructor:
     *
     * Params:
     *      ident = The identifier
     *      type_id = The type identifier
     *      args = The argument identifiers
     *      statements = The statement list
     */

    this ( string ident, Type type, AnnArgDeclaration[] args, AnnStatement[] statements )
    {
        super(ident, type);

        this.args = args;
        this.statements = statements;
    }
}
