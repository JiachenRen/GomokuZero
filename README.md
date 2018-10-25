#  ![alt text](https://github.com/JiachenRen/gomoku-zero-plus/blob/master/Gomoku%20Zero/Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128.png "Zero + App Icon") Zero +
My fifth attemp at building an unbeatable gomoku AI!

## Story of Creation
Zero+ is an OSX application built with Swift 4 that is optimized all the way to the end. Having read countless papers and accumulated experience with various optimization techniques including multi-threading and hashing, I flexed every nerve in my brain and fingers to equip Zero+ with an optimal algorithm. Based on a depth and time limited minimax algorithm that performs threat space search, Zero+ linearizes the 2D matrix of the board and extrapolates the best defensives and offensive moves that feed into minimax by using an original algorithm that evaluates and hashes linear patterns to achieve significant speedup. First, a 2D map of active coordinates is updated with each increment of depth and changes made to the history stack, and each active coordinate is evaluated for threat potential and sorted into an array to serve as candidates. Then, a slightly modified Zorbist transpositional hashtable coupled with heuristics evaluation is used at every leaf node to achieve further speedup. All modern computers are equipped with multiple cores, and Zero+ uses iterative deepening to bring out its full potential by calculating each depth concurrently on a separate thread with each thread having synchronized access to the shared hash maps. It is, indeed, considered the pinnacle of my creation.

## Algorithms

### Minimax w/ Alpha-beta Pruning 

### NegaScout (Principal Variation Search)

### Monte Carlo Tree Search

### ZeroMax - An attempt to overcome horizon effect

## Optimizations
### Hashing
Many well-known hashing techniques are used to optimize the `minimax` algorithm. One of the most important hash tables involved is a `Zobrist` transposition map. 

### Zobrist Transposition Table
First, a matrix matching the dimension of the board containing random 64-bit integer pairs is generated. 
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
Since there are only two colors involved in gomoku, i.e. black and white, each slot in the matrix correspond to 2 randomly generated integer. This table is shared across multiple concurrent AIs. At the beginning of each iteration of computation, the hash value for the board is computed once. 
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
The efficiency of the minimax algorithm depends on the quality of the supplied candidates. Ideally, the candidates, i.e. selected moves with threat potential, should be searched in an order such that the ones with maximum threat potential are evaluated first. This way, alpha-beta pruning is able to cut unwanted branches and avoid search of bad moves at an earlier stage, resulting in speed-up. In practice, the candidates are supplied by `ThreatEvaluator`. Unlike `HeuristicEvaluator`, which evaluates the heuristic value of the game state without bias, the threat evaluator looks at active coordinates on the board and selects moves that can cause the most threat to the opponent. The computation power required for this operation, however, grows exponentially as the branching factor (or breadth) increases. Therefore, to avoid searching the same game state twice for candidates by multiple concurrent threads, a `Dictionary`, Swift's equivalent of `HashMap`, is used.
```swift
if let retrieved = Zobrist.orderedMovesMap[zobrist] {
    return retrieved
} else {
    let moves = [genSortedMoves(for: .black, num: num), genSortedMoves(for: .white, num: num)]
        .flatMap({$0})
        .sorted(by: {$0.score > $1.score})
    ZeroPlus.syncedQueue.sync {
        Zobrist.orderedMovesMap[Zobrist(zobrist: zobrist)] = moves
    }
    return moves
}
```
Note that updates to the map are done on a different thread. Collections in Swift are not thread-safe - that is, when two different threads are reading and writing to the same hash map at the same time, we can get some really wacky behavior. (In most cases the application simply quits.) To address this issue, all modifications to be made to the hash map are delegated to a single synchronized (serial) thread. The extraction of candidates, however, could be done asynchronously and is in fact more efficient this way. 
### Sequence & Threat Types

## Concurrency
### Iterative Deepening






## Features Snapshot
![alt text](https://github.com/JiachenRen/gomoku-zero-plus/blob/master/Gomoku%20Zero/Resources/Screenshots/all-features.png "Features Snapshot") 
