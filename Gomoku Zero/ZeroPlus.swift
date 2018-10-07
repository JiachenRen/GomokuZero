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
class ZeroPlus {
    var delegate: ZeroPlusDelegate!
    var visDelegate: ZeroPlusVisualizationDelegate?
    var activeCoMap = [[Bool]]()
    var dim: Int {
        return delegate.dimension
    }
    var pieces = [[Piece]]()
    
    /**
     Generate a map that indicates the active coordinates
     */
    func genActiveCoMap() {
        activeCoMap = [[Bool]](repeating: [Bool](repeating: false, count: dim), count: dim)
        delegate.history.stack.forEach {co in
            for i in -2...2 {
                for j in -2...2 {
                    if abs(i) != abs(j) && i != 0 && j != 0  {
                        continue // Only activate diagonal coordinates
                    }
                    let newCo = (col: co.col + i, row: co.row + j)
                    if delegate.isValid(newCo) && pieces[newCo.row][newCo.col] == .none {
                        activeCoMap[newCo.row][newCo.col] = true
                    }
                }
            }
            activeCoMap[co.row][co.col] = false
        }
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
    
    func getMove(for player: Piece) {
        pieces = delegate.pieces // Update and store the arrangement of pieces from the delegate
        genActiveCoMap() // Generate a map containing active coordinates
        
        visDelegate?.activeMapUpdated(activeMap: activeCoMap) // Notify the delegate that active map has updated
        
        
        let offensiveMoves = genSortedMoves(for: player)
        let defensiveMoves = genSortedMoves(for: player.next())
        

        visDelegate?.activeMapUpdated(activeMap: nil) // Erase drawings of active map
        
        if offensiveMoves.count == 0 { // When ZeroPlus is black, the first move is always at the center
            delegate?.bestMoveExtrapolated(co: (dim / 2, dim / 2))
        } else {
            let offensiveMove = defensiveMoves[0]
            let defensiveMove = offensiveMoves[0]
            var move = offensiveMove
            if offensiveMove.score >= ThreatType.five.rawValue {
                move = offensiveMove
            } else if offensiveMove.score >= ThreatType.five.rawValue {
                move = defensiveMove
            } else {
                move = offensiveMove.score > defensiveMove.score ? offensiveMove : defensiveMove
            }
            delegate.bestMoveExtrapolated(co: move.co)
        }
        
    }
    
    
    
    private func random() -> Coordinate {
        let row = CGFloat.random(min: 0, max: CGFloat(delegate.pieces.count))
        let col = CGFloat.random(min: 0, max: CGFloat(delegate.pieces.count))
        return (col: Int(col), row: Int(row))
    }
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
