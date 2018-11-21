#  ![alt text](https://github.com/JiachenRen/gomoku-zero-plus/blob/master/Gomoku%20Zero/Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128.png "Zero + App Icon") Zero +
Zero+ is an OSX application built with Swift 4. Based multiple conventional algorithms that performs threat space search, Zero+ linearizes the 2D matrix of the board and extrapolates the best defensive and offensive moves that feed into minimax by using an original algorithm that evaluates and hashes linear patterns to achieve significant speedup. First, a 2D map of active coordinates is updated with each increment of depth and changes made to the history stack, and each active coordinate is evaluated for threat potential and sorted into an array to serve as candidates. Then, a slightly modified Zobrist transposition table coupled with heuristics evaluation is used at every leaf node to achieve further speedup. 

## Algorithms & Data Structures Overview
- Heuristic Evaluation
- Threat Space Search
    - Minimax w/ Alpha-beta Pruning 
        - ZeroMax - an attempt to overcome horizon effect
        - NegaScout (Principal Variation Search)
    - Monte Carlo Tree Search


## Optimizations
### Hashing
Many well-known hashing techniques are used to optimize the `minimax` algorithm. One of the most important hash tables involved is a `Zobrist` transposition map. 

### Zobrist Transposition Table
#### _Overview_
Since Zero+ supports multiple board dimensions other than the traditional `19 x 19` and `15 x 15`, a zobrist table containing random integer values assigned for each coordinate and color needs to be created every time when the user selects a new board dimension. Once created, the hash table is retained for the remaining of runtime. 
```swift
typealias ZobristTable = [[[Int]]]
var tables = Dictionary<Int,ZobristTable>()
```
This way, we establish a consistent source of referral when computing hash values for game states of different dimensions; using completely different random tables for each dimension also minimizes hash collision when multiple concurrent games are running (since they all use the same hash map for storing and retrieving heuristic scores of game states). The following segment shows the declaration of the shared heuristic score hash map:
```swift
var heuristicHash = Dictionary<Zobrist, Int>()
```
#### _Hash Value Computation_
First, in order to compute the hash value of a game state, i.e. board matrix, a matrix matching the dimension of the game state containing random 64-bit integer pairs is generated. 
```swift
var table = [[[Int]]]()
for _ in 0..<dim {
    var col = [[Int]]()
    for _ in 0..<dim {
        var piece = [Int]()
        for _ in 0...1 {
            let rand = Int.random(in: 0..<Int.max)
            piece.append(rand)
        }
        col.append(piece)
    }
    table.append(col)
}
```
Since there are only two colors involved in gomoku, i.e. black and white, each slot in the matrix correspond to 2 randomly generated integer. This table is shared across multiple concurrent threads. At the beginning of each iteration of computation, the hash value for the board is computed once. 
```swift
var hash = 0
for i in 0..<dim {
    for q in 0..<dim {
        let piece = matrix[i][q]
        switch piece {
        case .none: continue
        case .black: hash ^= Zobrist.tables[dim]![i][q][0]
        case .white: hash ^= Zobrist.tables[dim]![i][q][1]
        }
    }
}
```
This offers a huge advantage - once the initial hash value is computed, the expense of calculating the hash for successive game states down the decision tree is almost neglegible. A simple `XOR` operation is required to update the hash value of the board:
```swift
hashValue ^= Zobrist.tables[dim]![co.row][co.col][piece == .black ? 0 : 1]
```
### Ordered Moves Cache
The efficiency of the minimax algorithm depends on the quality of the supplied candidates. Ideally, the candidates, i.e. selected moves with threat potential, should be searched in an order such that the ones with maximum threat potential are evaluated first. This way, alpha-beta pruning is able to cut unwanted branches and avoid search of bad moves at an earlier stage, resulting in speed-up (In the case of Zero +, a **50% speed-up**). In practice, the candidates are supplied by `Evaluator`. The evaluator looks at active coordinates on the board and selects candidates that can cause the most threat to the opponent. The computation power required for this operation, however, grows exponentially as the branching factor (or breadth) increases. Therefore, to avoid searching the same game state twice for candidates by multiple concurrent threads, a `Dictionary`, Swift's equivalent of `HashMap`, is used.
```swift
orderedMovesHash = Dictionary<Zobrist, [Move]>()
```
Note that updates to the map are done on a different thread. Collections in Swift are not thread-safe - that is, when two different threads are reading and writing to the same hash map at the same time, we can get some really wacky behavior (in most cases the application simply quits). To address this issue, all modifications to be made to the hash map are delegated to a single synchronized (serial) thread. The extraction of candidates, however, could be done asynchronously and is in fact more efficient this way. 
```swift
public func getSortedMoves() -> [Move] {
    if let moves = Zobrist.orderedMovesHash[zobrist] {
        return moves
    } else {
        let moves = genSortedMoves()
        zobrist.update(.orderedMoves(moves))
        return moves
    }
}
```
Another thing that worth pointing out is how the array of candidates is sorted. There is an old saying that applies really well to the game of go:
> "The positions that are vital to the enemy are also vital positions to me"

Not surprisingly, this principle also applies very well to Gomoku, since Gomoku, like Go, is also a [zero-sum game](https://en.wikipedia.org/wiki/Zero-sum_game) where each participant's gain or loss of advantage is exactly balanced by the losses or gains of advantage of the other participant.

To implement this principle, the threat potential of a certain position is evaluated twice, once for black, and another for white. The holistic score of this position, that is, the score assigned to it taken into account both defense and offense, is then determined by summing up the threat potential for black and white. The following segment demonstrates how this is done programmatically: 
```swift
let bScore = eval(for: .black, at: co)
let wScore = eval(for: .white, at: co)
// Enemy's strategic positions are also our strategic positions.
let score = bScore + wScore
let move = (co, score)
sortedMoves.append(move)
```

### Sequence & Threat Types
The `ThreatEvaluator` works by linearizing a certain position on the 2D board into 1D arrays called `Sequence`. For example, this is what the linearization of the coordinate `(6, 7)` looks like:
```css
- - - - - - - - - - - - - - - 
- - - - - - - - - - - - - - - 
- - - - - - - - - - - - - - - 
- - - - - * o - - - - - - - - 
- - - o * * o - - - - - - - - 
- - - * * o * - o - - - - - - 
- - o o * * * o o - - - - - - 
- * o o o o E * * * - - - - - 
- - - - - * o - * - - - - - - 
- - - - o * o - - - - - - - - 
- - - - - - o - - - - - - - - 
- - - - - - * - - - - - - - - 
- - - - - - - - - - - - - - - 
- - - - - - - - - - - - - - - 
- - - - - - - - - - - - - - - 
```
Horizontally, we have 
```css
* o o o o - * * *
```
Vertically, we have 
```css
o o * * - o o o *
```
Diagonally (top left to bottom right), we have
```css
o * *
```
Diagonally (bottom left to top right), we have
```css
o * - o o
```
The linearization of 2D patterns into 1D sequences offers a huge advantage - rather than having to develop an algorithm that evaluates linear patterns for threats that could be very complex, a simpler general algorithm could be used to categorize each sequence, let it be horizontal, vertical, or diagonal (since it does not matter in the end), into `Threat` types. There are several threat types, and each is assigned a specific score. In Zero +, the values are assigned intuitively; nevertheless, these arbitrary values should be assigned by the program itself. In order to do so, the algorithm has to play against itself many times to figure out the optimal scores to be assigned to the threat types. To find out more about self-play capabilities, refer to **Self-Play** section. Once the categorizing of a sequence is done, the result is stored into a map such that when the same linear sequence is encountered later, the threat type is directly extracted from the map rather than resolved by running it through the identification algorithm all over again. This might not seem like much, but in practice it offers a **30% speed-up**, which is way more than what I expected!

### Iterative Deepening
For algorithms like minimax that resemble [brute-force search](https://en.wikipedia.org/wiki/Brute-force_search) when not optimized, increasing the branching factor or search depth exponentially increases the the amount of calculation. In practice, minimax can only reach a very shallow depth given limited time, even with alpha-beta pruning and various other hashing algorithms.

To address this issue, we need to take advantage of multiple cores and utilize all computational power at hand. To give an overview, Zero+ uses iterative deepening to concurrently calculate each depth on a separate thread. The threads are progressively deeper, i.e. the first thread searches up to depth = 2, the 2nd searches up to depth = 4, and so on. Note that only even depth are searched, this is because searching odd depths would cause heuristic evaluation to bias toward the current player. We will discuss this in later sections.

With iterative deepening, the time growth with each increment of depth is no longer exponential - since all threads have synchronized access to shared hash maps (heuristic, ordered moves, sequence types, etc.), the results of the computations done by shallower threads are re-used by threads that carry out deeper, more complex calculations.





## Features Snapshot
![alt text](https://github.com/JiachenRen/gomoku-zero-plus/blob/master/Gomoku%20Zero/Resources/Screenshots/all-features.png "Features Snapshot") 
