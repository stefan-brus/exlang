/**
 * The initial global environment
 */

module exlang.runtime.global;

/**
 * Imports
 */

import exlang.symtab.env;

/**
 * Set up the global environment
 *
 * Params:
 *      env = The global environment
 */

void setupGlobal ( Env env )
{
    import exlang.runtime.intrinsic;
    import exlang.symtab.symbol;

    // The built in types
    env["Void"] = new Type("Void");
    env["Int"] = new Type("Int");
    env["Char"] = new Type("Char");

    // The intrinsic functions
    env["printnum"] = new IntrinsicFunction("printnum", Builtin.printnum);
    env["printchr"] = new IntrinsicFunction("printchr", Builtin.printchr);
}

/**
 * Namespace for the built-in functions
 */

private struct Builtin
{
    import exlang.interpreter.value;
    import exlang.runtime.intrinsic;

    /**
     * printnum
     *
     * Prints the given Int
     *
     * Params:
     *      args = The arguments
     *
     * Returns:
     *      Void
     *
     * Throws:
     *      EvalException on error
     */

    static Value printnum_impl ( Value[] args )
    {
        import exlang.interpreter.exception;

        import std.exception;
        import std.stdio;

        enforce!EvalException(args.length == 1, "printnum: expects 1 argument");
        enforce!EvalException(args[0].type.ident == "Int", "printnum: argument must be Int");

        writefln("%d", args[0].get!ulong);

        return cast(Value)Value.VOID;
    }

    static Intrinsic printnum;

    /**
     * printchr
     *
     * Prints the given Char
     *
     * Params:
     *      args = The arguments
     *
     * Returns:
     *      Void
     *
     * Throws:
     *      EvalException on error
     */

    static Value printchr_impl ( Value[] args )
    {
        import exlang.interpreter.exception;

        import std.exception;
        import std.stdio;

        enforce!EvalException(args.length == 1, "printchr: expects 1 argument");
        enforce!EvalException(args[0].type.ident == "Char", "printchr: argument must be Char");

        writefln("%c", args[0].get!char);

        return cast(Value)Value.VOID;
    }

    static Intrinsic printchr;

    static this ( )
    {
        import exlang.symtab.symbol;

        import std.functional;

        printnum = new Intrinsic("printnum", new Type("Void"), [new Type("Int")], toDelegate(&printnum_impl));
        printchr = new Intrinsic("printchr", new Type("Void"), [new Type("Char")], toDelegate(&printchr_impl));
    }
}
