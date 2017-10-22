/**
 * Semantic analyzer, constructs an annotated syntax tree
 */

module exlang.annotated.semantic;

/**
 * Semantic analysis exception
 */

class SemanticException : Exception
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
 * Semantic analyzer class
 */

class Semantic
{
    import exlang.absyn.declaration;
    import exlang.absyn.expression;
    import exlang.absyn.statement;
    import exlang.annotated.declaration;
    import exlang.annotated.expression;
    import exlang.annotated.statement;
    import exlang.symtab.env;

    /**
     * List of already analyzed global symbols, to avoid analyzing one twice
     */

    private string[] analyzed_symbols;

    /**
     * The list of global declarations
     */

    private Declaration[] global_decls;

    /**
     * Analyze a list of declarations
     *
     * Params:
     *      decls = The absyn declarations
     *
     * Returns:
     *      The list of annotated declarations
     *
     * Throws:
     *      SemanticException on semantic error
     */

    AnnDeclaration[] analyze ( Declaration[] decls )
    {
        import std.algorithm;
        import std.exception;
        import std.format;

        this.analyzed_symbols.length = 0;
        this.global_decls = decls;

        AnnDeclaration[] result;

        foreach ( decl; decls )
        {
            // Skip already analyzed symbols
            if ( this.analyzed_symbols.canFind(decl.ident) ) continue;

            result ~= this.analyzeDeclaration(decl, Env.global);
            this.analyzed_symbols ~= decl.ident;
        }

        return result;
    }

    /**
     * Analyze a declaration
     *
     * Params:
     *      decl = The absyn declaration
     *      env = The parent environment frame
     *
     * Returns:
     *      The annotated declaration
     *
     * Throws:
     *      SemanticException on semantic error
     */

    private AnnDeclaration analyzeDeclaration ( Declaration decl, Env env )
    {
        import std.format;

        if ( auto func_decl = cast(FuncDeclaration)decl )
        {
            return this.analyzeFuncDecl(func_decl, env);
        }
        else
        {
            throw new SemanticException(format("Unexpected declaration at global scope: %s", decl.toString()));
        }
    }

    /**
     * Analyze a function declaration
     *
     * Params:
     *      decl = The absyn declaration
     *      parent = The parent environment frame
     *
     * Returns:
     *      The annotated declaration
     *
     * Throws:
     *      SemanticException on semantic error
     */

    private AnnFuncDeclaration analyzeFuncDecl ( FuncDeclaration decl, Env parent )
    {
        import exlang.symtab.symbol;

        import std.exception;
        import std.format;

        auto type = cast(Type)parent[decl.type_id];
        enforce(type !is null, format("%s is not a type identifier", decl.type_id));

        scope env = new Env(parent);

        AnnArgDeclaration[] args;
        foreach ( arg; decl.args )
        {
            args ~= this.analyzeArgDecl(arg, env);
        }

        AnnStatement[] stmts;
        foreach ( i, stmt; decl.statements )
        {
            auto analyzed_stmt = this.analyzeStatement(stmt, env);

            // Last statement must be a return statement of the correct type, unless the function is void
            if ( i == decl.statements.length -1 )
            {
                auto ret_stmt = cast(AnnRetStatement)analyzed_stmt;

                if ( ret_stmt is null )
                {
                    enforce!SemanticException(type == parent["Void"], format("Last statement of function %s must be a ret statement, got: %s", decl.ident, stmt.toString()));
                }
                else
                {
                    enforce!SemanticException(ret_stmt.exp.type.ident == type.ident, format("Ret statement of function %s must be of type %s", decl.ident, decl.type_id));
                }
            }

            stmts ~= analyzed_stmt;
        }

        auto result = new AnnFuncDeclaration(decl.ident, type, args, stmts);
        parent[decl.ident] = new Function(decl.ident, result);

        return result;
    }

    /**
     * Analyze a function argument declaration
     *
     * Puts arguments in the env as variables with a null expression, so they
     * can be looked up during semantic analysis
     *
     * Params:
     *      decl = The absyn declaration
     *      env = The environment frame
     *
     * Returns:
     *      The annotated declaration
     */

    private AnnArgDeclaration analyzeArgDecl ( ArgDeclaration decl, Env env )
    {
        import exlang.symtab.symbol;

        import std.exception;
        import std.format;

        auto type = cast(Type)env[decl.type_id];
        enforce(type !is null, format("%s is not a type identifier", decl.type_id));

        env[decl.ident] = new Variable(decl.ident, type, null);

        return new AnnArgDeclaration(decl.ident, type);
    }

    /**
     * Analyze a statement
     *
     * Params:
     *      stmt = The absyn statement
     *      env = The environment frame
     *
     * Returns:
     *      The annotated statement
     *
     * Throws:
     *      SemanticException on semantic error
     */

    private AnnStatement analyzeStatement ( Statement stmt, Env env )
    {
        import std.format;

        if ( auto let_stmt = cast(LetStatement)stmt )
        {
            return this.analyzeLetStmt(let_stmt, env);
        }
        else if ( auto ret_stmt = cast(RetStatement)stmt )
        {
            return this.analyzeRetStmt(ret_stmt, env);
        }
        else if ( auto exp_stmt = cast(ExpStatement)stmt )
        {
            return this.analyzeExpStmt(exp_stmt, env);
        }
        else if ( auto if_stmt = cast(IfStatement)stmt )
        {
            return this.analyzeIfStmt(if_stmt, env);
        }
        else if ( auto for_stmt = cast(ForStatement)stmt )
        {
            return this.analyzeForStmt(for_stmt, env);
        }
        else
        {
            throw new SemanticException(format("Unexpected statement: %s", stmt.toString()));
        }
    }

    /**
     * Analyze a let statement
     *
     * Puts a variable in the env
     *
     * Params:
     *      stmt = The absyn statement
     *      env = The environment frame
     *
     * Returns:
     *      The annotated statement
     *
     * Throws:
     *      SemanticException on semantic error
     */

    private AnnLetStatement analyzeLetStmt ( LetStatement stmt, Env env )
    {
        import exlang.symtab.symbol;

        auto exp = this.analyzeExpression(stmt.exp, env);
        env[stmt.ident] = new Variable(stmt.ident, exp.type, exp);

        return new AnnLetStatement(stmt.ident, exp);
    }

    /**
     * Analyze a ret statement
     *
     * Params:
     *      stmt = The absyn statement
     *      env = The environment frame
     *
     * Returns:
     *      The annotated statement
     *
     * Throws:
     *      SemanticException on semantic error
     */

    private AnnRetStatement analyzeRetStmt ( RetStatement stmt, Env env )
    {
        auto exp = this.analyzeExpression(stmt.exp, env);

        return new AnnRetStatement(exp);
    }

    /**
     * Analyze an if statement
     *
     * Params:
     *      if_stmt = The absyn statement
     *      env = The environment frame
     *
     * Returns:
     *      The annotated statement
     *
     * Throws:
     *      SemanticException on semantic error
     */

    private AnnIfStatement analyzeIfStmt ( IfStatement if_stmt, Env env )
    {
        import std.exception;
        import std.format;

        auto ann_cond = this.analyzeExpression(if_stmt.cond, env);
        enforce!SemanticException(ann_cond.type.ident == "Bool", format("Condition must be boolean, not %s", if_stmt.cond));

        AnnStatement[] ann_stmts;
        foreach ( stmt; if_stmt.stmts )
        {
            ann_stmts ~= this.analyzeStatement(stmt, env);
        }

        AnnIfStatement.AnnElifClause[] ann_elifs;
        foreach ( elif; if_stmt.elifs )
        {
            auto ann_elif_cond = this.analyzeExpression(elif.cond, env);
            enforce!SemanticException(ann_elif_cond.type.ident == "Bool", format("Condition must be boolean, not %s", elif.cond));

            AnnStatement[] ann_elif_stmts;
            foreach ( stmt; elif.stmts )
            {
                ann_elif_stmts ~= this.analyzeStatement(stmt, env);
            }

            ann_elifs ~= AnnIfStatement.AnnElifClause(ann_elif_cond, ann_elif_stmts);
        }

        AnnStatement[] ann_else_stmts;
        foreach ( stmt; if_stmt.else_stmts )
        {
            ann_else_stmts ~= this.analyzeStatement(stmt, env);
        }

        return new AnnIfStatement(ann_cond, ann_stmts, ann_elifs, ann_else_stmts);
    }

    /**
     * Analyze a for statement
     *
     * Params:
     *      stmt = The absyn statement
     *      env = The environment frame
     *
     * Returns:
     *      The annotated statement
     *
     * Throws:
     *      SemanticException on semantic error
     */

    private AnnForStatement analyzeForStmt ( ForStatement for_stmt, Env env )
    {
        import exlang.symtab.symbol;

        import std.exception;
        import std.format;

        auto ann_iter_exp = this.analyzeExpression(for_stmt.iter_exp, env);
        enforce!SemanticException(cast(ArrayType)ann_iter_exp.type !is null,
            format("For statement iteration expression must be a list, not %s", ann_iter_exp.type.ident));

        env[for_stmt.iter_ident.ident] = new Variable(for_stmt.iter_ident.ident, (cast(ArrayType)ann_iter_exp.type).internal, null);
        auto ann_iter_ident = this.analyzeIdentExp(for_stmt.iter_ident, env);

        AnnStatement[] ann_stmts;

        foreach ( stmt; for_stmt.stmts )
        {
            ann_stmts ~= this.analyzeStatement(stmt, env);
        }

        return new AnnForStatement(ann_iter_ident, ann_iter_exp, ann_stmts);
    }

    /**
     * Analyze an expression statement
     *
     * Params:
     *      stmt = The absyn statement
     *      env = The environment frame
     *
     * Returns:
     *      The annotated statement
     *
     * Throws:
     *      SemanticException on semantic error
     */

    private AnnExpStatement analyzeExpStmt ( ExpStatement stmt, Env env )
    {
        auto exp = this.analyzeExpression(stmt.exp, env);

        return new AnnExpStatement(exp);
    }

    /**
     * Analyze an expression
     *
     * Params:
     *      exp = The absyn expression
     *      env = The environment frame
     *
     * Returns:
     *      The annotated expression
     *
     * Throws:
     *      SemanticException on semantic error
     */

    private AnnExpression analyzeExpression ( Expression exp, Env env )
    {
        import std.format;

        if ( auto ident_exp = cast(IdentExpression)exp )
        {
            return this.analyzeIdentExp(ident_exp, env);
        }
        else if ( auto call_exp = cast(CallExpression)exp )
        {
            return this.analyzeCallExp(call_exp, env);
        }
        else if ( auto equals_exp = cast(EqualsExpression)exp )
        {
            return this.analyzeEqualsExp(equals_exp, env);
        }
        else if ( auto add_exp = cast(AddExpression)exp )
        {
            return this.analyzeAddExp(add_exp, env);
        }
        else if ( auto not_exp = cast(NotExpression)exp )
        {
            return this.analyzeNotExp(not_exp, env);
        }
        else if ( auto append_exp = cast(AppendExpression)exp )
        {
            return this.analyzeAppendExp(append_exp, env);
        }
        else if ( auto int_exp = cast(IntExpression)exp )
        {
            return this.analyzeIntExp(int_exp, env);
        }
        else if ( auto char_exp = cast(CharLitExpression)exp )
        {
            return this.analyzeCharLitExp(char_exp, env);
        }
        else if ( auto list_exp = cast(ListExpression)exp )
        {
            return this.analyzeListExp(list_exp, env);
        }
        else
        {
            throw new SemanticException(format("Unexpected expression: %s", exp.toString()));
        }
    }

    /**
     * Analyze an identifier expression
     *
     * Params:
     *      exp = The absyn expression
     *      env = The environment frame
     *
     * Returns:
     *      The annotated expression
     *
     * Throws:
     *      SemanticException on semantic error
     */

    private AnnIdentExpression analyzeIdentExp ( IdentExpression exp, Env env )
    {
        import exlang.symtab.symbol;

        import std.exception;
        import std.format;

        if ( exp.ident !in env )
        {
            this.lookupAndAnalyze(exp.ident);
        }

        auto var = cast(Variable)env[exp.ident];
        enforce!SemanticException(var !is null, format("Symbol %s must be a variable"));

        return new AnnIdentExpression(var.type, exp.ident);
    }

    /**
     * Analyze a call expression
     *
     * Params:
     *      exp = The absyn expression
     *      env = The environment frame
     *
     * Returns:
     *      The annotated expression
     *
     * Throws:
     *      SemanticException on semantic error
     */

    private AnnCallExpression analyzeCallExp ( CallExpression exp, Env env )
    {
        import exlang.runtime.intrinsic;
        import exlang.symtab.symbol;

        import std.exception;
        import std.format;

        if ( exp.ident !in env )
        {
            this.lookupAndAnalyze(exp.ident);
        }

        auto sym = env[exp.ident];

        if ( auto func = cast(Function)sym )
        {
            enforce!SemanticException(func.args.length == exp.arg_exps.length, format("Function %s expects %d arguments", func.ident, func.args.length));

            AnnExpression[] args;
            foreach ( i, arg; exp.arg_exps )
            {
                auto annotated_arg = this.analyzeExpression(arg, env);
                enforce(annotated_arg.type.ident == func.args[i].type.ident, format("Argument %d of function %s must be of type %s", i, func.ident, func.args[i].type.ident));
                args ~= annotated_arg;
            }

            return new AnnCallExpression(func.type, exp.ident, args);
        }
        else if ( auto func = cast(IntrinsicFunction)sym )
        {
            enforce!SemanticException(func.arg_types.length == exp.arg_exps.length, format("Function %s expects %d arguments", func.ident, func.arg_types.length));

            AnnExpression[] args;
            foreach ( i, arg; exp.arg_exps )
            {
                auto annotated_arg = this.analyzeExpression(arg, env);
                enforce(annotated_arg.type.ident == func.arg_types[i].ident, format("Argument %d of function %s of be of type %s", i, func.ident, func.arg_types[i].ident));
                args ~= annotated_arg;
            }

            return new AnnCallExpression(func.ret_type, exp.ident, args);
        }
        else
        {
            throw new SemanticException(format("Symbol %s must be a function", exp.ident));
        }
    }

    /**
     * Analyze an equals expression
     *
     * Params:
     *      exp = The absyn expression
     *      env = The environment frame
     *
     * Returns:
     *      The annotated expression
     *
     * Throws:
     *      SemanticException on semantic error
     */

    private AnnEqualsExpression analyzeEqualsExp ( EqualsExpression exp, Env env )
    {
        import std.exception;
        import std.format;

        auto ann_left = this.analyzeExpression(exp.left, env);
        auto ann_right = this.analyzeExpression(exp.right, env);
        enforce!SemanticException(ann_left.type.ident == ann_right.type.ident, format("Arguments of expression %s must be of the same type", exp.toString()));

        return new AnnEqualsExpression(ann_left, ann_right);
    }

    /**
     * Analyze an add expression
     *
     * Params:
     *      exp = The absyn expression
     *      env = The environment frame
     *
     * Returns:
     *      The annotated expression
     *
     * Throws:
     *      SemanticException on semantic error
     */

    private AnnAddExpression analyzeAddExp ( AddExpression exp, Env env )
    {
        import std.exception;
        import std.format;

        auto ann_left = this.analyzeExpression(exp.left, env);
        enforce!SemanticException(ann_left.type.ident == "Int", format("First argument of expression %s must be of type Int", exp.toString()));

        auto ann_right = this.analyzeExpression(exp.right, env);
        enforce!SemanticException(ann_right.type.ident == "Int", format("Second argument of expression %s must be of type Int", exp.toString()));

        enforce!SemanticException(ann_left.type.ident == ann_right.type.ident, format("Arguments of expression %s must be of the same type", exp.toString()));

        return new AnnAddExpression(ann_left.type, ann_left, ann_right);
    }

    /**
     * Analyize a not expression
     *
     * Params:
     *      exp = The absyn expression
     *      env = The environment frame
     *
     * Returns:
     *      The annotated expression
     *
     * Throws:
     *      SemanticExpression on semantic error
     */

    private AnnNotExpression analyzeNotExp ( NotExpression exp, Env env )
    {
        import std.exception;
        import std.format;

        auto ann_exp = this.analyzeExpression(exp.exp, env);
        enforce!SemanticException(ann_exp.type.ident == "Bool", format("Argument of expression %s must be of type Bool", exp));

        return new AnnNotExpression(ann_exp.type, ann_exp);
    }

    /**
     * Analyze an append expression
     *
     * Lowers it to a call to an append function
     *
     * Params:
     *      exp = The append expression
     *      env = The environment frame
     *
     * Returns:
     *      The lowered expression
     *
     * Throws:
     *      SemanticException on semantic error
     */

    private AnnCallExpression analyzeAppendExp ( AppendExpression exp, Env env )
    {
        import exlang.symtab.symbol;

        import std.exception;
        import std.format;

        auto ann_left = this.analyzeExpression(exp.left, env);
        enforce!SemanticException(cast(ArrayType)ann_left.type !is null, format("First argument of expression %s must be a list, not %s", exp.toString(), ann_left.type.ident));

        auto ann_right = this.analyzeExpression(exp.right, env);
        enforce!SemanticException(cast(ArrayType)ann_right.type !is null, format("Second argument of expression %s must be a list, not %s", exp.toString(), ann_right.type.ident));

        enforce!SemanticException(ann_left.type.ident == ann_right.type.ident, format("Arguments of expression %s must be of the same type", exp.toString()));

        switch ( ann_left.type.ident )
        {
            case "[Int]":
                return new AnnCallExpression(ann_left.type, "appint", [ann_left, ann_right]);

            case "[Char]":
                return new AnnCallExpression(ann_left.type, "appstr", [ann_left, ann_right]);

            default:
                throw new SemanticException(format("Invalid type in expression %s", exp.toString()));
        }
    }

    /**
     * Analyze an int expression
     *
     * Params:
     *      exp = The absyn expression
     *      env = The environment frame
     *
     * Returns:
     *      The annotated expression
     */

    private AnnIntExpression analyzeIntExp ( IntExpression exp, Env env )
    {
        return new AnnIntExpression(exp.value);
    }

    /**
     * Analyze a char lit expression
     *
     * Params:
     *      exp = The absyn expression
     *      env = The environment frame
     *
     * Returns:
     *      The annotated expression
     */

    private AnnCharLitExpression analyzeCharLitExp ( CharLitExpression exp, Env env )
    {
        return new AnnCharLitExpression(exp.value);
    }

    /**
     * Analyze a list expression
     *
     * Params:
     *      exp = The absyn expression
     *      env = The environment frame
     *
     * Returns:
     *      The annotated expression
     *
     * Throws:
     *      SemanticException on semantic error
     */

    private AnnListExpression analyzeListExp ( ListExpression exp, Env env )
    {
        import exlang.symtab.symbol;

        import std.exception;

        // TODO: Implement empty list expressions
        enforce!SemanticException(exp.exps.length > 0, "Empty list expressions not implemented");

        Type type;
        AnnExpression[] ann_exps;

        foreach ( i, internal; exp.exps )
        {
            auto ann_internal = this.analyzeExpression(internal, env);

            if ( i == 0 )
            {
                type = ann_internal.type;
            }
            else
            {
                enforce!SemanticException(ann_internal.type.ident == type.ident, "List expressions must be of the same type, got %s", exp.toString());
            }

            ann_exps ~= ann_internal;
        }

        return new AnnListExpression(type, ann_exps);
    }

    /**
     * Helper function to look up and analyze a symbol, if found
     *
     * Puts the symbol in the analyzed symbols list if it was found and
     * successfully analyzed
     *
     * Params:
     *      ident = The identifier to look up
     */

    private void lookupAndAnalyze ( string ident )
    {
        foreach ( decl; this.global_decls )
        {
            if ( decl.ident == ident )
            {
                this.analyzeDeclaration(decl, Env.global);
                this.analyzed_symbols ~= ident;
                break;
            }
        }
    }
}
