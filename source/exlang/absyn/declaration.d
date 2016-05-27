/**
 * Exlang declarations
 */

module exlang.absyn.declaration;

/**
 * Abstract declaration class
 */

abstract class Declaration
{
    /**
     * The identifier
     */

    string ident;

    /**
     * The type identifier
     */

    string type_id;

    /**
     * Constructor
     *
     * Params:
     *      ident = The identifier
     *      type_id = The type identifier
     */

    this ( string ident, string type_id )
    {
        this.ident = ident;
        this.type_id = type_id;
    }
}

/**
 * Function argument declaration
 */

class ArgDeclaration : Declaration
{
    /**
     * Constructor
     *
     * Params:
     *      ident = The identifier
     *      type_id = The type identifier
     */

    this ( string ident, string type_id )
    {
        super(ident, type_id);
    }

    /**
     * Convert to string
     *
     * Returns:
     *      The string representation of this declaration
     */

    override string toString ( )
    {
        import std.format;

        return format("%s : %s", this.ident, this.type_id);
    }
}

/**
 * Function declaration
 */

class FuncDeclaration : Declaration
{
    import exlang.absyn.statement;

    /**
     * The argument identifiers;
     */

    ArgDeclaration[] args;

    /**
     * The statement list
     */

    Statement[] statements;

    /**
     * Constructor:
     *
     * Params:
     *      ident = The identifier
     *      type_id = The type identifier
     *      args = The argument identifiers
     *      statements = The statement list
     */

    this ( string ident, string type_id, ArgDeclaration[] args, Statement[] statements )
    {
        super(ident, type_id);

        this.args = args;
        this.statements = statements;
    }

    /**
     * Convert to string
     *
     * Returns:
     *      The string representation of this declaration
     */

    override string toString ( )
    {
        import std.format;

        string result = format("def %s(", this.ident);

        foreach ( i, arg; this.args )
        {
            result ~= arg.toString();
            if ( i != this.args.length - 1 ) result ~= ", ";
        }

        result ~= format(") %s:\n", this.type_id);

        foreach ( i, stmt; this.statements )
        {
            result ~= stmt.toString();
            if ( i != this.statements.length - 1 ) result ~= "\n";
        }

        return result;
    }
}
