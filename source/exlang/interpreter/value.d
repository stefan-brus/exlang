/**
 * Interpreted values
 *
 * A value is a type symbol and a union of possible internal values
 *
 * Also contains a ValueSymbol for use with the symbol table when evaluating
 */

module exlang.interpreter.value;

/**
 * Imports
 */

import exlang.symtab.symbol;

/**
 * Value symbol class
 */

class ValueVar : Symbol
{
    /**
     * The value
     */

    Value value;

    /**
     * Constructor
     *
     * Params:
     *      ident = The identifier
     *      value = The value
     */

    this ( string ident, Value value )
    {
        super(ident);
        this.value = value;
    }
}

/**
 * Value class
 */

class Value
{
    /**
     * Utility constants
     */

    static const Value VOID = new Value(new Type("Void"));

    /**
     * The type of this value
     */

    Type type;

    /**
     * The union of possible internal values
     */

    private union InternalVal
    {
        ulong integer;
    }
    ///ditto
    private InternalVal internal_val;

    /**
     * Constructor
     *
     * Params:
     *      type = The type
     */

    this ( Type type )
    {
        this.type = type;
    }

    /**
     * Set the internal value
     *
     * Template_params:
     *      T = The internal value type
     *
     * Params:
     *      val = The value
     */

    void set ( T ) ( T val )
    {
        static if ( is(T == ulong) )
        {
            assert(this.type.ident == "Int");
            this.internal_val.integer = val;
        }
        else
        {
            static assert(false, "Unknown value type: " ~ T.stringof);
        }
    }

    /**
     * Get the internal value
     *
     * Template_params:
     *      T = The internal value type
     *
     * Returns:
     *      The internal value
     */

    T get ( T ) ( )
    {
        static if ( is(T == ulong) )
        {
            assert(this.type.ident == "Int");
            return this.internal_val.integer;
        }
        else
        {
            static assert(false, "Unknown value type: " ~ T.stringof);
        }
    }
}
