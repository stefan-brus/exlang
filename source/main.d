/**
 * Exlang main module
 */

module main;

/**
 * Main
 *
 * Params:
 *      args = CLI args
 */

int main ( string[] args )
{
    import exlang.annotated.semantic;
    import exlang.interpreter.eval;
    import exlang.parse.parser;
    import exlang.runtime.global;
    import exlang.symtab.env;

    import std.file;
    import std.stdio;

    if ( args.length != 2 )
    {
        writefln("USAGE: exlang [FILE]");
        return 1;
    }

    auto source = readText(args[1]);
    auto parser = new Parser();
    auto decls = parser.parse(source);

    //writeln("Parse successful, declarations:");
    /*foreach ( decl; decls )
    {
        writeln(decl);
    }*/

    setupGlobal(Env.global);
    auto semantic = new Semantic();
    auto ann_decls = semantic.analyze(decls);

    //writeln("Semantic analysis successful, interpreting");
    auto eval = new Evaluator();
    eval.run();

    return 0;
}
