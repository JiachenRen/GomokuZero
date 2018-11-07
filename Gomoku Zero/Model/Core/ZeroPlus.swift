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
class ZeroPlus: CortexDelegate, EvaluatorDataSource {
    let asyncedQueue = DispatchQueue(label: "asyncedQueue", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    
    var delegate: ZeroPlusDelegate!
    var visDelegate: VisualizationDelegate?
    
    var activeMapDiffStack = [[Coordinate]]()
    var activeMap = [[Bool]]()

    var zobrist: Zobrist = Zobrist(matrix: [[Piece]]())
    var history = History()
    var pieces: [[Piece]] {
        return zobrist.matrix
    }
    
    var curPlayer: Piece = .black
    var identity: Piece = .black
    
    var calcDurations = [TimeInterval]()
    var startTime: TimeInterval = 0
    
    var cortex: CortexProtocol
    var personality: Personality = .zeroMax(depth: 2, breadth: 8, rolloutPr: 100, simDepth: 6)
    var strategy: Strategy
    
    /// Default initializer
    init() {
        strategy = Strategy()
        cortex = BasicCortex(nil)
        cortex.delegate = self
    }
    
    convenience init(_ other: ZeroPlus) {
        self.init()
        delegate = other.delegate
        visDelegate = other.visDelegate
        
        zobrist = Zobrist(zobrist: other.zobrist)
        personality = other.personality
        activeMapDiffStack = [[Coordinate]]()
        activeMap = other.activeMap
        curPlayer = other.curPlayer
        identity = other.identity
        startTime = other.startTime
        strategy = other.strategy
        // TODO: add customization for the weighting!
    }

    func getMove(for player: Piece) {
        startTime = Date().timeIntervalSince1970
        zobrist = Zobrist(matrix: delegate.pieces) // Update and store the arrangement of pieces from the delegate
        genActiveCoMap() // Generate a map containing active coordinates
        history = History() // Create new history (on top of existing history)
        activeMapDiffStack = [[Coordinate]]()
        curPlayer = player // Note: this is changed every time put() is called.
        identity = player
        visDelegate?.activeMapUpdated(activeMap: activeMap) // Notify the delegate that active map has updated
        
        if delegate.history.stack.count == 0 && player == .black { // When ZeroPlus is black, the first move is always at the center
            delegate?.bestMoveExtrapolated(co: (zobrist.dim / 2, zobrist.dim / 2))
        } else if delegate.history.stack.count == 1 && player == .white {
            delegate?.bestMoveExtrapolated(co: getSecondMove())
        } else {
            switch personality {
            case .heuristic: cortex = BasicCortex(self)
            case .zeroSum: cortex = ZeroSumCortex(self)
            case .minimax(depth: let d, breadth: let b):
                if strategy.iterativeDeepening {
                    cortex = IterativeDeepeningCortex(self, depth: d, breadth: b, layers: strategy.layers) {
                        $0.cortex = MinimaxCortex($0, depth: $1, breadth: b)
                    }
                } else {
                    let minimax = MinimaxCortex(self, depth: d, breadth: b)
                    minimax.verbose = true
                    cortex = minimax
                }
            case .negaScout(depth: let d, breadth: let b):
                cortex = NegaScoutCortex(self, depth: d, breadth: b)
            case .monteCarlo(breadth: let b, rollout: let p, random: let r, debug: let d):
                cortex = MonteCarloCortex(self, breadth: b)
                let mtCortex = cortex as! MonteCarloCortex
                mtCortex.simDepth = p
                mtCortex.randomExpansion = r
                mtCortex.debug = d
            case .zeroMax(depth: let d, breadth: let b, rolloutPr: let r, simDepth: let s):
                if strategy.iterativeDeepening {
                    cortex = IterativeDeepeningCortex(self, depth: d, breadth: b, layers: strategy.layers) {
                        $0.cortex = ZeroMax($0, depth: $1, breadth: b, rollout: r, simDepth: s)
                    }
                } else {
                    cortex = ZeroMax(self, depth: d, breadth: b, rollout: r, simDepth: s)
                }
            }
            delegate.bestMoveExtrapolated(co: cortex.getMove().co)
        }
        let duration = Date().timeIntervalSince1970 - startTime
        calcDurations.append(duration)
        let avgDuration = calcDurations.reduce(0){$0 + $1} / Double(calcDurations.count)
        print("cortex: \(String(describing: cortex))\nduration: \(duration)\navg. duration: \(avgDuration)\n")
        
        let cached = Zobrist.heuristicHash.count
        print("retrieved: \(retrievedCount)\tcached: \(cached)\tratio: \(Double(retrievedCount) / Double(cached))\tcollisions: \(hashCollisions)\tcollision ratio: \(Double(hashCollisions) / Double(retrievedCount))")
        
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
        if !isValid(co, zobrist.dim) || co == firstMove  {
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
        visDelegate?.activeMapUpdated(activeMap: activeMap)
    }
    
    @discardableResult
    func revert() -> Coordinate? {
        if let co = history.revert() {
            zobrist.revert(at: co)
            curPlayer = curPlayer.next()
            revertActiveMapUpdate()
            visDelegate?.historyDidUpdate(history: history)
            visDelegate?.activeMapUpdated(activeMap: activeMap)
            return co
        }
        return nil
    }
    
    private func random() -> Coordinate {
        let row = CGFloat.random(min: 0, max: CGFloat(delegate.pieces.count))
        let col = CGFloat.random(min: 0, max: CGFloat(delegate.pieces.count))
        return (col: Int(col), row: Int(row))
    }
    
}

/**
 Active map update/revert related operations
 */
extension ZeroPlus {
    var activeCoordinates: [Coordinate] {
        return activeMap.enumerated().map {r, row in
            return row.enumerated().filter{$0.element}.map {c, _ in
                return Coordinate(col: c, row: r)
            }
            }.flatMap{$0}
    }
    
    /// Generate a 2D matrix of active coordinates
    func genActiveCoMap() {
        activeMap = [[Bool]](repeating: [Bool](repeating: false, count: zobrist.dim), count: zobrist.dim)
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
                if isValid(newCo, zobrist.dim) && pieces[newCo.row][newCo.col] == .none {
                    if recordDiff && activeMap[newCo.row][newCo.col] == false {
                        diffCluster.append(newCo)
                    }
                    activeMap[newCo.row][newCo.col] = true
                }
            }
        }
        if recordDiff && activeMap[co.row][co.col] == true {
            diffCluster.append(co)
        }
        activeMapDiffStack.append(diffCluster)
        activeMap[co.row][co.col] = false
    }
    
    /**
     Revert changes made to the active map made during last put() call
     */
    private func revertActiveMapUpdate() {
        for co in activeMapDiffStack.removeLast() {
            let tmp = activeMap[co.row][co.col]
            activeMap[co.row][co.col] = !tmp
        }
    }
}

extension ZeroPlus {
    
    var duration: TimeInterval {
        return Date().timeIntervalSince1970 - startTime
    }
    
    var timeout: Bool {
        return duration > strategy.timeLimit
    }
}

enum Personality {
    case heuristic
    case zeroSum
    case minimax(depth: Int, breadth: Int)
    case negaScout(depth: Int, breadth: Int)
    case monteCarlo(breadth: Int, rollout: Int, random: Bool, debug: Bool)
    case zeroMax(depth: Int, breadth: Int, rolloutPr: Int, simDepth: Int)
}

struct Strategy {
    /// Whether to use small random numbers to break the tie between even moves
    var randomizedSelection = true
    var iterativeDeepening = true
    var timeLimit: TimeInterval = 3
    var layers: IterativeDeepeningCortex.Layers = .evens
}

protocol ZeroPlusDelegate {
    var history: History {get}
    var dimension: Int {get}
    var pieces: [[Piece]] {get}
    func bestMoveExtrapolated(co: Coordinate)
}

protocol VisualizationDelegate {
    func activeMapUpdated(activeMap: [[Bool]]?)
    func historyDidUpdate(history: History?)
}
