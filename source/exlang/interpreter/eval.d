/**
 * Exlang interpreter
 *
 * Looks for the "main" function in the global environment
 * If found, recursively evaluate the statements/expressions
 */

module exlang.interpreter.eval;

/**
 * Evaluator class
 */

class Evaluator
{
    import exlang.annotated.declaration;
    import exlang.annotated.expression;
    import exlang.annotated.statement;
    import exlang.interpreter.value;
    import exlang.runtime.intrinsic;
    import exlang.symtab.env;

    /**
     * Run the main function
     *
     * Throws:
     *      EvalException on error
     */

    void run ( )
    {
        import exlang.interpreter.exception;
        import exlang.symtab.symbol;

        import std.exception;

        enforce!EvalException("main" in Env.global, "No main function declared");

        auto main = cast(Function)Env.global["main"];
        enforce!EvalException(main !is null, "Main must be a function");

        this.evalFunction(main, null, Env.global);
    }

    /**
     * Evaluate a function
     *
     * Params:
     *      decl = The declaration
     *      args = The argument expressions
     *      parent = The parent environment frame
     *
     * Returns:
     *      The function return value
     *
     * Throws:
     *      EvalException on error
     */

    private Value evalFunction ( AnnFuncDeclaration decl, AnnExpression[] args, Env parent )
    {
        import exlang.interpreter.exception;
        import exlang.symtab.symbol;

        import std.exception;
        import std.format;

        enforce!EvalException(decl.args.length == args.length, format("Function %s expects %d arguments", decl.ident, decl.args.length));

        scope env = new Env(parent);

        foreach ( i, arg; decl.args )
        {
            auto val = this.evalExpression(args[i], env);
            env[arg.ident] = new ValueVar(arg.ident, val);
        }

        Value result;
        foreach ( i, stmt; decl.statements )
        {
            auto val = this.evalStatement(stmt, env);

            if ( i == decl.statements.length - 1 )
            {
                if ( cast(AnnRetStatement)decl.statements[$ - 1] )
                {
                    enforce!EvalException(val.type.ident != "Void", format("Function %s cannot return a void value", decl.ident));
                    result = val;
                }
                else
                {
                    enforce!EvalException(decl.type.ident == "Void", format("Function %s does not return void", decl.ident));
                    result = cast(Value)Value.VOID;
                }
            }
        }

        return result;
    }

    /**
     * Evaluate an intrinsic function
     *
     * Params:
     *      func = The intrinsic function
     *      args = The argument expressions
     *      parent = The parent environment frame
     */

    private Value evalIntrinsic ( Intrinsic func, AnnExpression[] args, Env parent )
    {
        import exlang.interpreter.exception;

        import std.exception;
        import std.format;

        enforce!EvalException(func.arg_types.length == args.length, format("Function %s expects %d arguments", func.ident, func.arg_types.length));

        scope env = new Env(parent);

        Value[] vals;
        foreach ( i, arg; args )
        {
            enforce!EvalException(arg.type.ident == func.arg_types[i].ident, format("Function %s expects argument %d to be of type %s", func.ident, i, func.arg_types[i].ident));
            vals ~= this.evalExpression(arg, env);
        }

        return func.run(vals);
    }

    /**
     * Evaluate a statement
     *
     * Params:
     *      stmt = The statement
     *      env = The environment frame
     *
     * Returns:
     *      The statement value
     *
     * Throws:
     *      EvalException on error
     */

    private Value evalStatement ( AnnStatement stmt, Env env )
    {
        import exlang.interpreter.exception;
        if ( auto let_stmt = cast(AnnLetStatement)stmt )
        {
            return this.evalLetStatement(let_stmt, env);
        }
        else if ( auto ret_stmt = cast(AnnRetStatement)stmt )
        {
            return this.evalRetStatement(ret_stmt, env);
        }
        else if ( auto exp_stmt = cast(AnnExpStatement)stmt )
        {
            return this.evalExpStatement(exp_stmt, env);
        }
        else
        {
            throw new EvalException("Unknown statement type");
        }
    }

    /**
     * Evaluate a let statement
     *
     * Params:
     *      stmt = The statement
     *      env = The environment frame
     *
     * Returns:
     *      The statement value
     */

    private Value evalLetStatement ( AnnLetStatement stmt, Env env )
    {
        import exlang.symtab.symbol;

        env[stmt.ident] = new Variable(stmt.ident, stmt.exp.type, stmt.exp);

        return cast(Value)Value.VOID;
    }

    /**
     * Evaluate a ret statement
     *
     * Params:
     *      stmt = The statement
     *      env = The environment frame
     *
     * Returns:
     *      The statement value
     *
     * Throws:
     *      EvalException on error
     */

    private Value evalRetStatement ( AnnRetStatement stmt, Env env )
    {
        return this.evalExpression(stmt.exp, env);
    }

    /**
     * Evaluate an expression statement
     *
     * Params:
     *      stmt = The statement
     *      env = The environment frame
     *
     * Returns:
     *      The statement value
     *
     * Throws:
     *      EvalException on error
     */

    private Value evalExpStatement ( AnnExpStatement stmt, Env env )
    {
        return this.evalExpression(stmt.exp, env);
    }

    /**
     * Evaluate an expression
     *
     * Params:
     *      exp = The expression
     *      env = The environment frame
     *
     * Returns:
     *      The expression value
     *
     * Throws:
     *      EvalException on error
     */

    private Value evalExpression ( AnnExpression exp, Env env )
    {
        import exlang.interpreter.exception;

        if ( auto ident_exp = cast(AnnIdentExpression)exp )
        {
            return this.evalIdentExpression(ident_exp, env);
        }
        else if ( auto call_exp = cast(AnnCallExpression)exp )
        {
            return this.evalCallExpression(call_exp, env);
        }
        else if ( auto add_exp = cast(AnnAddExpression)exp )
        {
            return this.evalAddExpression(add_exp, env);
        }
        else if ( auto int_exp = cast(AnnIntExpression)exp )
        {
            return this.evalIntExpression(int_exp, env);
        }
        else if ( auto char_exp = cast(AnnCharLitExpression)exp )
        {
            return this.evalCharLitExpression(char_exp, env);
        }
        else if ( auto list_exp = cast(AnnListExpression)exp )
        {
            return this.evalListExpression(list_exp, env);
        }
        else
        {
            throw new EvalException("Unknown expression type");
        }
    }

    /**
     * Evaluate an identifier expression
     *
     * Params:
     *      exp = The expression
     *      env = The environment frame
     *
     * Returns:
     *      The expression value
     *
     * Throws:
     *      EvalException on error
     */

    private Value evalIdentExpression ( AnnIdentExpression exp, Env env )
    {
        import exlang.interpreter.exception;
        import exlang.symtab.symbol;

        import std.format;

        auto sym = env[exp.ident];

        if ( auto val_var = cast(ValueVar)sym )
        {
            return val_var.value;
        }
        else if ( auto var = cast(Variable)sym )
        {
            return this.evalExpression(var.exp, env);
        }
        else
        {
            throw new EvalException(format("%s expected to be a variable", exp.ident));
        }
    }

    /**
     * Evaluate a call expression
     *
     * Params:
     *      exp = The expression
     *      env = The environment frame
     *
     * Returns:
     *      The expression value
     *
     * Throws:
     *      EvalException on error
     */

    private Value evalCallExpression ( AnnCallExpression exp, Env env )
    {
        import exlang.interpreter.exception;
        import exlang.symtab.symbol;

        import std.format;

        auto sym = env[exp.ident];

        if ( auto func = cast(Function)sym )
        {
            return this.evalFunction(func, exp.arg_exps, env);
        }
        else if ( auto intrinsic = cast(IntrinsicFunction)sym )
        {
            return this.evalIntrinsic(intrinsic, exp.arg_exps, env);
        }
        else
        {
            throw new EvalException(format("%s expected to be a function", exp.ident));
        }
    }

    /**
     * Evaluate an add expression
     *
     * Params:
     *      exp = The expression
     *      env = The environment frame
     *
     * Returns:
     *      The expression value
     *
     * Throws:
     *      EvalException on error
     */

    private Value evalAddExpression ( AnnAddExpression exp, Env env )
    {
        import exlang.interpreter.exception;

        import std.exception;
        import std.format;

        auto val_left = this.evalExpression(exp.left, env);
        auto val_right = this.evalExpression(exp.right, env);

        enforce!EvalException(val_left.type.ident == val_right.type.ident, "Can't add different types");
        enforce!EvalException(val_left.type.ident == "Int", format("Can only add integers, not %s", val_left.type));

        auto result = new Value(val_left.type);
        result.set(val_left.get!ulong + val_right.get!ulong);

        return result;
    }

    /**
     * Evaluate an integer expression
     *
     * Params:
     *      exp = The expression
     *      env = The environment frame
     *
     * Returns:
     *      The expression value
     */

    private Value evalIntExpression ( AnnIntExpression exp, Env env )
    {
        import exlang.symtab.symbol;

        auto result = new Value(cast(Type)Env.global["Int"]);
        result.set(exp.value);

        return result;
    }

    /**
     * Evaluate a character literal expression
     *
     * Params:
     *      exp = The expression
     *      env = The environment frame
     *
     * Returns:
     *      The expression value
     */

    private Value evalCharLitExpression ( AnnCharLitExpression exp, Env env )
    {
        import exlang.symtab.symbol;

        auto result = new Value(cast(Type)Env.global["Char"]);
        result.set(exp.value);

        return result;
    }

    /**
     * Evaluate a list expression
     *
     * Params:
     *      exp = The expression
     *      env = The environment
     *
     * Returns:
     *      The expression value
     */

    private Value evalListExpression ( AnnListExpression exp, Env env )
    {
        import exlang.interpreter.exception;
        import exlang.symtab.symbol;

        import std.exception;
        import std.format;

        auto result = new Value(exp.type);
        auto internal_type = (cast(ArrayType)exp.type).internal;
        Value[] internal_vals;

        foreach ( internal_exp; exp.exps )
        {
            auto val = this.evalExpression(internal_exp, env);

            enforce!EvalException(val.type == internal_type, format("Wrong type for expression %s, expected %s", internal_exp, internal_type.ident));

            internal_vals ~= val;
        }

        result.set(internal_vals);

        return result;
    }
}
