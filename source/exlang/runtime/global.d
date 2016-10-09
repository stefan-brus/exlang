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
    env["String"] = new ArrayType(cast(Type)env["Char"]);

    // The intrinsic functions
    env["printnum"] = new IntrinsicFunction("printnum", Builtin.printnum);
    env["printchr"] = new IntrinsicFunction("printchr", Builtin.printchr);
    env["printlst"] = new IntrinsicFunction("printlst", Builtin.printlst);
    env["print"] = new IntrinsicFunction("print", Builtin.print);
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

    /**
     * printlst
     *
     * Prints the given list
     *
     * TODO: Support internal types other than Int
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

    static Value printlst_impl ( Value[] args )
    {
        import exlang.interpreter.exception;
        import exlang.symtab.symbol;

        import std.exception;
        import std.stdio;

        enforce!EvalException(args.length == 1, "printlst: expects 1 argument");
        enforce!EvalException(cast(ArrayType)args[0].type !is null, "printlst: argument must be List");

        write("[");

        auto vals = args[0].get!(Value[]);
        foreach ( i, val; vals )
        {
            enforce!EvalException(val.type.ident == "Int", "printlst: Currently only supports integer lists");
            writef("%s", val.get!ulong);

            if ( i < vals.length - 1 )
            {
                write(", ");
            }
        }

        writeln("]");

        return cast(Value)Value.VOID;
    }

    static Intrinsic printlst;

    /**
     * print
     *
     * Prints the given string
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

    static Value print_impl ( Value[] args )
    {
        import exlang.interpreter.exception;
        import exlang.symtab.symbol;

        import std.exception;
        import std.stdio;

        enforce!EvalException(args.length == 1, "print: expects 1 argument");
        enforce!EvalException(cast(ArrayType)args[0].type !is null, "print: argument must be String");

        auto vals = args[0].get!(Value[]);
        foreach ( val; vals )
        {
            enforce!EvalException(val.type.ident == "Char", "print: Currently only supports strings");
            writef("%s", val.get!char);
        }

        writeln();

        return cast(Value)Value.VOID;
    }

    static Intrinsic print;

    static this ( )
    {
        import exlang.symtab.symbol;

        import std.functional;

        printnum = new Intrinsic("printnum", new Type("Void"), [new Type("Int")], toDelegate(&printnum_impl));
        printchr = new Intrinsic("printchr", new Type("Void"), [new Type("Char")], toDelegate(&printchr_impl));
        printlst = new Intrinsic("printlst", new Type("Void"), [new ArrayType(new Type("Int"))], toDelegate(&printlst_impl));
        print = new Intrinsic("print", new Type("Void"), [new ArrayType(new Type("Char"))], toDelegate(&print_impl));
    }
}
