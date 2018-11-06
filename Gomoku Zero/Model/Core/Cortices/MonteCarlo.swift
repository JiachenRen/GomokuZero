//
//  MonteCarlo.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/20/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class MonteCarloCortex: BasicCortex {
    var randomExpansion = true
    var simDepth = 10
    var iterations = 0
    var debug = true
    
    // BasicCortex for performing fast simulation.
    var cortex: CortexProtocol
    
    /// The exploration factor
    static let expFactor: Double = sqrt(2.0)
    
    /// The branching factor
    var breadth: Int
    
    init(_ delegate: CortexDelegate, breadth: Int) {
        self.breadth = breadth
        self.cortex = BasicCortex(delegate)
        super.init(delegate)
    }
    
    func dPrint(_ items: Any) {
        if !debug {return}
        print(items)
    }
    
    
    
    override func getMove() -> Move {
        let rootNode = Node(identity: delegate.curPlayer, co: (0,0))
        iterations = 0
        while !delegate.timeout {
            dPrint("begin\t------------------------------------------------")
            dPrint(">> initial root node: \n\(rootNode)")
            let node = rootNode.select()
            dPrint(">> selected node: \n\(node)")
            let stackTrace = node.stackTrace()
            var count = 0
            for node in stackTrace {
                delegate.put(at: node.coordinate!)
                count += 1
            }
            print("level: \(count), iterations: \(iterations)")
            let newNode = node.expand(self, breadth)
            dPrint(">> expanded node: \n\(newNode)")
            let score = rollout(depth: simDepth, node: newNode)
            dPrint(">> playout score: \(score)")
            newNode.backpropagate(score)
            revert(num: stackTrace.count)
            iterations += 1
            dPrint(">> iterations completed: \(iterations)")
            dPrint(">> root node: \n\(rootNode)")
            dPrint("end\t------------------------------------------------")
        }
        
        var bestNode: Node?
        for node in rootNode.children {
            if bestNode == nil {
                bestNode = node
            } else if node.numVisits > bestNode!.numVisits {
                print("avg. Score: \(node.avgScore), visits: \(node.numVisits), co: \(node.coordinate!)")
                bestNode = node
            }
        }
        let move = (bestNode!.coordinate!, bestNode!.numVisits)
        return move
    }
    
    
    
    /**
     Performs quick simulation with target node
     - Returns: null for draw, .black if black emerges as winner.
     */
    func rollout(depth: Int, node: Node) -> Int {
        delegate.put(at: node.coordinate!)
        if let winner = hasWinner() { // if the node is terminal node
            delegate.revert()
            return winner == .black ? Evaluator.win : -Evaluator.win
        }
        for i in 0..<depth {
            let move = cortex.getMove()
            delegate.put(at: move.co)
            if let winner = hasWinner() {
                //                print("simulated winner: \(winner)\t sim. depth = \(i)")
                //                print(delegate.zobrist)
                revert(num: i + 2)
                return winner == .black ? Evaluator.win : -Evaluator.win
            }
        }
        let score = threatCoupledHeuristic()
        revert(num: depth + 1)
        return score
    }
    
    
    /// Monte Carlo Tree Node
    class Node {
        var cumScore: Int = 0
        var numVisits: Int = 0
        var identity: Piece
        var coordinate: Coordinate?
        var children = [Node]()
        var parent: Node?
        var candidates: [Move]?
        var avgScore: Double {
            return Double(cumScore) / Double(numVisits)
        }
        
        convenience init(identity: Piece, co: Coordinate) {
            self.init(parent: nil, identity: identity, co: co)
        }
        
        init(parent: Node?, identity: Piece, co: Coordinate) {
            self.parent = parent
            self.identity = identity
            self.coordinate = co
        }
        
        /// Trace up the search tree; root node is excluded.
        func stackTrace() -> [Node] {
            var stack = [Node]()
            var node = self
            while node.parent != nil {
                stack.append(node)
                node = node.parent!
            }
            
            return stack.reversed()
        }
        
        /// Recursive selection phase
        func select() -> Node {
            if candidates == nil || candidates!.count > 0 {
                return self // If the current node is not fully expanded, stop selection.
            }
            var selected: Node?
            var maxUcb1 = -Double.infinity
            for idx in 0..<children.count {
                let node = children[idx]
                let ucb1 = node.ucb1()
                if ucb1 > maxUcb1 {
                    maxUcb1 = ucb1
                    selected = node
                }
            }
            
            if selected == nil { // If all of the child nodes are terminal
                if let parent = self.parent {
                    return parent.select()
                } else { // If root node is terminal
                    return self
                }
            }
            return selected!.select()
        }
        
        /// Upper Confidence Bound 1 algorithm, used to balance exploiration and exploration
        func ucb1() -> Double {
            var avgScore = Double(cumScore) / Double(numVisits)
            if identity == .white {
                avgScore *= -1
            }
            let exploitation = map(avgScore, Double(-Evaluator.win), Double(Evaluator.win), -1, 1)
            let exploration = MonteCarloCortex.expFactor * sqrt(log(Double(parent!.numVisits)) / log(M_E) / Double(numVisits))
            return exploitation + exploration
        }
        
        private func map(_ n: Double, _ lb1: Double, _ ub1: Double, _ lb2: Double, _ ub2: Double) -> Double {
            return (n - lb1) / (ub1 - lb1) * (ub2 - lb2) + lb2
        }
        
        
        /// Expansion phase
        func expand(_ delegate: MonteCarloCortex, _ breadth: Int) -> Node {
            if candidates == nil {
                candidates = Array(delegate.getSortedMoves().prefix(breadth))
                func filter(_ cands: inout [Move], thres: Int) {
                    if cands.contains(where: {$0.score >= thres}) {
                        cands = cands.filter{$0.score >= thres}
                    }
                }
                
                let bp4 = delegate.val(.blockedPokedFour)
                let sp3 = delegate.val(.straightPokedThree)
                
                filter(&candidates!, thres: Evaluator.win) // 5
                filter(&candidates!, thres: bp4) // 4
                filter(&candidates!, thres: bp4 + sp3) // 4 x 3
                filter(&candidates!, thres: sp3 * 2) // 3 x 3
                
                if delegate.randomExpansion {
                    candidates = candidates!.shuffled()
                }
            }
            if candidates!.count == 0 { // Terminal state has been reached
                return self
            }
            let candidate = candidates!.removeFirst()
            let newNode = Node(parent: self, identity: delegate.delegate.curPlayer, co: candidate.co)
            children.append(newNode)
            return newNode
        }
        
        
        /// Backpropagation: update the stats of all nodes that were traversed to get to the current node
        func backpropagate(_ score: Int) {
            cumScore += score
            numVisits += 1
            if let parent = self.parent {
                parent.backpropagate(score)
            }
        }
    }
    
}

extension MonteCarloCortex.Node: CustomStringConvertible {
    var description: String {
        let coStr = coordinate == nil ? "nil" : "\(coordinate!)"
        let this = "avg_score: \(avgScore)\tvisits: \(numVisits)\tidentity: \(identity)\tco: \(coStr)\tchildren: \(children.count)"
        return self.children.map{$0.description}
            .reduce(this){"\($0)\n\(indentation)\($1)"}
    }
    
    private var indentation: String {
        return (0...stackTrace().count).map{_ in "\t"}.reduce("", +)
    }
}
