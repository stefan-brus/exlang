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
        char character;
        bool boolean;
        Value[] list;
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
        else static if ( is(T == char) )
        {
            assert(this.type.ident == "Char");
            this.internal_val.character = val;
        }
        else static if ( is(T == bool) )
        {
            assert(this.type.ident == "Bool");
            this.internal_val.boolean = val;
        }
        else static if ( is(T == Value[]) )
        {
            assert(this.type.ident[0] == '[');
            this.internal_val.list = val;
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
        else static if ( is(T == char) )
        {
            assert(this.type.ident == "Char");
            return this.internal_val.character;
        }
        else static if ( is(T == bool) )
        {
            assert(this.type.ident == "Bool");
            return this.internal_val.boolean;
        }
        else static if ( is(T == Value[]) )
        {
            assert(this.type.ident[0] == '[');
            return this.internal_val.list;
        }
        else
        {
            static assert(false, "Unknown value type: " ~ T.stringof);
        }
    }

    /**
     * Compare two values
     *
     * Params:
     *      left = The left value
     *      right = The right value
     *
     * Returns:
     *      Negative if left is "less" than right, 0 if they are equal,
     *      positive if left is "greater" than right
     *
     * Throws:
     *      EvalException on error
     */

    static int compare ( Value left, Value right )
    {
        import exlang.interpreter.exception;

        import std.algorithm;
        import std.exception;
        import std.format;

        enforce!EvalException(left.type.ident == right.type.ident, format("Can't compare different types, got: %s and %s", left.type.ident, right.type.ident));

        switch ( left.type.ident )
        {
            case "Int":
                return compareInternal(left.get!ulong, right.get!ulong);

            case "Char":
                return compareInternal(left.get!char, right.get!char);

            case "Bool":
                return compareInternal(left.get!bool, right.get!bool);

            default:
                if ( left.type.ident[0] == '[' )
                {
                    return compareAll(left.get!(Value[]), right.get!(Value[]));
                }
                else
                {
                    throw new EvalException(format("Value comparison not implemented for type: %s", left.type.ident));
                }
        }
    }

    /**
     * Compare two value arrays
     *
     * Params:
     *      left = The left array
     *      right = The right array
     *
     * Returns:
     *      Negative if left is "less" than right, 0 if they are equal,
     *      positive if left is "greater" than right
     *
     * Throws:
     *      EvalException on error
     */

    private static int compareAll ( Value[] left, Value[] right )
    {
        if ( left.length < right.length )
        {
            return -1;
        }
        else if ( left.length > right.length )
        {
            return 1;
        }
        else
        {
            assert(left.length == right.length);

            int total;

            foreach ( i, val_left; left )
            {
                total += compare(val_left, right[i]);
            }

            return total;
        }
    }

    /**
     * Compare two internal values
     *
     * Template_params:
     *      T = The internal value
     *
     * Params:
     *      left = The left internal value
     *      right = The right internal value
     *
     * Returns:
     *      Negative if left is "less" than right, 0 if they are equal,
     *      positive if left is "greater" than right
     */

    private static int compareInternal ( T ) ( T left, T right )
    {
        static if ( is(T == ulong) || is(T == char) )
        {
            if ( left < right ) return -1;
            else if ( left > right ) return 1;
            else return 0;
        }
        else static if ( is(T == bool) )
        {
            if ( !left && right ) return -1;
            else if ( left && !right ) return 1;
            else return 0;
        }
        else
        {
            static assert(false, "Unknown value type: " ~ T.stringof);
        }
    }
}
