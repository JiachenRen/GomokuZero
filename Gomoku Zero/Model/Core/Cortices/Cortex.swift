//
//  Cortex.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/20/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

/// The cortex packages basic evaluation functions.
protocol CortexProtocol: HeuristicDataSource {
    var delegate: CortexDelegate {get}
    var heuristicEvaluator: HeuristicEvaluator {get}
    var pieces: [[Piece]] {get}
    var identity: Piece {get}
    var zobrist: Zobrist {get}
    var dim: Int {get}
    
    /**
     Not the most efficient way, will do for now.
     */
    func genSortedMoves() -> [Move]
    
    /**
     Query hashedDecisionMap to find out the best moves.
     */
    func getSortedMoves(num: Int) -> [Move]
    
    /**
     Computes the heuristic value of the node.
     */
    func getHeuristicValue() -> Int
    
    func getMove() -> Move
    
    func timeout() -> Bool
}

var retrievedCount = 0
extension CortexProtocol {
    var pieces: [[Piece]] {return delegate.pieces}
    var identity: Piece {return delegate.identity}
    var dim: Int {return delegate.dim}
    var zobrist: Zobrist {return delegate.zobrist}
    var time: TimeInterval {
        return Date().timeIntervalSince1970
    }
    
    func timeout() -> Bool {
        return Date().timeIntervalSince1970 - delegate.startTime > delegate.maxThinkingTime
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
        let blackScore = heuristicEvaluator.evaluate(for: .black)
        let whiteScore = heuristicEvaluator.evaluate(for: .white)
        if blackScore > Threat.win || whiteScore > Threat.win {
            return blackScore > whiteScore ? .black : .white
        }
        return nil
    }
    
    func genSortedMoves() -> [Move] {
        var sortedMoves = [Move]()
        var scoreMap = [[Int?]](repeating: [Int?](repeating: nil, count: dim), count: dim)
        
        if let co = delegate.revert() {
            if let moves = Zobrist.orderedMovesHash[zobrist] {
                delegate.put(at: co)
                moves.forEach{(co, score) in scoreMap[co.row][co.col] = score}
                
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
                            scoreMap[c.row][c.col] = nil
                            c.col += i
                            c.row += q
                        }
                    }
                }
                
            } else {
                delegate.put(at: co)
            }
        }
        
        for (i, row) in delegate.activeMap.enumerated() {
            for (q, isActive) in row.enumerated() {
                if isActive {
                    let co = (col: q, row: i)
                    if let score = scoreMap[i][q] {
                        sortedMoves.append((co, score))
                    } else {
                        let bScore = Threat.evaluate(for: .black, at: co, pieces: pieces)
                        let wScore = Threat.evaluate(for: .white, at: co, pieces: pieces)
                        let move = (co, bScore + wScore)
                        sortedMoves.append(move)
                    }
                }
            }
        }
        
        return sortedMoves.sorted {$0.score > $1.score}
    }
    
    func getSortedMoves(num: Int) -> [Move] {
        func finalize(_ moves: [Move]) -> [Move] {
            return [Move](moves.prefix(num))
        }
        if let moves = Zobrist.orderedMovesHash[zobrist] {
            return finalize(moves)
        } else {
            let moves = genSortedMoves()
            
            if ZeroPlus.useOptimizations {
                ZeroPlus.syncedQueue.sync {
                    let newZobrist = Zobrist(zobrist: zobrist)
                    Zobrist.orderedMovesHash[newZobrist] = moves
                }
            }
            return finalize(moves)
        }
    }
    
    func getHeuristicValue(for player: Piece) -> Int {
        var score = 0
        
        if let retrieved = Zobrist.hueristicHash[dim - 1][zobrist] {
            retrievedCount += 1
            score = retrieved
        } else {
            score = threatCoupledHeuristic()
            let newZobrist = Zobrist(zobrist: zobrist)
            if ZeroPlus.useOptimizations {
                ZeroPlus.syncedQueue.sync {
                    Zobrist.hueristicHash[dim - 1][newZobrist] = score
                }
            }
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
            if var retrieved = Zobrist.segregatedHMap[zobrist] {
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
                    var score = Threat.evaluate(for: piece, at: co, pieces: delegate.zobrist.matrix)
                    score *= piece == .black ? 1 : -1
                    scoreMap[r][c] = score
                    zeroSumScore += score
                }
            }
        }
        
        if ZeroPlus.useOptimizations {
            ZeroPlus.syncedQueue.sync {
                let newZobrist = Zobrist(zobrist: zobrist)
                Zobrist.segregatedHMap[newZobrist] = scoreMap
            }
        }
        
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
    var activeMap: [[Bool]] {get}
    var pieces: [[Piece]] {get}
    var identity: Piece {get}
    var zobrist: Zobrist {get}
    var maxThinkingTime: TimeInterval {get}
    var startTime: TimeInterval {get}
    var dim: Int {get}
    var curPlayer: Piece {get}
    var asyncedQueue: DispatchQueue {get}
    var activeMapDiffStack: [[Coordinate]] {get}
    var randomizedSelection: Bool {get}
    func put(at co: Coordinate)
    @discardableResult
    func revert() -> Coordinate?
}

class BasicCortex: CortexProtocol {
    var delegate: CortexDelegate
    
    var heuristicEvaluator = HeuristicEvaluator()
    
    init(_ delegate: CortexDelegate) {
        self.delegate = delegate
        heuristicEvaluator.dataSource = self
    }
    
    /**
     Add an insignificant random weight to the scores to break apart ties.
     */
    func differentiate(_ cands: [Move], maxWeight: Int) -> [Move] {
        return cands.map {(co: $0.co, score: $0.score + Int.random(in: 0..<maxWeight))}
    }
    
    func getMove(for player: Piece) -> Move {
        var moves = genSortedMoves()
        if moves.count == 0 {
            // If ZeroPlus is out of moves...
            return ((-1, -1), 0)
        }
        if delegate.randomizedSelection {
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
