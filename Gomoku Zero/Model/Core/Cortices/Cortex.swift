//
//  Cortex.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/20/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

/// The cortex packages basic evaluation functions.
protocol CortexProtocol {
    var delegate: CortexDelegate! {get set}
    var pieces: [[Piece]] {get}
    var identity: Piece {get}
    var zobrist: Zobrist {get}
    var dim: Int {get}
    
    /// Not the most efficient way, will do for now.
    func genSortedMoves() -> [Move]
    
    /// Query hashedDecisionMap to find out the best moves.
    func getSortedMoves() -> [Move]
    
    /// Computes the heuristic value of the node.
    func getHeuristicValue() -> Int
    
    func getMove() -> Move
    
}

var retrievedCount = 0
extension CortexProtocol {
    var pieces: [[Piece]] {return delegate.pieces}
    var identity: Piece {return delegate.identity}
    var dim: Int {return delegate.dim}
    var zobrist: Zobrist {return delegate.zobrist}
    var evaluator: Evaluator {return delegate.evaluator}
    var time: TimeInterval {
        return Date().timeIntervalSince1970
    }
    
    func val(_ threat: Threat) -> Int {
        return evaluator.val(threat)
    }
    
    func eval(for piece: Piece, at co: Coordinate) -> Int {
        return evaluator.evaluate(for: piece, at: co)
    }
    
    
    /**
     Perform a fast simulation on the current game state.
     This is used by ZeroMax to overcome the horizon effect.
     */
    func rollout(depth: Int, policy: BasicCortex) -> Int {
        var heuristicValue = 0
        for i in 0..<depth {
            let move = policy.getMove(for: delegate.curPlayer)
            delegate.put(at: move.co)
            if let _ = hasWinner() {
                heuristicValue = getHeuristicValue()
                revert(num: i + 1)
                return heuristicValue
            }
        }
        heuristicValue = getHeuristicValue()
        revert(num: depth)
        return heuristicValue
    }
    
    func revert(num: Int) {
        for _ in 0..<num {
            delegate.revert()
        }
    }
    
    func hasWinner() -> Piece? {
        let score = threatCoupledHeuristic()
        if abs(score) >= Evaluator.win {
            return score > 0 ? .black : .white
        }
        return nil
    }
    
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
                let bScore = evaluator.evaluate(for: .black, at: co)
                let wScore = evaluator.evaluate(for: .white, at: co)
                // Enemy's strategic positions are also our strategic positions.
                let score = bScore + wScore
                let move = (co, score)
                sortedMoves.append(move)
            }
        }
        
        // Sort by descending order.
        return sortedMoves.sorted {$0.score > $1.score}
    }
    
    /**
     After a new move is made, mark coordinates that need to be updated as nil.
     - Parameter map: 2D matrix containing coordinates to be marked as outdated
     - Parameter co: The coordinate at which the most recent change is made
     */
    public func invalidate<T>(_ map: inout [[Optional<T>]], at co: Coordinate) {
        for i in -1...1 {
            for q in -1...1 {
                if i == 0 && q == 0 {
                    continue
                }
                var c = (col: co.col + i, row: co.row + q)
                var empty = 0
                var anchor: Piece? = nil
                loop: while isValid(c) {
                    let piece = zobrist.get(c)
                    switch piece {
                    case .none:
                        if empty > 1 {
                            break loop
                        } else {
                            empty += 1
                        }
                    default:
                        if anchor == nil {
                            anchor = piece
                        } else if piece != anchor! {
                            break
                        }
                        empty = 0
                    }
                    map[c.row][c.col] = nil
                    c.col += i
                    c.row += q
                }
            }
        }
    }
    
    /**
     If cached moves exist for current game state, moves are retrieved from hash;
     otherwise, sorted moves are generated and hashed.
     - Returns: all possible moves sorted in order of decreasing threat potential
     */
    public func getSortedMoves() -> [Move] {
        if let moves = Zobrist.orderedMovesHash[zobrist] {
            return moves
        } else {
            let moves = genSortedMoves()
            zobrist.update(.orderedMoves(moves))
            return moves
        }
    }
    
    func getHeuristicValue(for player: Piece) -> Int {
        var score = 0
        
        if let retrieved = Zobrist.heuristicHash[zobrist] {
            retrievedCount += 1
            score = retrieved
        } else {
            score = threatCoupledHeuristic()
            zobrist.update(.heuristic(score))
        }
        
        return player == .black ? score : -score
    }
    
    /**
     Generates a heuristic score by summing up threats of white
     and black pieces on the board. This heuristic eval. strategy is
     based on zero-sum principle.
     - Returns: heuristic score based on black's point of view.
     */
    func threatCoupledHeuristic() -> Int {
        var scoreMap = [[Int?]](repeating: [Int?](repeating: nil, count: dim), count: dim)
        var prevScoreMap: [[Int?]]? = nil
        
        func invalidate(_ map: inout [[Int?]], at co: Coordinate) {
            let dirs = [(0, 1),(1, 0),(1, 1),(-1, -1),(-1, 1),(1, -1),(-1, 0),(0, -1)]
            dirs.forEach { dir in
                var co = co
                while isValid(co) {
                    map[co.row][co.col] = nil
                    co.col += dir.0
                    co.row += dir.1
                }
            }
        }
        
        if let co = delegate.revert() {
            if var retrieved = Zobrist.scoreMap[zobrist] {
                invalidate(&retrieved, at: co)
                prevScoreMap = retrieved
            }
            delegate.put(at: co)
        }
        
        var zeroSumScore = 0
        delegate.zobrist.matrix.enumerated().forEach { (r, row) in
            for (c, piece) in row.enumerated() {
                if piece == .none {
                    continue
                }
                if let oldScore = prevScoreMap?[r][c] {
                    scoreMap[r][c] = oldScore
                    zeroSumScore += oldScore
                } else {
                    let co = (col: c, row: r)
                    var score = evaluator.evaluate(for: piece, at: co)
                    score *= piece == .black ? 1 : -1
                    scoreMap[r][c] = score
                    zeroSumScore += score
                }
            }
        }
        
        zobrist.update(.scoreMap(scoreMap))
        
        return zeroSumScore
    }
    
    func getHeuristicValue() -> Int {
        return getHeuristicValue(for: identity)
    }
    
    func isValid(_ c: Coordinate) -> Bool {
        return c.col >= 0 && c.col < dim && c.row >= 0 && c.row < dim
    }
}


protocol CortexDelegate {
    var activeCoordinates: [Coordinate] {get}
    var pieces: [[Piece]] {get}
    var identity: Piece {get}
    var zobrist: Zobrist {get}
    var evaluator: Evaluator {get}
    var dim: Int {get}
    var curPlayer: Piece {get}
    var asyncedQueue: DispatchQueue {get}
    var strategy: Strategy {get}
    var duration: TimeInterval {get}
    var timeout: Bool {get}
    func put(at co: Coordinate)
    @discardableResult
    func revert() -> Coordinate?
}

class BasicCortex: CortexProtocol {
    var delegate: CortexDelegate!
    
    init(_ delegate: CortexDelegate?) {
        self.delegate = delegate
    }
    
    convenience init() {
        self.init(nil)
    }
    
    /**
     Add an insignificant random weight to the scores to break apart ties.
     */
    func differentiate(_ cands: [Move], maxWeight: Int) -> [Move] {
        return cands.map {(co: $0.co, score: $0.score + Int.random(in: 0..<maxWeight))}
    }
    
    func getMove(for player: Piece) -> Move {
        var moves = [Move]()
        for co in delegate.activeCoordinates {
            let myScore = evaluator.evaluate(for: player, at: co)
            let yourScore = evaluator.evaluate(for: player.next(), at: co)
            if myScore > Evaluator.win {
                return (co, myScore)
            }
            let score = myScore + yourScore
            let move = (co, score)
            moves.append(move)
        }
        moves.sort{$0.score > $1.score}
        
        if moves.count == 0 {
            // ZeroPlus is out of moves...
            return ((-1, -1), 0)
        }
        
        if delegate.strategy.randomizedSelection {
            moves = differentiate(moves, maxWeight: 10).sorted{$0.score > $1.score}
        }
        
        return moves[0]
    }
    
    func getMove() -> Move {
        return getMove(for: identity)
    }
}

protocol TimeLimitedSearchProtocol {
    var searchCancelledInProgress: Bool {get}
}
