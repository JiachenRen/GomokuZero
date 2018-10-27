//
//  Cortex.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/20/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

/// The cortex packages basic evaluation functions.
protocol CortexProtocol: HeuristicEvaluatorDelegate {
    var delegate: CortexDelegate {get}
    var heuristicEvaluator: HeuristicEvaluator {get}
    var pieces: [[Piece]] {get}
    var identity: Piece {get}
    var zobrist: Zobrist {get}
    var dim: Int {get}
    
    /**
     Could be optimized with binary insertion technique
     */
    func genSortedMoves(for player: Piece) -> [Move]
    
    /**
     Not the most efficient way, will do for now.
     */
    func genSortedMoves(for player: Piece, num: Int) -> [Move]
    
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
    
    func genSortedMoves(for player: Piece) -> [Move] {
        var sortedMoves = [Move]()
        var scoreMap = [[Int?]](repeating: [Int?](repeating: nil, count: dim), count: dim)
        
        if let co = delegate.revert() {
            if let moves = Zobrist.getOrderedMoves(zobrist, for: player) {
                delegate.put(at: co)
                moves.forEach{(co, score) in scoreMap[co.row][co.col] = score}
                
                for i in -1...1 {
                    for q in -1...1 {
                        if i == 0 && q == 0 {
                            continue
                        }
                        var c = (col: co.col + i, row: co.row + q)
                        var empty = 0
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
                                if piece != player {
                                    break loop
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
                        let score = ThreatEvaluator.evaluate(for: player, at: co, pieces: pieces)
                        let move = (co, score)
                        sortedMoves.append(move)
                    }
                }
            }
        }
        
        return sortedMoves.sorted {$0.score > $1.score}
    }
    
    func genSortedMoves(for player: Piece, num: Int) -> [Move] {
        return [Move](genSortedMoves(for: player).prefix(num))
    }
    
    func getSortedMoves(num: Int) -> [Move] {
        func finalize(_ movesB: [Move], _ movesW: [Move]) -> [Move] {
            if delegate.subjectiveBias {
                return [Move]([movesB, movesW]
                    .flatMap{$0}
                    .sorted(by: {$0.score > $1.score})
                    .prefix(num))
            } else {
                return [[Move](movesB.prefix(num)), [Move](movesW.prefix(num))]
                .flatMap{$0}
                .sorted(by: {$0.score > $1.score})
            }
        }
        if let retrieved = Zobrist.getOrderedMoves(zobrist, for: .black) {
            return finalize(retrieved, Zobrist.getOrderedMoves(zobrist, for: .white)!)
        } else {
            let blackMoves = genSortedMoves(for: .black)
            let whiteMoves = genSortedMoves(for: .white)
            
            if ZeroPlus.useOptimizations {
                ZeroPlus.syncedQueue.sync {
                    let newZobrist = Zobrist(zobrist: zobrist)
                    Zobrist.blackOrderedMovesMap[newZobrist] = blackMoves
                    Zobrist.whiteOrderedMovesMap[newZobrist] = whiteMoves
                }
            }
            return finalize(blackMoves, whiteMoves)
        }
    }
    
    func getHeuristicValue(for player: Piece) -> Int {
        var score = 0
        
        if let retrieved = Zobrist.hashedHeuristicMaps[dim - 1][zobrist] {
            retrievedCount += 1
            score = retrieved
        } else {
            let black = heuristicEvaluator.evaluate(for: .black)
            let white = heuristicEvaluator.evaluate(for: .white)
            score = black - white
            let newZobrist = Zobrist(zobrist: zobrist)
            if ZeroPlus.useOptimizations {
                ZeroPlus.syncedQueue.sync {
                    Zobrist.hashedHeuristicMaps[dim - 1][newZobrist] = score
                }
            }
        }
        
        return player == .black ? score : -score
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
    var subjectiveBias: Bool {get}
    func put(at co: Coordinate)
    @discardableResult
    func revert() -> Coordinate?
}

class BasicCortex: CortexProtocol {
    var delegate: CortexDelegate
    
    var heuristicEvaluator = HeuristicEvaluator()
    
    init(_ delegate: CortexDelegate) {
        self.delegate = delegate
        heuristicEvaluator.delegate = self
    }
    
    /**
     Add an insignificant random weight to the scores to break apart ties.
     */
    func differentiate(_ cands: [Move], maxWeight: Int) -> [Move] {
        return cands.map {(co: $0.co, score: $0.score + Int.random(in: 0..<maxWeight))}
    }
    
    func getMove(for player: Piece) -> Move {
        var offensiveMoves = genSortedMoves(for: player)
        var defensiveMoves = genSortedMoves(for: player.next())
        if offensiveMoves.count == 0 && defensiveMoves.count == 0 {
            // If ZeroPlus is out of moves...
            return ((-1, -1), 0)
        }
        if delegate.randomizedSelection {
            offensiveMoves = differentiate(offensiveMoves, maxWeight: 10).sorted{$0.score > $1.score}
            defensiveMoves = differentiate(defensiveMoves, maxWeight: 10).sorted{$0.score > $1.score}
        }
        let attack = offensiveMoves[0]
        let defend = defensiveMoves[0]
        if attack.score >= Threat.win {
            return attack
        } else if defend.score >= Threat.win {
            return defend
        } else {
            return attack.score > defend.score ? attack : defend
        }
    }
    
    func getMove() -> Move {
        return getMove(for: identity)
    }
}

protocol TimeLimitedSearchProtocol {
    var searchCancelledInProgress: Bool {get}
}
