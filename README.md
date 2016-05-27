# exlang

Experimental programming language.

## Example

```
// The very first, historical, exlang program, that interprets and runs
def main() Void:
  let v = 3;
  let w = 4;
  // This is a crazy comment
  printnum(myfunc(v, w));

def myfunc(x : Int, y : Int) Int:
  printnum(x);
  printnum(y);
  ret x + y + 1;
```
