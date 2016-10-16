/**
 * Array utilities
 */

module util.array;

/**
 * Get the length of the longest array
 *
 * Params:
 *      T = The element contained in the arrays
 *      arrs = The arrays
 *
 * Returns:
 *      The length of the longest array
 */

size_t longestLength ( T ) ( T[][] arrs )
{
    size_t result;

    foreach ( arr; arrs )
    {
        if ( arr.length > result )
        {
            result = arr.length;
        }
    }

    return result;
}
