# Prolog Sudoku Documentation
In this part of the documentation, all defined predicates are described and usage examples are shown..

## List Operations 

### `removeItem/3 (+Item, +List, -Out)`
Deterministic wrapper for select/3 (removes only the first occurence of Item from List). \
    If Item is not found, the original list is returned.
```prolog

?- removeItem(a, [a,b,c,d], Out).
Out = [b,c,d].

?- removeItem(a, [a,b,c,d,a], Out).
Out = [b,c,d,a].

?- removeItem(x, [a,b,c,a], Out).
Out = [a,b,c,a].
```

### `reduceDomain/3 (+Vars, +Domain, -Out)`
Scans +Vars, if there is an assigned value, it gets removed from the Domain.
```prolog

?- reduceDomain([a,X,_,b], [a,b,c,d], Out).
Out = [c,d].

```

### `obfuscateLine/3 (+Probability, +InLine, -OutLine)`
Given a probability threshold, this predicate recursively replaces random items in the list with free variables.
```prolog

?- obfuscateLine(0.5, [a,b,c,d], Out). % (nondeterministic because of randomness, might give different results)
Out = [_9030, b, c, _9060].

?- obfuscateLine(1, [a,b,c,d], Out).
Out = [_412, _418, _424, _430].

?- obfuscateLine(0, [a,b,c,d], Out).
Out = [a,b,c,d].
```

## Sudoku Board Operations 

### `getBoard/3 (+Rows, +Cols, -Matrix)`
Generates matrix of size (Rows x Cols) filled with free variables.
```prolog

?- getBoard(2,2,Sudoku).
Sudoku = [[_366, _372], [_384, _390]].

```

### `peelLeft/3 (+Matrix, -Col, -RestOfMatrix)`
Extracts the first elements of all rows and returns a list of these.\ 
Also returns a list of tails of the original rows. Fails with matrix of empty rows, returns empty lists for empty matrix.
```prolog

?- peelLeft([[a,b],[c,d]],Col,Rest).
Col = [a, c],
Rest = [[b], [d]].

```

### `transpose/2 (+ListOfRows, -ListOfCols)`
Transposes the input matrix represented as a list of rows. Predicate is not symmetrical!
```prolog

?- transpose([[a,b],[c,d]], Cols).
Cols = [[a, c], [b, d]].

```

### `getBoxStack/6 (+Sudoku, +BoxWidth, +BoxHeight, +Buffer, -BoxStack, -RestOfSudoku)`

- getBoxStack/6 returns a list of boxes from the leftmost stack of boxes of the Sudoku board. \
Also returns the rest of the board (as a list of rows).
- Predicate recursively peels the leftmost parts of rows (of length BoxWidth) and stores them into Buffer. \
When the desired number of rows (BoxHeight) has been processed, buffer is cleared and stored into the Out list.
```prolog

?- Sudoku = 
    [[2,4,3,1,6,5],
    [3,1,6,5,2,4],
    [6,5,2,4,3,1],
    [4,2,1,3,5,6],
    [1,3,5,6,4,2],
    [5,6,4,2,1,3]], getBoxStack(Sudoku,3,2,[],Stack,Rest).

Sudoku = [[2, 4, 3, 1, 6, 5], [3, 1, 6, 5, 2, 4], [6, 5, 2, 4, 3, 1], [4, 2, 1, 3, 5|...], [1, 3, 5, 6|...], [5, 6, 4|...]],
Stack = [[3, 1, 6, 2, 4, 3], [4, 2, 1, 6, 5, 2], [5, 6, 4, 1, 3, 5]],
Rest = [[1, 6, 5], [5, 2, 4], [4, 3, 1], [3, 5, 6], [6, 4, 2], [2, 1, 3]].

```

### `getBoxes_/4 (+Sudoku, +BoxWidth, +BoxHeight, -Out)`
*Notice the underscore_ in the name.* Recursively peels the left side stack of boxes from the +Sudoku board until none are left.
```prolog

?- getBoxes_([[a,b],[c,d]],1,1,Out).
Out = [[a], [c], [b], [d]].

?- Sudoku = 
  [[2,4,3,1,6,5],
  [3,1,6,5,2,4],
  [6,5,2,4,3,1],
  [4,2,1,3,5,6],
  [1,3,5,6,4,2],
  [5,6,4,2,1,3]], getBoxes_(Sudoku,2,2,Boxes).
Sudoku = [[2, 4, 3, 1, 6, 5], [3, 1, 6, 5, 2, 4], [6, 5, 2, 4, 3, 1], [4, 2, 1, 3, 5|...], [1, 3, 5, 6|...], [5, 6, 4|...]],
Boxes = [[3, 1, 2, 4], [4, 2, 6, 5], [5, 6, 1, 3], [6, 5, 3, 1], [1, 3, 2, 4], [4, 2, 5|...], [2, 4|...], [5|...], [...|...]].

```

### `getBoxes/4 (+Sudoku, +BoxWidth, +BoxHeight, -Out)`
- Checks the dimensions of desired boxes and the input sudoku board itself.
- The board must be square, must fit exact number of same size boxes and each box must be the same size as all the rows and columns of the board (needed for proper Sudoku solving).
- Returns the return value of getBoxes_/4.

```prolog

?- getBoxes([[a,b,c],[d,e,f]],3,1,Out).
false.

?- getBoxes([[a,b,c],[d,e,f],[g,h,i]],2,2,Out).
false.

% for correct examples see getBoxes_/6 above.
```

### `getProblem/4 (+BoxHeight, +BoxWidth, +Rows, -Out)`
- Given dimensions of boxes and Sudoku board as a list of rows, getProblem/4 returns list of lists of variables, which should conform the allDifferent constraint (rows, columns and boxes).
- These areas are sharing the same set of variables, unification in one "area" results in the value appearing 
in all the other areas containing this variable.
```prolog

?- getProblem(2,1,[[a,b],[c,d]],Problem).
Problem = [[a, b], [c, d], [a, c], [b, d], [c, a], [d, b]].

```

## Constraints and Problem Solving 

### `inequal/2 (?X, ?Y)`
Tests whether the two arguments are not identical - fails at two equal numbers or atoms, succeeds at everything else - two (non-identical) variables, variable and an atom etc.
```prolog

?- inequal(a,a).
false.

?- inequal(X,a).
true.

?- inequal(X,Y).
true.

?- inequal(X,X).
false.

```

### `allDifferent/1 (+List)`
Succeeds if all the elements in the list conform inequal/2 (pairwise).
```prolog

?- allDifferent([a,b,_,a]).
false.

?- allDifferent([a,b,c,X]).
true.

?- allDifferent([_,_,_,_]).
true.

```

### `checkConsistency/1 (+Problem)`
Succeeds if all the sublists conform allDifferent/1 - meaning there are no incorrect assignments.
```prolog

?- checkConsistency([[a,b],[X,d]]).
true.

?- checkConsistency([[a,X],[a,a]]).
false.

?- checkConsistency([[a,b],[X,_]]).
true.

```

### `solvePiece/4 (+RemainingVariables, +Domain, +AllVariables, +Problem)`
- Recursivly tries to assign values to all variables. Possible different values for a variable 
are selected using select/3 (introduces nondeterministic behaviour, which naturally allows for branching in the search tree). 
- After finding a correct assignement for a variable, we check whether there are no conflicts in other sublists - this speeds up the whole process a lot, since global inconsistencies are found immediately.
```prolog

?- Problem = [[X,Y,c],[X,b]],
solvePiece([X,Y,c], [a,b,c],[X,Y],Problem).
  Problem = [[a, b, c], [a, b]],
  X = a,
  Y = b .

```

### `solvePiece/3 (+Variables, +Domain, +Problem)`
Finds a correct and consistent assignment for one "area" (in Sudoku row, column or block) or fails, 
if there is no such assignment. \
If there are any values already assigned, they are removed from the domain prior to the recursion itself (using reduceDomain/3) to speed up the process. 
```prolog

?- Problem = [[X,Y,c],[X,b]],
solvePiece([X,Y,c], [a,b,c],Problem).
  Problem = [[a, b, c], [a, b]],
  X = a,
  Y = b .

```

### `getSolution/2 (+Problem, +Domain) `
- Accepts two-dimensional list (of variables, variables in each sublist should be all different from one another) and a list of values (domain), which specifies possible values for the variables.
- The definition of this predicate allows for calling it in all possible directions, +Problem and +Domain are however the only ones giving useful results.
```prolog
?- Problem = [[X,Y,c],[X,b]],
getSolution(Problem,[a,b,c]).
  Problem = [[a, b, c], [a, b]],
  X = a,
  Y = b ;
  false.
```

## Formatting 
### `printLine/2 (+BoxWidth, +Row)`
Prints the Row in a nice formatted manner (printing | every BoxWidth-th character and _ instead of free variables).
```prolog

?- printLine(2,[a,b,c,d]).
| a b | c d |
true.

```
  
### `printSudoku/3 (+Sudoku, +BoxWidth, +BoxHeight)`
Prints the Sudoku board in a nice formatted manner, with lines and spaces dividing boxes.
```prolog
?- printSudoku([[a,b],[c,d]], 1, 1).
| a | b |

| c | d |
true. 
```
   
## "Public" Predicates    

### `solveSudoku/3 (+BoxHeight, +BoxWidth, +Rows)`
- Solves given Sudoku riddle (interpreted as a list of rows) with "boxes" of given size and prints the solution.
- Example:
  - See [README.md](https://github.com/barjin/Prolog-Sudoku#solving-sudoku-riddles).

### `generateSudoku/6 (+BoardWidth, +BoardHeight, +BoxWidth, +BoxHeight, +Difficulty, -Out) `
- Generates and prints a valid Sudoku riddle of given difficulty.
- Basically solves an empty sudoku board (board with no clues) and then removes some of the values.
- Example:
  - See [README.md](https://github.com/barjin/Prolog-Sudoku#generating-sudoku-puzzles).
