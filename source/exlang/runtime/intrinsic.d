/**
 * Intrinsic functions
 *
 * Also contains an Intrinsic symbol for use with the symbol table when evaluating
 */

module exlang.runtime.intrinsic;

/**
 * Imports
 */

import exlang.symtab.symbol;

/**
 * Intrinsic symbol class
 */

class IntrinsicFunction : Symbol
{
    /**
     * The function
     */

    Intrinsic func;

    alias func this;

    /**
     * Constructor
     *
     * Params:
     *      ident = The identifier
     *      func = The function
     */

    this ( string ident, Intrinsic func )
    {
        super(ident);

        this.func = func;
    }
}

/**
 * Intrinsic function class
 */

class Intrinsic
{
    import exlang.interpreter.value;

    /**
     * The identifier
     */

    string ident;

    /**
     * The return type
     */

    Type ret_type;

    /**
     * The argument types
     */

    Type[] arg_types;

    /**
     * The function
     */

    alias IntrinsicDg = Value delegate ( Value[] );

    IntrinsicDg run;

    /**
     * Constructor
     *
     * Params:
     *      ident = The identifier;
     *      ret_type = The return type
     *      arg_types = The argument types
     *      run = The function
     */

    this ( string ident, Type ret_type, Type[] arg_types, IntrinsicDg run )
    {
        this.ident = ident;
        this.ret_type = ret_type;
        this.arg_types = arg_types;
        this.run = run;
    }
}
