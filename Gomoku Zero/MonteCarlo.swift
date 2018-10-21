//
//  MonteCarlo.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/20/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class MonteCarloCortex: CortexProtocol {
    var delegate: CortexDelegate
    
    var heuristicEvaluator = HeuristicEvaluator()
    var randomExpansion = true
    var maxSimulationDepth = 5
    var iterations = 0
    var debug = true
    
    // BasicCortex for performing fast simulation.
    var basicCortex: BasicCortex
    
    /// The exploration factor
    static let expFactor: Double = sqrt(2.0)
    
    /// The branching factor
    var breadth: Int
    
    init(_ delegate: CortexDelegate, breadth: Int) {
        self.delegate = delegate
        self.breadth = breadth
        self.basicCortex = BasicCortex(delegate)
        heuristicEvaluator.delegate = self
    }
    
    func dPrint(_ items: Any) {
        if !debug {return}
        print(items)
    }
    
    
    
    func getMove() -> Move {
        let rootNode = Node(identity: delegate.curPlayer, co: (0,0))
        iterations = 0
        while !timeout() {
            dPrint("begin\t------------------------------------------------")
            dPrint(">> initial root node: \n\(rootNode)")
            let node = rootNode.select()
            dPrint(">> selected node: \n\(node)")
            let stackTrace = node.stackTrace()
            for node in stackTrace {
                delegate.put(at: node.coordinate!)
            }
            let newNode = node.expand(self, breadth)
            dPrint(">> expanded node: \n\(newNode)")
            let player = playout(node: newNode)
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
            } else if node.winningRatio > bestNode!.winningRatio {
                bestNode = node
            }
        }
        return (bestNode!.coordinate!, bestNode!.numVisits)
    }
    
    func revert(num: Int) {
        for _ in 0..<num {
            delegate.revert()
        }
    }
    
    /**
     Performs quick simulation with target node
     - Returns: null for draw, .black if black emerges as winner.
     */
    func playout(node: Node) -> Piece? {
        delegate.put(at: node.coordinate!)
        if let winnner = hasWinner() { // if the node is terminal node
            node.isTerminal = true
            delegate.revert()
            return winnner
        }
        for i in 0..<maxSimulationDepth {
            let move = basicCortex.getMove(for: delegate.curPlayer)
            delegate.put(at: move.co)
            if let winner = hasWinner() {
//                print("simulated winner: \(winner)\t sim. depth = \(i)")
//                print(delegate.zobrist)
                revert(num: i + 2)
                return winner
            }
        }
        revert(num: maxSimulationDepth + 1)
        return nil
    }
    
    func hasWinner() -> Piece? {
        let blackScore = heuristicEvaluator.evaluate(for: .black)
        let whiteScore = heuristicEvaluator.evaluate(for: .white)
        if blackScore > Threat.win || whiteScore > Threat.win {
            return blackScore > whiteScore ? .black : .white
        }
        return nil
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
        var isTerminal = false
        
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
                if node.isTerminal {continue}
                let ucb1 = node.ucb1()
                if ucb1 > maxUcb1 {
                    maxUcb1 = ucb1
                    selected = node
                }
            }
            
            if selected == nil { // If all of the child nodes are terminal
                isTerminal = true
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
                candidates = delegate.getSortedMoves(num: breadth)
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
        
        /**
         Backpropagation: update the stats of all nodes that were traversed to get to the current node
         */
        func backpropagate(winner: Piece?) {
            if let player = winner, let parent = self.parent {
                numWins += parent.identity == player ? 1 : -1
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
