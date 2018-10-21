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
class ZeroPlus: CortexDelegate {
    var delegate: ZeroPlusDelegate!
    var visDelegate: ZeroPlusVisualizationDelegate?
    
    var activeMapDiffStack = [[Coordinate]]()
    var activeCoMap = [[Bool]]()
    var dim: Int {
        return delegate.dimension
    }
    
    var zobrist: Zobrist = Zobrist(matrix: [[Piece]]())
    var pieces: [[Piece]] {
        return zobrist.matrix
    }
    var history = History()
    
    
    var curPlayer: Piece = .black
    var identity: Piece = .black
    
    var startTime: TimeInterval = 0
    var maxThinkingTime: TimeInterval = 10
    
    let asyncedQueue = DispatchQueue(label: "asyncedQueue", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    static let syncedQueue = DispatchQueue(label: "syncedQueue")
    var cortex: CortexProtocol?
//    var personality: Personality = .search(depth: 6, breadth: 3)
    var personality: Personality = .monteCarlo(breadth: 5)
    var iterativeDeepening = true
    
    var calcDurations = [TimeInterval]()
    
    /**
     Generate a map that indicates the active coordinates
     */
    func genActiveCoMap() {
        activeCoMap = [[Bool]](repeating: [Bool](repeating: false, count: dim), count: dim)
        delegate.history.stack.forEach {updateActiveCoMap(at: $0, recordDiff: false)}
    }
    
    private func updateActiveCoMap(at co: Coordinate, recordDiff: Bool) {
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
    
    func getMove(for player: Piece) {
        startTime = Date().timeIntervalSince1970
        zobrist = Zobrist(matrix: delegate.pieces) // Update and store the arrangement of pieces from the delegate
        genActiveCoMap() // Generate a map containing active coordinates
        history = History() // Create new history
        activeMapDiffStack = [[Coordinate]]()
        curPlayer = player // Note: this is changed every time put() is called.
        identity = player
        Zobrist.orderedMovesMap = Dictionary<Zobrist, [Move]>() // Clear ordered moves map.
        
        visDelegate?.activeMapUpdated(activeMap: activeCoMap) // Notify the delegate that active map has updated
        
        if delegate.history.stack.count == 0 && player == .black { // When ZeroPlus is black, the first move is always at the center
            delegate?.bestMoveExtrapolated(co: (dim / 2, dim / 2))
        } else if delegate.history.stack.count == 1 && player == .white {
            delegate?.bestMoveExtrapolated(co: getSecondMove())
        } else {
            switch personality {
            case .basic: cortex = BasicCortex(self)
            case .search(depth: let d, breadth: let b):
                if iterativeDeepening {
                    cortex = IterativeDeepeningCortex(self, depth: d, breadth: b)
                } else {
                    let minimax =  MinimaxCortex(self, depth: d, breadth: b)
                    minimax.verbose = true
                    cortex = minimax
                }
            case .negaScout(depth: let d, breadth: let b):
                cortex = NegaScoutCortex(self, depth: d, breadth: b)
            case .monteCarlo(breadth: let b):
                cortex = MonteCarloCortex(self, breadth: b)
            }
            delegate.bestMoveExtrapolated(co: cortex!.getMove().co)
        }
        let duration = Date().timeIntervalSince1970 - startTime
        calcDurations.append(duration)
        let avgDuration = calcDurations.reduce(0){$0 + $1} / Double(calcDurations.count)
        print("duration: \(duration)\n avg. duration: \(avgDuration)")
        
        visDelegate?.activeMapUpdated(activeMap: nil) // Erase drawings of active map
    }
    
    /**
     This is a special case, generate a random second move around the first move.
     */
    func getSecondMove() -> Coordinate {
        let firstMove = delegate.history.stack.first!
        let range = Int.random(in: 0...5) == 0 ? -2...2 : -1...1
        let randOffset1 = Int.random(in: range)
        let randOffset2 = Int.random(in: range)
        let co = Coordinate(col: firstMove.col + randOffset1, row: firstMove.row + randOffset2)
        if !delegate.isValid(co) || co == firstMove  {
            return getSecondMove()
        }
        return co
    }
    
    /**
     Used in pair with revert to handle changes to the board efficiently
     */
    func put(at co: Coordinate) {
        zobrist.put(at: co, curPlayer)
        curPlayer = curPlayer.next()
        history.push(co)
        updateActiveCoMap(at: co, recordDiff: true) // Push changes to active map to the difference stack
        visDelegate?.historyDidUpdate(history: history)
        visDelegate?.activeMapUpdated(activeMap: activeCoMap)
    }
    
    func revert() {
        let co = history.revert()!
        zobrist.revert(at: co)
        curPlayer = curPlayer.next()
        revertActiveMapUpdate()
        visDelegate?.historyDidUpdate(history: history)
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
    
    func hasWinner() -> Piece? {
        return delegate.hasWinner()
    }
}

enum Personality {
    case basic
    case search(depth: Int, breadth: Int)
    case negaScout(depth: Int, breadth: Int)
    case monteCarlo(breadth: Int)
}

protocol ZeroPlusDelegate {
    var history: History {get}
    var dimension: Int {get}
    var pieces: [[Piece]] {get}
    func isValid(_ co: Coordinate) -> Bool
    func bestMoveExtrapolated(co: Coordinate)
    func hasWinner() -> Piece?
}

protocol ZeroPlusVisualizationDelegate {
    func activeMapUpdated(activeMap: [[Bool]]?)
    func historyDidUpdate(history: History?)
}
