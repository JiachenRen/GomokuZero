#  ![alt text](https://github.com/JiachenRen/gomoku-zero-plus/blob/master/Gomoku%20Zero%20macOS/Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128.png "Zero + App Icon") Zero +
Zero+ is an AI for Gomoku, also known as Five in a Row, a popular board game that is played on the same board as Go. For the iOS version (less powerful), see [Gomoku Grandmaster](https://github.com/JiachenRen/gomoku-grandmaster)

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

There is still another optimization that could be done for the generation of sorted moves. In Gomoku, once a piece is put in place, it would remain there for the rest of the game. Therefore, each successive game state differs from the previous one only by the addition of a new piece. 

Let's first look at the computation of heuristic score. Since the overall heuristic score for a specific game state is generated by identifying existing threats for both players, the heuristic score of each successive game state could be computed by coupling the threats identified in the previous game state that are unaffected by the addition of the new piece with the new threats that emerges due to the addition of the new piece. Since the implementation is similar to that of `genSortedMoves()`, the code is not shown here. 

The generation of sorted moves could be optimized using the same technique mentioned above; the difference is that this time we look at the empty coordinates that are affected rather than the existing threats themselves. Once the initial array of sorted moves are generated, they are stored in `orderedMovesHash` with the key being the current game state. Then, in the successive game state, the moves for the previous game state are extracted and assorted into a 2D matrix matching the dimension of the board. 
```swift
var scoreMap = [[Int?]](repeating: [Int?](repeating: nil, count: dim), count: dim)
moves.forEach{(co, score) in scoreMap[co.row][co.col] = score}
```
Note that due to the addition of a new piece in the current game state, not all of these moves are reusable; for this reason, we need to mark the moves affected as invalid. 
```swift
invalidate(&scoreMap, at: co)
```
At this point, we have a `scoreMap` that retains the scores of moves from the previous game state that are reusable in the current game state. All we need to do now is to compute new moves and combine them with the existing ones in the score map. Putting these ideas together, we arrive at the following segment of code:
```swift
/**
 Generate moves and sort them in decreasing order of threat potential.
 After the initial moves are generated, most of these older ones are reused
 by later game states. With every advance in game state, the older moves that
 horizontally, vertically, or diagnolly align to the new coordinate are invalidated;
 their scores are updated and carried on to the next game state, and so on.
 This allows a significant speed-up.

 - Returns: all possible moves sorted in descending order of threat potential.
 */
func genSortedMoves() -> [Move] {
    var sortedMoves = [Move]()
    var scoreMap = [[Int?]](repeating: [Int?](repeating: nil, count: dim), count: dim)

    // Revert to previous game state if it exists.
    if let co = delegate.revert() {
        // Extract the calculated moves from that game state.
        if let moves = Zobrist.orderedMovesHash[zobrist] {
            // Restore to current game state.
            delegate.put(at: co)
            moves.forEach{(co, score) in scoreMap[co.row][co.col] = score}
            // Invalidate old moves that are affected by the difference b/w current game state and the old game state.
            invalidate(&scoreMap, at: co)
        } else {
            delegate.put(at: co)
        }
    }

    // Only look at coordinates that are relevant, i.e. in the same 3 x 3 matrix with an adjacent piece.
    delegate.activeCoordinates.forEach { co in
        if let score = scoreMap[co.row][co.col] {
            sortedMoves.append((co, score))
        } else {
            let bScore = eval(for: .black, at: co)
            let wScore = eval(for: .white, at: co)
            // Enemy's strategic positions are also our strategic positions.
            let score = bScore + wScore
            let move = (co, score)
            sortedMoves.append(move)
        }
    }

    // Sort by descending order.
    return sortedMoves.sorted {$0.score > $1.score}
}
```

### Sequence & Threat Types
The `ThreatEvaluator` works by linearizing a certain position on the 2D board into 1D arrays called `Sequence`. For example, this is what the linearization of the coordinate `(6, 7)` looks like:
![alt text](https://github.com/JiachenRen/gomoku-zero-plus/blob/master/Gomoku%20Zero%20macOS/Resources/Screenshots/linearization.png "Board 15 x 15")
Horizontally, we have `* o o o o - * * *`, vertically, we have `o o * * - o o o *`, diagonally (top left to bottom right), we have `o * *`, and diagonally from bottom left to top right, we have `o * - o o`.

The linearization of 2D patterns into 1D sequences offers a huge advantage - rather than having to develop an algorithm that evaluates linear patterns for threats that could be very complex, a simpler general algorithm could be used to categorize each sequence, let it be horizontal, vertical, or diagonal (since it does not matter in the end), into `Threat` types. There are several threat types, and each is assigned a specific score. In Zero +, the values are assigned intuitively:
```swift
var weights: Dictionary<Threat, Int> = [
    .five: Int(1E15),
    .straightFour: Int(1E5),
    .straightPokedFour: Int(1E4),
    .blockedFour: Int(1E4),
    .blockedPokedFour: Int(1E4),
    .straightThree: Int(5E3),
    .straightPokedThree: Int(5E3),
    .blockedThree: 1670,
    .blockedPokedThree: 1670,
    .straightTwo: 1500,
    .straightPokedTwo: 1500,
    .blockedTwo: 500,
    .blockedPokedTwo: 300,
    .none: 0
]
```
Note that these arbitrary could be assigned by the program itself. In order to do so, the algorithm has to play against itself many times to figure out the optimal weights. A neural network is perhaps best suited for this task. This is left to be done in future projects. In Zero+, the weights are approximated using a simpler but quite effective algorithm based on mutation and evolution. To find out more about the implementation, refer to **Self-Play** section. 

Once the categorizing of a sequence is done, the result is stored into a map such that when the same linear sequence is encountered later, the threat type is directly extracted from the map rather than resolved by running it through the identification algorithm all over again. This might not seem like much, but in practice it offers a **30% speed-up**.

### Iterative Deepening
For algorithms like minimax that resemble [brute-force search](https://en.wikipedia.org/wiki/Brute-force_search) when not optimized, increasing the branching factor or search depth exponentially increases the the amount of calculation. In practice, minimax can only reach a very shallow depth given limited time, even with alpha-beta pruning and various other hashing algorithms.

To address this issue, we need to take advantage of multiple cores and utilize all computational power at hand. To give an overview, Zero+ uses iterative deepening to concurrently calculate each depth on a separate thread. The threads are progressively deeper, i.e. the first thread searches up to depth = 2, the 2nd searches up to depth = 4, and so on. Note that only even depth are searched, this is because searching odd depths would cause heuristic evaluation to bias toward the current player. We will discuss this in later sections.

With iterative deepening, the time growth with each increment of depth is no longer exponential - since all threads have [synchronized](https://en.wikipedia.org/wiki/Synchronization_(computer_science)) access to shared hash maps (heuristic, ordered moves, sequence types, etc.), the results of the computations done by shallower threads are re-used by threads that carry out deeper, more complex calculations.


## Self-Play
In order to figure out the optimal weight assignment for each threat type, Zero+ plays against itself. This is currently a work in progress, but starting with zero knowlege about the game except the rules, the algorithm is able to converge toward a reasonable weight assignment given enough time. 

Refer to [here](https://github.com/JiachenRen/gomoku-zero-plus/blob/master/GZeroCommandLine/main.swift) for complete implementation.

To spawn a customized looped skirmish, use the **Zero+ Console**. The short-cut for opening the console is `⌃⇧C` (Control-Shift-C). Make sure that `Looped` is checked. You can optionally save the skirmishes to a designated location. To generate stats from saved skirmishes, click `Generate Stats`. 

![alt text](https://github.com/JiachenRen/gomoku-zero-plus/blob/master/Gomoku%20Zero%20macOS/Resources/Screenshots/console.png "Console Screenshot")

The following .gif shows a looped play of two heuristic AIs happening in real time:

![alt text](https://github.com/JiachenRen/gomoku-zero-plus/blob/master/Gomoku%20Zero%20macOS/Resources/Screenshots/self-play.gif "self-play.gif")

One of the cool features proprietary to Zero+ is the visualization of the AI. The visualization offers a peek into the inner-workings of the algorithm (i.e. what it is doing, either updating the active map or performing simulations) in real time. The following is a snap-shot of visualization of ZeroMax playing against MCTS. Note that visualization would be different for different algorithms since they would be doing different things!

To enable visualization, make sure the check box is checked in the console. (Alternatively, use the short cut `⌃⌥A` (Control-Option-A)).

![alt text](https://github.com/JiachenRen/gomoku-zero-plus/blob/master/Gomoku%20Zero%20macOS/Resources/Screenshots/max-vs-mcts.gif)
