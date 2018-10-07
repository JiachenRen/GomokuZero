//
//  History.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class History {
    var stack: [Coordinate]
    var reverted: [Coordinate]
    
    init() {
        stack = [Coordinate]()
        reverted = [Coordinate]()
    }
    
    /**
     Push a move into the history stack
     */
    func push(_ co: Coordinate) {
        stack.append(co)
        reverted = [Coordinate]() // Clear the history that's been overwritten
    }
    
    /**
     Used for reverting a move
     Extract a move from the history stack
     */
    func revert() -> Coordinate? {
        if stack.count == 0 {return nil}
        let co = stack.removeLast()
        reverted.append(co)
        return co
    }
    
    /**
     Used for restoring a reverted move
     */
    func restore() -> Coordinate? {
        if reverted.count == 0 {return nil}
        let co = reverted.removeLast()
        stack.append(co)
        return co
    }
    
    /**
     Serialize the history stack in the following format:
     col,row;col,row;col,row...
     */
    func serialize() -> String {
        var str =  stack.map{"\($0.col),\($0.row)"}
            .reduce(""){"\($0);\($1)"}
        str.removeFirst()
        return str
    }
    
    /**
     Reload serialized coordinates into the stack
     */
    func load(_ history: String) {
        reverted = [Coordinate]()
        self.stack = history.split(separator: ";")
            .map{$0.split(separator: ",").map{Int($0)!}}
            .map{(col: $0[0], row: $0[1])}
    }
}
