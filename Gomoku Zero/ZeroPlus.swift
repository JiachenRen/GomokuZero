//
//  ZeroPlus.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/6/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

typealias Move = (co: Coordinate, score: Int)

/**
 Zero Plus - Jiachen's fifth attemp at making an unbeatable Gomoku AI
 */
class ZeroPlus: HeuristicEvaluatorDelegate {
    var delegate: ZeroPlusDelegate!
    var visDelegate: ZeroPlusVisualizationDelegate?
    var activeCoMap = [[Bool]]()
    var dim: Int {
        return delegate.dimension
    }
    var pieces = [[Piece]]()
    var history = History()
    var identity: Piece = .black
    var staticId: Piece = .black
    var heuristicEvaluator = HeuristicEvaluator()
    
    var personality: Personality = .gameTheory
    var activeMapDiffStack = [[Coordinate]]()
    
    /**
     Generate a map that indicates the active coordinates
     */
    func genActiveCoMap() {
        activeCoMap = [[Bool]](repeating: [Bool](repeating: false, count: dim), count: dim)
        delegate.history.stack.forEach {updateActiveCoMap(at: $0, recordDiff: false)}
    }
    
    func updateActiveCoMap(at co: Coordinate, recordDiff: Bool) {
        var diffCluster = [Coordinate]()
        for i in -2...2 {
            for j in -2...2 {
                if abs(i) != abs(j) && i != 0 && j != 0  {
                    continue // Only activate diagonal coordinates
                }
                let newCo = (col: co.col + i, row: co.row + j)
                if delegate.isValid(newCo) && pieces[newCo.row][newCo.col] == .none {
                    if recordDiff && activeCoMap[newCo.row][newCo.col] == false {
                        diffCluster.append(newCo)
                    }
                    activeCoMap[newCo.row][newCo.col] = true
                }
            }
        }
        if recordDiff && activeCoMap[co.row][co.col] == true {
            diffCluster.append(co)
        }
        activeMapDiffStack.append(diffCluster)
        activeCoMap[co.row][co.col] = false
    }
    
    /**
     Could be optimized with binary insertion technique
     */
    func genSortedMoves(for player: Piece) -> [Move] {
        var sortedMoves = [Move]()
        for (i, row) in activeCoMap.enumerated() {
            for (q, isActive) in row.enumerated() {
                if isActive {
                    let co = (col: q, row: i)
                    let score = Evaluator.evaluate(for: player, at: co, pieces: pieces)
                    let move = (co, score)
                    sortedMoves.append(move)
                }
            }
        }
        return sortedMoves.sorted {$0.score > $1.score}
    }
    
    /**
     Not the most efficient way, will do for now.
     */
    func genSortedMoves(for player: Piece, num: Int) -> [Move] {
        return [Move](genSortedMoves(for: player).prefix(num))
    }
    
    func getMove(for player: Piece) {
        heuristicEvaluator.delegate = self
        pieces = delegate.pieces // Update and store the arrangement of pieces from the delegate
        genActiveCoMap() // Generate a map containing active coordinates
        history = History() // Create new history
        activeMapDiffStack = [[Coordinate]]()
        identity = player // Note: this is changed every time put() is called.
        staticId = player
        
        visDelegate?.activeMapUpdated(activeMap: activeCoMap) // Notify the delegate that active map has updated
        
        if delegate.history.stack.count == 0 && player == .black{ // When ZeroPlus is black, the first move is always at the center
            delegate?.bestMoveExtrapolated(co: (dim / 2, dim / 2))
        } else {
            var move: Move? = nil
            
            switch personality {
            case .basic:
                let offensiveMoves = genSortedMoves(for: player)
                let defensiveMoves = genSortedMoves(for: player.next())
                let offensiveMove = offensiveMoves[0]
                let defensiveMove = defensiveMoves[0]
                if offensiveMove.score >= ThreatType.terminalMax {
                    move = offensiveMove
                } else if defensiveMove.score >= ThreatType.terminalMax {
                    move = defensiveMove
                } else {
                    move = offensiveMove.score > defensiveMove.score ? offensiveMove : defensiveMove
                }
            case .gameTheory:
                move = minimax(depth: 4, breadth: 3, player: identity)
            }
            
            delegate.bestMoveExtrapolated(co: move!.co)
        }
        
        visDelegate?.activeMapUpdated(activeMap: nil) // Erase drawings of active map
    }
    
    
    //    function minimax(node, depth, maximizingPlayer)
    //    02     if depth = 0 or node is a terminal node
    //    03         return the heuristic value of node
    //
    //    04     if maximizingPlayer
    //    05         bestValue := −∞
    //    06         for each child of node
    //    07             v := minimax(child, depth − 1, FALSE)
    //    08             bestValue := max(bestValue, v)
    //    09         return bestValue
    //
    //    10     else    (* minimizing player *)
    //    11         bestValue := +∞
    //    12         for each child of node
    //    13             v := minimax(child, depth − 1, TRUE)
    //    14             bestValue := min(bestValue, v)
    //    15         return bestValue
    func minimax(depth: Int, breadth: Int, player: Piece) -> Move {
        let myScore = heuristicEvaluator.evaluate(for: staticId)
        let opponentScore = heuristicEvaluator.evaluate(for: staticId.next())
        let score = myScore - opponentScore
        
        if score >= ThreatType.terminalMax || score <= -ThreatType.terminalMax { // Terminal state has reached
            return (co: (col: 0, row: 0), score: score)
        } else if depth == 0  {
            var move = genSortedMoves(for: player)[0]
            move.score = myScore - opponentScore
            return move
        }
    
        if player == staticId {
            var bestMove = (co: (col: 0,row: 0), score: Int.min)
            for move in [genSortedMoves(for: player, num: breadth), genSortedMoves(for: player.next(), num: breadth)].flatMap({$0}) {
                put(at: move.co)
                let score = minimax(depth: depth - 1, breadth: breadth, player: player.next()).score
                revert()
                if score > bestMove.score {
                    bestMove = move
                    bestMove.score = score
                    if score >= ThreatType.terminalMax {
                        return bestMove
                    }
                }
            }
            return bestMove
        } else {
            var bestMove = (co: (col: 0,row: 0), score: Int.max)
            for move in [genSortedMoves(for: player, num: breadth), genSortedMoves(for: player.next(), num: breadth)].flatMap({$0}) {
                put(at: move.co)
                let score = minimax(depth: depth - 1, breadth: breadth, player: player.next()).score
                revert()
                if score < bestMove.score {
                    bestMove = move
                    bestMove.score = score
                    if score <= -ThreatType.terminalMax {
                        return bestMove
                    }
                }
            }
            return bestMove
        }
    }
    
    /**
     Used in pair with revert to handle changes to the board efficiently
     */
    private func put(at co: Coordinate) {
        pieces[co.row][co.col] = identity
        identity = identity.next()
        history.push(co)
        updateActiveCoMap(at: co, recordDiff: true) // Push changes to active map to the difference stack
        visDelegate?.activeMapUpdated(activeMap: activeCoMap)
    }
    
    private func revert() {
        let co = history.revert()!
        pieces[co.row][co.col] = .none
        identity = identity.next()
        revertActiveMapUpdate()
        visDelegate?.activeMapUpdated(activeMap: activeCoMap)
    }
    
    /**
     Revert changes made to the active map made during last put() call
     */
    private func revertActiveMapUpdate() {
        for co in activeMapDiffStack.removeLast() {
            let tmp = activeCoMap[co.row][co.col]
            activeCoMap[co.row][co.col] = !tmp
        }
    }
    
    
    private func random() -> Coordinate {
        let row = CGFloat.random(min: 0, max: CGFloat(delegate.pieces.count))
        let col = CGFloat.random(min: 0, max: CGFloat(delegate.pieces.count))
        return (col: Int(col), row: Int(row))
    }
}

enum Personality {
    case basic, gameTheory
}

protocol ZeroPlusDelegate {
    var history: History {get}
    var dimension: Int {get}
    var pieces: [[Piece]] {get}
    func isValid(_ co: Coordinate) -> Bool
    func bestMoveExtrapolated(co: Coordinate)
}

protocol ZeroPlusVisualizationDelegate {
    func activeMapUpdated(activeMap: [[Bool]]?)
}
