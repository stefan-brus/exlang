/**
 * Test that the examples compile and run without errors
 */

/**
 * Main
 */

void main ( )
{
    import std.file;
    import std.process;
    import std.stdio;

    foreach ( string name; dirEntries("examples", SpanMode.depth) )
    {
        writefln("Running %s", name);

        auto dub = executeShell("dub run -- " ~ name);

        if ( dub.status != 0 )
        {
            writefln("Error running %s", name);
            writeln("Output:");
            writeln(dub.output);
        }
        else
        {
            writefln("Successfully ran %s", name);
        }
    }
}
