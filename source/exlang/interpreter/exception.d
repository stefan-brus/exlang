/**
 * Evaluation exception
 */

module exlang.interpreter.exception;

/**
 * Eval exception
 */

class EvalException : Exception
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
