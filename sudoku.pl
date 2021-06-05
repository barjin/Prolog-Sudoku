%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Sudoku Solver and Generator   %
% ------------------------------- %
%          Jindřich Bär           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%
% List Operations %
%%%%%%%%%%%%%%%%%%%

% removeItem/3 (+Item, +List, -Out)
%
%   Deterministic wrapper for select/3 (removes only the first occurence of Item from List).
%   If Item is not found, the original list is returned.
%
removeItem(Item,List,Out) :-
    select(Item,List,Out), !.

removeItem(_,List,List).

% reduceDomain/3 (+Vars, +Domain, -Out)
%
%   Scans +Vars, if there is an assigned value, it gets removed from the Domain.
%
reduceDomain(_,[],[]) :- !.
reduceDomain([],Domain,Domain) :- !.

reduceDomain([H|T],Domain,Out) :- 
    nonvar(H), removeItem(H,Domain,DomainWithoutValue), reduceDomain(T,DomainWithoutValue,Out), !.

reduceDomain([H|T],Domain,Out) :- 
    var(H), reduceDomain(T,Domain,Out).

% obfuscateLine/3 (+Probability, +InLine, -OutLine)
%
%   Given a probability threshold, this predicate recursively replaces random items in the list with free variables.
%
obfuscateLine(_, [], []).

obfuscateLine(Diff, [H|T], [H|ObfuscatedRest]) :-
    random(X), X > Diff, obfuscateLine(Diff,T,ObfuscatedRest).

obfuscateLine(Diff, [_|T], [_|ObfuscatedRest]) :-
    obfuscateLine(Diff,T,ObfuscatedRest).

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sudoku Board Operations %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% getBoard/3 (+Rows, +Cols, -Matrix)
%
% Generates matrix of size (Rows x Cols) filled with free variables.
%
getBoard(0,_,[]) :- !.
getBoard(Rows, Cols, [H|T]) :- length(H, Cols), NewRows is Rows-1, getBoard(NewRows,Cols,T).

% peelLeft/3 (+Matrix, -Col, -RestOfMatrix)
% 
% Extracts the first elements of all rows and returns a list of these.
% Also returns a list of tails of the original rows.
%
peelLeft([], [], []).
peelLeft([[H|R]|T], [H|RestOfColumn], [R|RestOfRests]) :- peelLeft(T,RestOfColumn,RestOfRests).

% transpose/2 (+ListOfRows, -ListOfCols)
%
% Transposes the input matrix represented as a list of rows. Predicate is not symmetrical!
%
transpose([[]|_],[]).
transpose(Matrix, [H|T]) :- peelLeft(Matrix,H,RestOfMatrix), transpose(RestOfMatrix,T).

% getBoxStack/6 (+Sudoku, +BoxWidth, +BoxHeight, +Buffer, -BoxStack, -RestOfSudoku)
%
%   getBoxStack/6 returns a list of boxes from the leftmost stack of boxes of the Sudoku board.
%   Also returns the rest of the board (as a list of rows).
%
%   Predicate recursively peels the leftmost parts of rows (of length BoxWidth) and stores them into Buffer.
%   When the desired number of rows (BoxHeight) has been processed, buffer is cleared and stored into the Out list.
%
getBoxStack([],_,_,Buffer,[Buffer],[]).

getBoxStack(Sudoku,Width,Height,Buffer,[Buffer|RestOfBoxes],RemainingRows):-
    SizeOfBox is Width * Height,    % When Buffer is filled, it gets appended to the Out list and the Buffer is cleared for next step.
    length(Buffer,SizeOfBox),
    getBoxStack(Sudoku,Width,Height,[],RestOfBoxes,RemainingRows), !.

getBoxStack([CurrentRow|Frontier],Width,Height,OldBuffer,Boxes,[RestOfCurrentRow|RemainingRows]):-
    length(CurrentStackSlice, Width),
    append(CurrentStackSlice, RestOfCurrentRow, CurrentRow),
    append(CurrentStackSlice,OldBuffer,NewBuffer),
    getBoxStack(Frontier,Width,Height,NewBuffer,Boxes,RemainingRows).

% getBoxes_/4 (+Sudoku, +BoxWidth, +BoxHeight, -Out) (please, notice the underscore_ in the name)
%
%   Recursively peels the left side stack of boxes from the +Sudoku board until none are left.
%
getBoxes_([],_,_,[]).
getBoxes_([[]|_],_,_,[]).

getBoxes_(Sudoku, Width, Height, Out) :-
    getBoxStack(Sudoku,Width,Height,[],Stack,Rest),
    append(Stack,OtherBoxes,Out),
    getBoxes_(Rest,Width,Height,OtherBoxes).

% getBoxes/4 (+Sudoku, +BoxWidth, +BoxHeight, -Out)
%
%   Checks the dimensions of desired boxes and the input sudoku board itself.
%   The board must be square, must fit exact number of same size boxes and each box must be 
%   the same size as all the rows and columns of the board (needed for proper Sudoku solving).
%
%   Returns the return value of getBoxes_/4.
%
getBoxes([H|T], BoxWidth, BoxHeight, Out) :- 
        length([H|T], MatrixSize), 
        length(H, MatrixSize), 
        Y is (MatrixSize mod BoxHeight),
        X is (MatrixSize mod BoxWidth),
        X = Y, Y = 0, BoxWidth \= 0, BoxHeight \= 0,
        MatrixSize is BoxWidth * BoxHeight,
        getBoxes_([H|T], BoxWidth, BoxHeight, Out).

% getProblem/4 (+BoxHeight, +BoxWidth, +Rows, -Out)
%
%   Given dimensions of boxes and Sudoku board as a list of rows, 
%   getProblem/4 returns list of areas which should conform the allDifferent constraint (rows, columns and boxes).
%       
%   These areas are sharing the same set of variables, unification in one "area" results in the value appearing 
%   in all the other areas containing this variable.

getProblem(H, W, Rows,Out) :-
    transpose(Rows,Cols), getBoxes(Rows,W,H,Boxes), append(Rows,Cols,Temp), append(Temp,Boxes,Out).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constraints and Problem Solving %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% inequal/2 (?X, ?Y)
%
%   Tests whether the two arguments are not identical - fails at two equal numbers or atoms, succeeds at everything else
%       - two (non-identical) variables, variable and an atom etc.
%
inequal(X,Y) :- X \== Y.

% allDifferent/1 (+List)
%
%   Succeeds if all the elements in the list conform inequal/2 (pairwise).
%
allDifferent([]).
allDifferent([X|Xss]) :- maplist(inequal(X), Xss), allDifferent(Xss).

% checkConsistency/1 (+Problem)
%
%   Succeeds if all the sublists conform allDifferent/1 - meaning there are no incorrect assignments.
%
checkConsistency(Problem) :-
    maplist(allDifferent, Problem).

% solvePiece/4 (+RemainingVariables, +Domain, +AllVariables, +Problem)   
%
%   Recursivly tries to assign values to all variables. Possible different values for a variable 
%   are selected using select/3 (introduces nondeterministic behaviour, which naturally allows for branching in the search tree). 
%
%   After finding a correct assignement for a variable, we check whether there are no conflicts in other sublists
%   - this speeds up the whole process a lot, since global inconsistencies are found immediately.
%
% solvePiece/3 (+Variables, +Domain, +Problem)
%
%   Finds a correct and consistent assignment for one "area" (in Sudoku row, column or block) or fails, 
%   if there is no such assignment. If there are any values already assigned, they are removed from the 
%   domain prior to the recursion itself (using reduceDomain/3) to speed up the process. 
%
solvePiece([], _, _, _) :- !.

solvePiece([Item|Rest], Dom, List, Problem) :- 
    nonvar(Item), solvePiece(Rest, Dom, List, Problem).

solvePiece([CurrentVar|Vars], Domain, List, Problem) :- 
        select(CurrentTip, Domain, NewDomain),   % predicate select/3 fails if Domain is empty.
        CurrentVar = CurrentTip,
        checkConsistency(Problem),
        solvePiece(Vars, NewDomain, List, Problem).

solvePiece(Vars,Domain, Problem) :-
    reduceDomain(Vars,Domain,ReducedDomain), 
    solvePiece(Vars, ReducedDomain, Vars, Problem).

% getSolution/2 (+Problem, +Domain) 
% 
% Accepts two-dimensional list (of variables, variables in each sublist should be all different from one another)
% and a list of values (domain), which specifies possible values for the variables.
%
% The definition of this predicate is pure, meaning it can be called in all possible directions,
%   +Problem and +Domain are however the only ones giving useful results.
%
getSolution([],_).
getSolution([H|T],Domain) :- solvePiece(H,Domain,[H|T]), getSolution(T,Domain).


%%%%%%%%%%%%%%
% Formatting %
%%%%%%%%%%%%%%

% printLine/2 (+BoxWidth, +Row)
%   
%   Prints the Row in a nice formatted manner (printing | every BoxWidth-th character and _ instead of free variables).
%   
printLine(_,[]) :- writeln('|').

printLine(BoxWidth, [H|T]) :-
    (
        (length([H|T], RemainingItems),
        Mod is RemainingItems mod BoxWidth,
        Mod = 0,
        write('| ')); 
        true
    ),
    (
        (var(H), write('_ '));
        (nonvar(H), write(H), write(' '))
    ),
    printLine(BoxWidth, T),!.

% printSudoku/3 (+Sudoku, +BoxWidth, +BoxHeight)
%   
%   Prints the Sudoku board in a nice formatted manner (with | and spaces dividing boxes etc.s).
%   
printSudoku([],_,_).

printSudoku([FirstRow|Rest],BoxWidth,BoxHeight) :-
    (
        (length([FirstRow|Rest], RemainingLines),
        Mod is RemainingLines mod BoxHeight,
        Mod = 0,
        writeln('')); 
        true
    ),
    printLine(BoxWidth, FirstRow),
    printSudoku(Rest,BoxWidth,BoxHeight), !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    "Public" Predicates    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% solveSudoku/3 (+BoxHeight, +BoxWidth, +Rows)
%
% Solves given Sudoku riddle (interpreted as a list of rows) with "boxes" of given size and prints the solution.
%
solveSudoku(H,W,Sudoku) :-
    getProblem(H,W,Sudoku,Problem), 
    Nums is H*W, 
    numlist(1,Nums,Domain),

    % Domain gets permutated for better sudoku generation. Permutating the CSP domain does not affect the problem solving process,
    %   however when solving an empty board during the puzzle generation, using the same domain would always result in the same Sudoku puzzles.
    random_permutation(Domain,MixedDomain),

    getSolution(Problem,MixedDomain),
    writeln('Solution: '),
    printSudoku(Sudoku, W, H).

% generateSudoku/6 (+BoardWidth, +BoardHeight, +BoxWidth, +BoxHeight, +Difficulty, -Out) 
%
%   Generates and prints a valid Sudoku riddle of given difficulty.
%
%   Basicaly solves an empty sudoku board (board with no clues) and then removes some of the values.
%
generateSudoku(BoardWidth, BoardHeight, BoxWidth, BoxHeight, Diff, Out) :-
    getBoard(BoardHeight, BoardWidth, Sudoku),
    solveSudoku(BoxWidth, BoxHeight, Sudoku),
    maplist(obfuscateLine(Diff), Sudoku, Out), !,
    writeln('Sudoku: '),
    printSudoku(Out, BoxHeight, BoxWidth).
