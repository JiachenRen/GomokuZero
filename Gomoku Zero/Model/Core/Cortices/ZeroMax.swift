//
//  ZeroMax.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/21/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

/// A variant of minimax that attempts to address the horizon effect
class ZeroMax: MinimaxCortex {

    var basicCortex: BasicCortex
    
    /// An Int b/w 0 and 100 that denotes the probability in which a simulation should be performed.
    var rolloutPr: Int
    
    /// Defaults to Threat.interesting. Denotes the threshold beyond which a simulation might be performed.
    var threshold: Int
    
    /// Simulation deph during rollout.
    var simDepth: Int
    
    var status: Status = .search
    
    /// black & white threat matrices
    static var bTMatrices = Dictionary<Zobrist, [[[Threat]?]]>()
    static var wTMatrices = Dictionary<Zobrist, [[[Threat]?]]>()
    static var exterminationHash = Dictionary<Zobrist, [Move]>()
    static var syncedQueue = DispatchQueue(label: "ZeroMax.syncedQueue")
    
    private let sp3 = Threat.straightPokedThree.rawValue
    private let bp4 = Threat.blockedPokedFour.rawValue
    private let bp2 = Threat.blockedPokedTwo.rawValue
    private let s4 = Threat.straightFour.rawValue
    
    /**
     - Parameter rollout: an integer b/w 0 and 100 that denotes the probability of simulation at leaf nodes.
     - Parameter threshold: defaults to Threat.interesting. Denotes the threshold beyond which a simulation might be performed.
     - Parameter simDepth: depth of rollouts to be carried. Defaults to 10.
     */
    init(_ delegate: CortexDelegate, depth: Int, breadth: Int, rollout: Int, threshold: Int = Threat.interesting, simDepth: Int = 10) {
        self.basicCortex = BasicCortex(delegate)
        self.rolloutPr = rollout
        self.threshold  = threshold
        self.simDepth = simDepth
        super.init(delegate, depth: depth, breadth: breadth)
    }
    
    override func getMove() -> Move {
        let move = super.getMove()
        if verbose {
            print("rollout probability: \(rolloutPr)")
        }
        return move
    }
    
    /**
     A modification to the minimax algorithm that attempts to address the horizon effect.
     It attempts to look beyond the horizon by playing out a full simulation
     of the current leaf node game state until a winner emerges.
     Otherwise, there is nothing beyond the horizon and the original heuristic value is returned.
     
     - Returns: modified heuristic value of the node.
     */
    override func beyondHorizon(_ score: Int, _ alpha: Int, _ beta: Int, _ player: Piece) -> Int {
        // Overcome horizon effect by looking further into interesting nodes
        var score = score
        let shouldRollout = rolloutPr != 0 && Int.random(in: 0...(100 - rolloutPr)) == 0
        if shouldRollout && status != .exterminate {
            status = .exterminate
            if let rolloutScore = minimax(simDepth, player, alpha, beta)?.score {
                score = rolloutScore
            }
            status = .search
        }
        return score
    }
    
    override func getCandidates() -> [Move] {
        switch status {
        case .search: return super.getCandidates()
        case .exterminate:
            if let moves = ZeroMax.exterminationHash[zobrist] {
                return moves
            } else {
                let moves = genTerminalCands()
                let copy = Zobrist(zobrist: zobrist)
                ZeroMax.syncedQueue.sync {
                    ZeroMax.exterminationHash[copy] = moves
                }
                return moves
            }
        }
    }
    
    typealias Candidate = (co: Coordinate, threats: [Threat], score: Int)
    
    /**
     Generate candidates that have better threat potential than straight poked threes. This
     significantly reduces branching factor. Another hand-crafted policy is used to further
     filter the candidates until only absolutely necessary ones remain.
     
     - Returns: Moves for the current player that have strong potential to either fend off
                the opponent's attack or defeat the opponent.
     */
    private func genTerminalCands() -> [Move] {
        var bCands = [Candidate]()
        var wCands = [Candidate]()
        var bTMatrix = [[[Threat]?]](repeating: [[Threat]?](repeating: nil, count: dim), count: dim)
        var wTMatrix = bTMatrix

        if let co = delegate.revert() {
            if let bMatrix = ZeroMax.bTMatrices[zobrist], let wMatrix = ZeroMax.wTMatrices[zobrist] {
                delegate.put(at: co)
                wTMatrix = wMatrix
                bTMatrix = bMatrix
                invalidate(&bTMatrix, at: co)
                invalidate(&wTMatrix, at: co)
            } else {
                delegate.put(at: co)
            }
        }

        delegate.activeCoordinates.forEach {co in
            let bts = bTMatrix[co.row][co.col] ?? Threat.analyze(for: .black, at: co, pieces: pieces)
            let wts = wTMatrix[co.row][co.col] ?? Threat.analyze(for: .white, at: co, pieces: pieces)
            bTMatrix[co.row][co.col] = bts
            wTMatrix[co.row][co.col] = wts
            bCands.append((co, bts, bts.reduce(0){$0 + $1.rawValue}))
            wCands.append((co, wts, wts.reduce(0){$0 + $1.rawValue}))
        }

        ZeroMax.update(zobrist, bTMatrix, wTMatrix)
        
        func finalize(_ cands: [Candidate]) -> [Move] {
            return cands.map{(co: $0.co, score: $0.score)}
        }
        
        // We are only concerned about threes and fours
        bCands = bCands.filter{$0.score > sp3 + bp2}
            .filter{$0.threats.count > 1 || $0.score >= s4}
            .sorted{$0.score > $1.score}
        wCands = wCands.filter{$0.score > sp3 + bp2}
            .filter{$0.threats.count > 1 || $0.score >= s4}
            .sorted{$0.score > $1.score}
        
        if bCands.isEmpty {
            return finalize(wCands)
        }
        
        if wCands.isEmpty {
            return finalize(bCands)
        }
        
        let me = delegate.curPlayer == .white ? wCands : bCands
        let you = delegate.curPlayer == .white ? bCands : wCands
        
        let cands = terminalPolicy(me, you)
        return finalize(cands)
    }
    
    /**
     The terminal policy elects candidates based on the premise that each player is either
     trying to win by continuous threes and fours or blocking other's moves.
     
     - Parameter me: candidates for the current player
     - Parameter you: candidates for the next player
     */
    private func terminalPolicy(_ me: [Candidate], _ you: [Candidate]) -> [Candidate] {
        if me.first!.score >= Threat.win {
            return [me.first!]
        } else if you.first!.score >= Threat.win {
            return [you.first!]
        }
        
        // You can form s4 next turn, thus I can only play fours or block your three
        if you.first!.score >= s4 {
            var fours = me.filter{$0.score >= bp4}
            let blocks = you.filter{$0.score >= s4}
            fours.append(contentsOf: blocks)
            return fours
        }
        
        // You can form b4 + s3 next turn, thus I can only play fours or block you
        if you.first!.score >= bp4 + sp3 {
            var fours = me.filter{$0.score >= bp4}
            let blocks = you.filter{$0.score >= bp4 + sp3}
            fours.append(contentsOf: blocks)
            return fours
        }
        
        // Only explore moves that bring threats to my opponent. This makes me aggressive!
        return [me].flatMap{$0}.sorted{$0.score > $1.score}
    }
    
    private static func update(_ key: Zobrist, _ bTMatrix: [[[Threat]?]], _ wTMatrix: [[[Threat]?]]) {
        let copy = Zobrist(zobrist: key)
        syncedQueue.sync {
            bTMatrices[copy] = bTMatrix
            wTMatrices[copy] = wTMatrix
        }
    }
    
    enum Status {
        case search
        case exterminate
    }
}
