//
//  Configuration.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/4/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class Configuration {
    var algorithm: Algorithm {
        let config = cellConfigs[1] as! SegueConfig
        return Algorithm(rawValue: config.subtitle)!
    }
    var enabled: Bool {
        let config = cellConfigs[0] as! SwitchConfig
        return config.isOn
    }
    var cellConfigs: [CellConfig]
    
    init(_ algorithm: Algorithm, enabled: Bool) {
        let idx = Algorithm.all.firstIndex(of: algorithm)!
        
        cellConfigs = [
            SwitchConfig(title: "Enabled", isOn: enabled),
            SegueConfig(title: "Algorithm",
                        selectedIdx: idx,
                        subtitles: Algorithm.all.map{$0.rawValue})
        ]
        cellConfigs.append(contentsOf: configs[algorithm]!)
    }
    
    private func get(_ name: String) -> CellConfig? {
        return cellConfigs.filter{$0.title == name}.first
    }
    
    private func bool(_ name: String) -> Bool? {
        return (get(name) as? ToggleConfig)?.isOn
    }
    
    private func double(_ name: String) -> Double? {
        return (get(name) as? StepperConfig)?.val
    }
    
    private func int(_ name: String) -> Int {
        return Int(double(name)!)
    }
    
    /// Resolve Strategy from cell configuration UI elements
    func resolveStrategy() -> Strategy {
        let randomizedSelection = bool("Randomized Selection") ?? true
        let iterativeDeepening = bool("Iterative Deepening") ?? true
        let timeout = double("Timeout (s)") ?? 5
        var strategy = Strategy()
        strategy.randomizedSelection = randomizedSelection
        strategy.iterativeDeepening = iterativeDeepening
        strategy.timeLimit = timeout
        if let config = (get("Layers") as? SegmentedConfig) {
            let v = config.subtitles[config.selectedIdx].lowercased()
            strategy.layers = IterativeDeepeningCortex.Layers(rawValue: v)!
        }
        return strategy
    }
    
    /// Resolve Personality
    func resolvePersonality() -> Personality {
        switch algorithm {
        case .heuristic: return .heuristic
        case .zeroSum: return .zeroSum
        case .minimax, .negaScout:
            let d = int("Depth")
            let b = int("Breadth")
            if algorithm == .minimax {
                return .minimax(depth: d, breadth: b)
            } else {
                return .negaScout(depth: d, breadth: b)
            }
        case .monteCarlo:
            let sim_d = int("Sim. Depth")
            let b = int("Breadth")
            let r = bool("Randomized Expansion")!
            return .monteCarlo(breadth: b, rollout: sim_d, random: r, debug: false)
        case .zeroMax:
            let d = int("Depth")
            let ext_d = int("Ext. Depth")
            let b = int("Breadth")
            let ext_pr = int("Ext. Pr.")
            return .zeroMax(depth: d, breadth: b, rolloutPr: ext_pr, simDepth: ext_d)
        }
    }
}

enum Algorithm: String {
    static let all: [Algorithm] = [.heuristic, .zeroSum, .minimax, .negaScout, .monteCarlo, .zeroMax]
    
    case heuristic = "Heuristic"
    case zeroSum = "Zero Sum"
    case minimax = "Minimax"
    case negaScout = "NegaScout (PVS)"
    case monteCarlo = "MCTS"
    case zeroMax = "Zero Max"
}

var blackConfig = Configuration(.zeroMax, enabled: true)
var whiteConfig = Configuration(.zeroMax, enabled: false)

// Default configuration for all algorithms.
let configs: [Algorithm: [CellConfig]] = [
    .heuristic: [
        ToggleConfig(title: "Randomized Selection", isOn: true)
    ],
    .zeroSum: [
        ToggleConfig(title: "Randomized Selection", isOn: true)
    ],
    .minimax: [
        ToggleConfig(title: "Randomized Selection", isOn: true),
        StepperConfig(title: "Timeout (s)", min: 1, max: 60, val: 15),
        StepperConfig(title: "Depth", min: 0, max: 10, val: 4),
        StepperConfig(title: "Breadth", min: 1, max: 20, val: 6),
        ToggleConfig(title: "Iterative Deepening", isOn: true),
        SegmentedConfig(title: "Layers", selectedIdx: 1, subtitles: ["All", "Even", "Odd"]),
    ],
    .negaScout: [
        ToggleConfig(title: "Randomized Selection", isOn: true),
        StepperConfig(title: "Timeout (s)", min: 1, max: 60, val: 15),
        StepperConfig(title: "Depth", min: 0, max: 10, val: 4),
        StepperConfig(title: "Breadth", min: 1, max: 20, val: 6),
        ToggleConfig(title: "Iterative Deepening", isOn: true),
        SegmentedConfig(title: "Layers", selectedIdx: 1, subtitles: ["All", "Even", "Odd"]),
    ],
    .monteCarlo: [
        ToggleConfig(title: "Randomized Expansion", isOn: true),
        StepperConfig(title: "Timeout (s)", min: 1, max: 60, val: 3),
        StepperConfig(title: "Sim. Depth", min: 1, max: 20, val: 6),
        StepperConfig(title: "Breadth", min: 1, max: 20, val: 10),
    ],
    .zeroMax: [
        ToggleConfig(title: "Randomized Selection", isOn: true),
        StepperConfig(title: "Timeout (s)", min: 1, max: 60, val: 15),
        StepperConfig(title: "Depth", min: 0, max: 10, val: 2),
        StepperConfig(title: "Ext. Depth", min: 0, max: 20, val: 8),
        StepperConfig(title: "Breadth", min: 1, max: 20, val: 10),
        StepperConfig(title: "Ext. Pr.", min: 1, max: 100, val: 100),
        ToggleConfig(title: "Iterative Deepening", isOn: true),
        SegmentedConfig(title: "Layers", selectedIdx: 0, subtitles: ["All", "Even", "Odd"]),
    ]
]
