/**
 * Symbol definitions
 */

module exlang.symtab.symbol;

/**
 * Symbol base class
 */

abstract class Symbol
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
}

/**
 * Type symbol
 */

class Type : Symbol
{
    /**
     * Constructor
     *
     * Params:
     *      ident = The identifier
     */

    this ( string ident )
    {
        super(ident);
    }
}

/**
 * Variable symbol
 */

class Variable : Symbol
{
    import exlang.annotated.expression;

    /**
     * The variable type
     */

    Type type;

    /**
     * The expression that initializes this variable
     */

    AnnExpression exp;

    /**
     * Constructor
     *
     * Params:
     *      ident = The identifier
     *      type = The type
     *      exp = The expression
     */

    this ( string ident, Type type, AnnExpression exp )
    {
        super(ident);

        this.type = type;
        this.exp = exp;
    }
}

/**
 * Function symbol
 */

class Function : Symbol
{
    import exlang.annotated.declaration;

    /**
     * The function declaration
     */

    AnnFuncDeclaration decl;

    alias decl this;

    /**
     * Constructor
     *
     * Params:
     *      ident = The identifier
     *      decl = The declaration
     */

    this ( string ident, AnnFuncDeclaration decl )
    {
        super(ident);

        this.decl = decl;
    }
}
