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
            let player = rollout(depth: simDepth, node: newNode)
            dPrint(">> playout winner: \(player == nil ? "none" : "\(player!)")")
            newNode.backpropagate(winner: player)
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
                print("winning ratio: \(node.winningRatio), visits: \(node.numVisits), co: \(node.coordinate!)")
                bestNode = node
            }
        }
        let move = (bestNode!.coordinate!, bestNode!.numVisits)
        return move
    }
    
    /**
     Checks the output of the Monte Carlo Search, since sometimes it can get really wierd!
     Ideally, this function should not exist. Or am I mistaken?
     */
    func guardSolution(move: Move) -> Move {
        let node = Node(identity: delegate.curPlayer, co: move.co)
        let threshold = 10
        if let piece = rollout(depth: threshold, node: node) {
            // A winner emerges with Monte Carlo's solution
            if piece == node.identity {
                return move
            } else {
                // If Monte Carlo loses by choosing the current move,
                // a basic move is generated using heuristics.
                print("monte carlo solution invalidated - generating basic move")
                return cortex.getMove()
            }
        }
        return move
    }
    
    
    
    /**
     Performs quick simulation with target node
     - Returns: null for draw, .black if black emerges as winner.
     */
    func rollout(depth: Int, node: Node) -> Piece? {
        delegate.put(at: node.coordinate!)
        if let winnner = hasWinner() { // if the node is terminal node
            delegate.revert()
            return winnner
        }
        for i in 0..<depth {
            let move = cortex.getMove()
            delegate.put(at: move.co)
            if let winner = hasWinner() {
                //                print("simulated winner: \(winner)\t sim. depth = \(i)")
                //                print(delegate.zobrist)
                revert(num: i + 2)
                return winner
            }
        }
        let winner: Piece = threatCoupledHeuristic() > 0 ? .black : .white
        revert(num: depth + 1)
        return winner
    }
    
    
    /// Monte Carlo Tree Node
    class Node {
        var numWins: Int = 0
        var numVisits: Int = 0
        var identity: Piece
        var coordinate: Coordinate?
        var children = [Node]()
        var parent: Node?
        var candidates: [Move]?
        var winningRatio: Double {
            return Double(numWins) / Double(numVisits)
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
            let exploitation = Double(numWins) / Double(numVisits)
            let exploration = MonteCarloCortex.expFactor * sqrt(log(Double(parent!.numVisits)) / log(M_E) / Double(numVisits))
            return exploitation + exploration
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
        func backpropagate(winner: Piece?) {
            if let player = winner, let parent = self.parent {
                numWins += parent.identity == player ? 1 : 0
            }
            numVisits += 1
            if let parent = self.parent {
                parent.backpropagate(winner: winner)
            }
        }
    }
    
}

extension MonteCarloCortex.Node: CustomStringConvertible {
    var description: String {
        let coStr = coordinate == nil ? "nil" : "\(coordinate!)"
        let this = "wins: \(numWins)\tvisits: \(numVisits)\tidentity: \(identity)\tco: \(coStr)\tchildren: \(children.count)"
        return self.children.map{$0.description}
            .reduce(this){"\($0)\n\(indentation)\($1)"}
    }
    
    private var indentation: String {
        return (0...stackTrace().count).map{_ in "\t"}.reduce("", +)
    }
}
