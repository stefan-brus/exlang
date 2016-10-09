/**
 * Parser utility functions
 */

module exlang.parse.util;

import exlang.parse.token;

/**
 * Check if a token type is a binary operator
 *
 * Params:
 *      type = The token type
 *
 * Returns:
 *      True if the token is a binary operator
 */

bool isBinOp ( TokType type )
{
    with ( TokType ) switch ( type )
    {
        case Plus:
        case Slash:
        case Tilde:
            return true;

        default:
            return false;
    }
}
