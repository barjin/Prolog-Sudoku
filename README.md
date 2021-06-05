# Prolog Sudoku
Yet another Sudoku solver written in Prolog. This time without clpfd!

## How to use
This program has two main usecases:
### Solving Sudoku Riddles
  -  Use the predicate `solveSudoku(BoxHeight, BoxWidth, Sudoku)`, where BoxHeight and BoxWidth are integers specifying height and width of the boxes (3x3 in standard 9x9 sudoku) and Sudoku is a list of Rows (lists with integers as clues and free variables as empty cells).
```prolog
?- Sudoku = [
       [5,3,_,_,7,_,_,_,_],
       [6,_,_,1,9,5,_,_,_],
       [_,9,8,_,_,_,_,6,_],
       [8,_,_,_,6,_,_,_,3],
       [4,_,_,8,_,3,_,_,1],
       [7,_,_,_,2,_,_,_,6],
       [_,6,_,_,_,_,2,8,_],
       [_,_,_,4,1,9,_,_,5],
       [_,_,_,_,8,_,_,7,9]
], solveSudoku(3,3,Sudoku).
Solution: 

| 5 3 4 | 6 7 8 | 9 1 2 |
| 6 7 2 | 1 9 5 | 3 4 8 |
| 1 9 8 | 3 4 2 | 5 6 7 |

| 8 5 9 | 7 6 1 | 4 2 3 |
| 4 2 6 | 8 5 3 | 7 9 1 |
| 7 1 3 | 9 2 4 | 8 5 6 |

| 9 6 1 | 5 3 7 | 2 8 4 |
| 2 8 7 | 4 1 9 | 6 3 5 |
| 3 4 5 | 2 8 6 | 1 7 9 |
L = [[5, 3, 4, 6, 7, 8, 9, 1|...], [6, 7, 2, 1, 9, 5, 3|...], [1, 9, 8, 3, 4, 2|...], [8, 5, 9, 7, 6|...], [4, 2, 6, 8|...], [7, 1, 3|...], [9, 6|...], [2|...], [...|...]] ;
false.
  ```
  
### Generating Sudoku Puzzles
  -  Use the predicate `generateSudoku(BoardWidth, BoardHeight, BoxWidth, BoxHeight, Difficulty, Out)`, where `BoardWidth` and `BoardHeight` specify the board dimensions, `BoxWidth` and `BoxHeight` specify the box dimensions (see above). 
  -  `Difficulty` is float `(0.0 - 1.0)` specifying the desired difficulty of the puzzle (`0` is easiest, `1` is hardest). Both extreme values give absurd results, something in range `0.4 - 0.6` works best).
```prolog
?- generateSudoku(6,6,3,2,0.4,_).
Solution:

| 6 3 | 5 4 | 1 2 |
| 5 4 | 1 2 | 6 3 |
| 1 2 | 6 3 | 5 4 |

| 3 6 | 4 5 | 2 1 |
| 4 5 | 2 1 | 3 6 |
| 2 1 | 3 6 | 4 5 |
Sudoku:

| 6 3 | _ 4 | 1 _ |
| 5 4 | _ _ | _ 3 |
| 1 2 | _ 3 | _ _ |

| 3 _ | _ _ | 2 1 |
| 4 5 | 2 _ | 3 _ |
| 2 1 | _ 6 | 4 _ |
true.
```
## How does it work?
- Check out [predicates.md](https://github.com/barjin/Prolog-Sudoku/blob/main/predicates.md), where all the used predicates are described, including example usage.

## Test Data
- Test data can be found in [test_data.md](https://github.com/barjin/Prolog-Sudoku/blob/main/test_data.md).

## Legal
Made by Jindřich Bär as a semestral work for [NPRG005](https://is.cuni.cz/studium/predmety/index.php?tid=&do=predmet&kod=NPRG005&skr=2020&fak=11320) at [MFF UK](https://www.mff.cuni.cz/), Prague, 2021.
