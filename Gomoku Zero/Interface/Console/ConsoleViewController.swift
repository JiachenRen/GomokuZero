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
    @IBOutlet weak var blackRolloutProbability: NSTextField!
    @IBOutlet weak var blackThreshold: NSTextField!
    @IBOutlet weak var blackLayers: NSSegmentedControl!
    @IBOutlet weak var blackRandomizedSelection: NSButton!
    @IBOutlet weak var blackSubjectiveBias: NSButton!
    
    @IBOutlet weak var whiteCheckBox: NSButton!
    @IBOutlet weak var whiteAlgorithm: NSPopUpButton!
    @IBOutlet weak var whiteMaxThinkingTime: NSTextField!
    @IBOutlet weak var whiteDepth: NSTextField!
    @IBOutlet weak var whiteBreadth: NSTextField!
    @IBOutlet weak var whiteIterativeDeepening: NSButton!
    @IBOutlet weak var whiteDebug: NSButton!
    @IBOutlet weak var whiteSimulationDepth: NSTextField!
    @IBOutlet weak var whiteRandomExpansion: NSButton!
    @IBOutlet weak var whiteRolloutProbability: NSTextField!
    @IBOutlet weak var whiteThreshold: NSTextField!
    @IBOutlet weak var whiteLayers: NSSegmentedControl!
    @IBOutlet weak var whiteRandomizedSelection: NSButton!
    @IBOutlet weak var whiteSubjectiveBias: NSButton!
    
    @IBOutlet weak var boardDimension: NSComboBox! // Done
    @IBOutlet weak var showStepNumber: NSButton! // Done
    
    @IBOutlet weak var enableVisualization: NSButton!
    @IBOutlet weak var activeCoordinates: NSButton!
    @IBOutlet weak var historyStack: NSButton!
    
    @IBOutlet weak var strictEqualityCheck: NSButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func resolveLayers(_ control: NSSegmentedControl) -> IterativeDeepeningCortex.Layers {
        switch control.selectedSegment {
        case 0: return .odds
        case 1: return .evens
        case 2: return .all
        default: fatalError()
        }
    }
    
    func configure(_ wc: BoardWindowController, cleanSlate: Bool = true) {
        // Configure visualization properties
        let vc = wc.viewController as BoardViewController
        vc.boardView.overlayStepNumber = showStepNumber.state == .on
        vc.boardView.visualizationEnabled = enableVisualization.state == .on
        vc.boardView.activeMapVisible = activeCoordinates.state == .on
        vc.boardView.historyVisible = historyStack.state == .on
        
        // Configure board properties
        let board = wc.board
        func constraint(_ dim: String) -> Int {
            if let d = Int(dim) {
                return d > 0 && d <= Zobrist.hashedHeuristicMaps.count ? d : 19
            }
            return 19
        }
        let dim = boardDimension.stringValue // Translate board dimension
        if cleanSlate {
            if dim == "" { board.dimension = 19} else {
                let idx = dim.firstIndex(of: "x")
                if idx == nil {
                    board.dimension = constraint(dim)
                } else  {
                    var num = String(dim[..<idx!])
                    num.removeAll{$0 == " "}
                    board.dimension = constraint(num)
                }
            }
        }
        
        // Configure Zobrist
        Zobrist.strictEqualityCheck = strictEqualityCheck.state == .on
        
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
            let simDepth = Int(blackSimulationDepth.stringValue) ?? 10
            let randExpansion = blackRandomExpansion.state == .on
            zero1.randomizedSelection = blackRandomizedSelection.state == .on
            zero1.subjectiveBias = blackSubjectiveBias.state == .on
            zero1.layers = resolveLayers(blackLayers)
            
            switch blackAlgorithm.selectedItem!.title {
            case "Heuristic": zero1.personality = .basic
            case "Minimax":
                zero1.personality = .search(depth: depth, breadth: breadth)
                zero1.iterativeDeepening = iterativeDeepening
            case "Monte Carlo":
                zero1.personality = .monteCarlo(breadth: breadth, rollout: simDepth, random: randExpansion, debug: debug)
            case "ZeroMax":
                let rolloutPr = Int(blackRolloutProbability.stringValue) ?? 100
                let threshold = Int(blackThreshold.stringValue) ?? Threat.interesting
                zero1.personality = .zeroMax(depth: depth, breadth: breadth, rolloutPr: rolloutPr, simDepth: simDepth, threshold: threshold)
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
            let simDepth = Int(whiteSimulationDepth.stringValue) ?? 10
            let randExpansion = whiteRandomExpansion.state == .on
            zero2.randomizedSelection = whiteRandomizedSelection.state == .on
            zero2.subjectiveBias = whiteSubjectiveBias.state == .on
            zero2.layers = resolveLayers(whiteLayers)
            
            switch whiteAlgorithm.selectedItem!.title {
            case "Heuristic": zero2.personality = .basic
            case "Minimax":
                zero2.personality = .search(depth: depth, breadth: breadth)
                zero2.iterativeDeepening = iterativeDeepening
            case "Monte Carlo":
                zero2.personality = .monteCarlo(breadth: breadth, rollout: simDepth, random: randExpansion, debug: debug)
            case "ZeroMax":
                let rolloutPr = Int(whiteRolloutProbability.stringValue) ?? 100
                let threshold = Int(whiteThreshold.stringValue) ?? Threat.interesting
                zero2.personality = .zeroMax(depth: depth, breadth: breadth, rolloutPr: rolloutPr, simDepth: simDepth, threshold: threshold)
            default: break
            }
            zero2.maxThinkingTime = TimeInterval(whiteMaxThinkingTime.stringValue) ?? 5
            board.zeroPlus2 = zero2
        }
        
        if blackCheckBox.state == .off && whiteCheckBox.state == .on {
            // Special case, disable default board AI
            board.zeroPlus = zero2
            board.zeroPlus2 = nil
            board.zeroIdentity = .white
        } else {
            board.zeroIdentity = .black
        }
        
        if board.zeroPlus2 != nil {
            board.zeroXzero = true
        }
        
        wc.showWindow(self)
        board.requestZeroBrainStorm()
    }
    
    
    @IBAction func spawnNewGame(_ sender: NSButton) {
        let boardWindowController = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "board-window") as! BoardWindowController
        configure(boardWindowController)
    }
    
    @IBAction func assign(_ sender: NSButton) {
        BoardWindowController.open { controllers in
            controllers.forEach { [unowned self] in
                self.configure($0, cleanSlate: false)
            }
        }
    }
}
