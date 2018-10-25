#  ![alt text](https://github.com/JiachenRen/gomoku-zero-plus/blob/master/Gomoku%20Zero/Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128.png "Zero + App Icon") Zero +
My fifth attemp at building an unbeatable gomoku AI!

## Story of Creation
Zero+ is an OSX application built with Swift 4 that is optimized all the way to the end. Having read countless papers and accumulated experience with various optimization techniques including multi-threading and hashing, I flexed every nerve in my brain and fingers to equip Zero+ with an optimal algorithm. Based on a depth and time limited minimax algorithm that performs threat space search, Zero+ linearizes the 2D matrix of the board and extrapolates the best defensives and offensive moves that feed into minimax by using an original algorithm that evaluates and hashes linear patterns to achieve significant speedup. First, a 2D map of active coordinates is updated with each increment of depth and changes made to the history stack, and each active coordinate is evaluated for threat potential and sorted into an array to serve as candidates. Then, a slightly modified Zorbist transpositional hashtable coupled with heuristics evaluation is used at every leaf node to achieve further speedup. All modern computers are equipped with multiple cores, and Zero+ uses iterative deepening to bring out its full potential by calculating each depth concurrently on a separate thread with each thread having synchronized access to the shared hash maps. It is, indeed, considered the pinnacle of my creation.

## Algorithms

### Evaluation
#### Heuristic
#### Threat

### Minimax w/ Alpha-beta Pruning 

#### Hashing
Many well-known hashing techniques are used to optimize the `minimax` algorithm. One of the most important hash tables involved is a `Zobrist` transposition map. 

##### Zobrist
First, a matrix matching the dimension of the board containing random 64-bit integer pairs is generated. Since there are only two colors involved in gomoku, i.e. black and white, each slot in the matrix correspond to 2 randomly generated integer. This table is shared across multiple concurrent AIs. At the beginning of each iteration of computation, the hash value for the board is computed once. 
```swift
private func computeInitialHash() -> Int {
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
        return hash
    }
```
This offers a huge advantage - once the initial hash value is computed, the expense of calculating the hash for successive game states down the decision tree is almost neglegible. A simple xor operation is required to update the hash value of the board:
```swift
hashValue ^= Zobrist.tables[dim]![co.row][co.col][piece == .black ? 0 : 1]
```
##### Ordered Moves
##### Sequence

#### Iterative Deepening

### NegaScout (Principal Variation Search)

### Monte Carlo Tree Search

### ZeroMax - An attempt to overcome horizon effect




## Features Snapshot
![alt text](https://github.com/JiachenRen/gomoku-zero-plus/blob/master/Gomoku%20Zero/Resources/Screenshots/all-features.png "Features Snapshot") 
