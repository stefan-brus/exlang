/**
 * An environment frame of the symbol table
 */

module exlang.symtab.env;

/**
 * Symbol table exception
 */

class SymtabException : Exception
{
    /**
     * Constructor
     *
     * Params:
     *      msg = The message
     *      file = The file
     *      line = The line
     */

    this ( string msg, string file = __FILE__, uint line = __LINE__ )
    {
        super(msg, file, line);
    }
}

/**
 * Environment frame class
 */

class Env
{
    import exlang.symtab.symbol;

    /**
     * A reference to the global environment
     */

    static private Env global_instance;

    /**
     * Parent environment, can be null if global scope
     */

    private Env parent;

    /**
     * The map of identifiers to their symbols
     */

    private Symbol[string] sym_map;

    /**
     * Constructor
     *
     * Params:
     *      parent = The parent frame
     */

    this ( Env parent )
    {
        this.parent = parent;
    }

    /**
     * Get the global scope instance
     *
     * Returns:
     *      The global environment scope
     */

    static Env global ( )
    {
        if ( global_instance is null )
        {
            global_instance = new Env(null);
        }

        return global_instance;
    }

    /**
     * Look up a symbol
     *
     * Params:
     *      ident = The identifier
     *
     * Returns:
     *      The symbol
     *
     * Throws:
     *      SymtabException if the identifier was not found
     */

    Symbol lookup ( string ident )
    {
        import std.exception;
        import std.format;

        if ( ident in this.sym_map )
        {
            return this.sym_map[ident];
        }
        else
        {
            enforce!SymtabException(this.parent !is null, format("No such identifier: %s", ident));
            return this.parent.lookup(ident);
        }
    }

    alias opIndex = lookup;

    /**
     * Check if a symbol exists
     *
     * Params:
     *      ident = The identifier
     *
     * Returns:
     *      True if the symbol exists, false otherwise
     */

    bool exists ( string ident )
    {
        if ( ident in this.sym_map )
        {
            return true;
        }
        else if ( this.parent !is null )
        {
            return this.parent.exists(ident);
        }
        else
        {
            return false;
        }
    }

    alias opIn_r = exists;

    /**
     * Set a identifier to a symbol
     *
     * Params:
     *      val = The symbol
     *      ident = The identifier
     *
     * Returns:
     *      The symbol
     */

    Symbol set ( Symbol val, string ident )
    in
    {
        assert(val !is null);
    }
    body
    {
        this.sym_map[ident] = val;
        return val;
    }

    alias opIndexAssign = set;
}
