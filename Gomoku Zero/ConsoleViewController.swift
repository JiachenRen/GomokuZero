//
//  ConsoleViewController.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/21/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Cocoa

class ConsoleViewController: NSViewController {

    
    @IBOutlet weak var blackCheckBox: NSButton! // Done
    @IBOutlet weak var blackAlgorithm: NSPopUpButton! // Done
    @IBOutlet weak var blackMaxThinkingTime: NSTextField! // Done
    @IBOutlet weak var blackDepth: NSTextField! // Done
    @IBOutlet weak var blackBreadth: NSTextField! // Done
    @IBOutlet weak var blackIterativeDeepening: NSButton! // Done
    @IBOutlet weak var blackDebug: NSButton! // Done
    @IBOutlet weak var blackSimulationDepth: NSTextField! // Done
    @IBOutlet weak var blackRandomExpansion: NSButton! // Done
    
    @IBOutlet weak var whiteCheckBox: NSButton!
    @IBOutlet weak var whiteAlgorithm: NSPopUpButton!
    @IBOutlet weak var whiteMaxThinkingTime: NSTextField!
    @IBOutlet weak var whiteDepth: NSTextField!
    @IBOutlet weak var whiteBreadth: NSTextField!
    @IBOutlet weak var whiteIterativeDeepening: NSButton!
    @IBOutlet weak var whiteDebug: NSButton!
    @IBOutlet weak var whiteSimulationDepth: NSTextField!
    @IBOutlet weak var whiteRandomExpansion: NSButton!
    
    @IBOutlet weak var boardDimension: NSComboBox! // Done
    @IBOutlet weak var showStepNumber: NSButton! // Done
    
    @IBOutlet weak var enableVisualization: NSButton!
    @IBOutlet weak var activeCoordinates: NSButton!
    @IBOutlet weak var historyStack: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func spawnNewGame(_ sender: NSButton) {
        let boardWindowController = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "board-window") as! BoardWindowController
        
        // Configure visualization properties
        let vc = boardWindowController.viewController as BoardViewController
        vc.boardView.overlayStepNumber = showStepNumber.state == .on
        vc.boardView.zeroPlusVisualization = enableVisualization.state == .on
        vc.boardView.activeMapVisible = activeCoordinates.state == .on
        vc.boardView.zeroPlusHistoryVisible = historyStack.state == .on
        
        // Configure board properties
        let board = boardWindowController.board
        let dim = boardDimension.stringValue // Translate board dimension
        if dim == "" { board.dimension = 19} else {
            let idx = dim.firstIndex(of: "x")
            if idx == nil {
                board.dimension = Int(dim) ?? 19
            }
            var num = String(dim[..<idx!])
            num.removeAll{$0 == " "}
            board.dimension = Int(num) ?? 19
        }
        
        // Configure Zero+ AI
        let zero1 = ZeroPlus(), zero2 = ZeroPlus()
        zero1.identity = .black
        zero1.delegate = board
        zero1.visDelegate = vc
        zero2.identity = .white
        zero2.delegate = board
        zero2.visDelegate = vc
        if blackCheckBox.state == .on {
            let depth = Int(blackDepth.stringValue) ?? 6
            let breadth = Int(blackBreadth.stringValue) ?? 3
            let iterativeDeepening = blackIterativeDeepening.state == .on
            let debug = blackDebug.state == .on
            let playout = Int(blackSimulationDepth.stringValue) ?? 5
            let randExpansion = blackRandomExpansion.state == .on
            switch blackAlgorithm.selectedItem!.title {
            case "Heuristic": zero1.personality = .basic
            case "Minimax":
                zero1.personality = .search(depth: depth, breadth: breadth)
                zero1.iterativeDeepening = iterativeDeepening
            case "Monte Carlo":
                zero1.personality = .monteCarlo(breadth: breadth, playout: playout, random: randExpansion, debug: debug)
            default: break
            }
            zero1.maxThinkingTime = TimeInterval(blackMaxThinkingTime.stringValue) ?? 5
            board.zeroPlus = zero1
        }
        if whiteCheckBox.state == .on {
            let depth = Int(whiteDepth.stringValue) ?? 6
            let breadth = Int(whiteBreadth.stringValue) ?? 3
            let iterativeDeepening = whiteIterativeDeepening.state == .on
            let debug = whiteDebug.state == .on
            let playout = Int(whiteSimulationDepth.stringValue) ?? 5
            let randExpansion = whiteRandomExpansion.state == .on
            switch whiteAlgorithm.selectedItem!.title {
            case "Heuristic": zero2.personality = .basic
            case "Minimax":
                zero2.personality = .search(depth: depth, breadth: breadth)
                zero2.iterativeDeepening = iterativeDeepening
            case "Monte Carlo":
                zero2.personality = .monteCarlo(breadth: breadth, playout: playout, random: randExpansion, debug: debug)
            default: break
            }
            zero2.maxThinkingTime = TimeInterval(whiteMaxThinkingTime.stringValue) ?? 5
            board.zeroPlus2 = zero2
        }
        
        if board.zeroPlus2 != nil {
            board.zeroXzero = true
        }
        
        boardWindowController.showWindow(self)
        board.requestZeroBrainStorm()
    }
}
