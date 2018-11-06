//
//  AppDelegate.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var toggleTexture: NSMenuItem!
    
    @IBOutlet weak var darkTexture: NSMenuItem!
    @IBOutlet weak var normalTexture: NSMenuItem!
    @IBOutlet weak var lightTexture: NSMenuItem!
    
    @IBOutlet weak var depthMI: NSMenuItem!
    @IBOutlet weak var breadthMI: NSMenuItem!
    
    @IBOutlet weak var iterativeDeepening: NSMenuItem!
    @IBOutlet weak var setTimeLimit: NSMenuItem!
    @IBOutlet weak var maxSearchTime: NSMenuItem!
    
    var consoleWindowController: ConsoleWindowController?
    
    var textureMenuItems: [NSMenuItem?] {
        return [
            darkTexture,
            normalTexture,
            lightTexture
        ]
    }
    
    var activeBoard: Board? {
        return activeController?.board
    }
    
    var activeController: BoardViewController? {
        return NSApplication.shared.mainWindow?.windowController?.contentViewController as? BoardViewController
    }
    
    var activeWindowController: BoardWindowController? {
        return NSApplication.shared.mainWindow?.windowController as? BoardWindowController
    }
    
    var activeBoardView: BoardView? {
        return activeController?.boardView
    }
    
    var windowControllers: [BoardWindowController] {
        return NSApplication.shared.windows.map{$0.windowController as? BoardWindowController}
            .filter{$0 != nil}
            .map{$0!}
    }
    
    var viewControllers: [BoardViewController] {
        return windowControllers.map{$0.viewController}
    }
    
    @IBAction func zeroPlus(_ sender: NSMenuItem) {
        switch sender.title {
        case "Black": activeBoard?.zeroIdentity = .black
            activeBoard?.requestZeroBrainStorm()
        case "White": activeBoard?.zeroIdentity = .white
            activeBoard?.requestZeroBrainStorm()
        case "Off": activeBoard?.zeroIdentity = .none
        default: activeBoard?.triggerZeroBrainstorm()
        }
    }
    @IBAction func toggleStepNumber(_ sender: NSMenuItem) {
        if let b = activeBoardView?.overlayStepNumber {
            activeBoardView?.overlayStepNumber = !b
        }
    }
    
    @IBAction func toggleHighlight(_ sender: NSMenuItem) {
        if let b = activeBoardView?.highlightLastStep {
            activeBoardView?.highlightLastStep = !b
        }
    }
    @IBAction func toggleCalcDuration(_ sender: NSMenuItem) {
        if let b = activeBoardView?.showCalcDuration {
            activeBoardView?.showCalcDuration = !b
        }
    }
    
    @IBAction func openConsole(_ sender: NSMenuItem) {
        if consoleWindowController == nil {
            consoleWindowController = NSStoryboard(name: "Main", bundle: nil)
                .instantiateController(withIdentifier: "zero-console") as? ConsoleWindowController
        }
        consoleWindowController?.showWindow(self)
    }
    
    @IBAction func zeroVsZero(_ sender: NSMenuItem) {
        if let board = activeBoard {
            board.zeroXzero = !board.zeroXzero
            board.requestZeroBrainStorm()
        }
    }
    
    @IBAction func zeroPlusPersonality(_ sender: NSMenuItem) {
        switch sender.title {
        case "Heuristic": activeBoard?.zeroPlus.personality = .heuristic
        case "Custom Depth & Breadth":
            let config = getMinimaxConfig()
            if let personality = config {
                switch personality {
                case .minimax(let depth, let breadth):
                    depthMI.title = "Depth = \(depth)"
                    breadthMI.title = "Breadth = \(breadth)"
                default: break
                }
                activeBoard?.zeroPlus.personality = personality
            }
        case "Monte Carlo":
            activeBoard?.zeroPlus.personality = .monteCarlo(breadth: 2, rollout: 5, random: true, debug: true)
        case "Use Default":
            activeBoard?.zeroPlus.personality = .minimax(depth: 6, breadth: 3)
        case "Iterative Deepening":
            if let tmp = activeBoard?.zeroPlus.strategy.iterativeDeepening {
                activeBoard?.zeroPlus.strategy.iterativeDeepening = !tmp
                iterativeDeepening.state = tmp ? .off : .on
            }
        case "Set Time Limit":
            let timeLimit = setTimeLimitDialogue()
            if timeLimit < 0 {return}
            activeBoard?.zeroPlus.strategy.timeLimit = timeLimit
            maxSearchTime.title = "Max Search Time: \(timeLimit)"
        default: break
        }
    }
    
    func setTimeLimitDialogue() -> TimeInterval {
        let msg = NSAlert()
        msg.addButton(withTitle: "Set")
        msg.addButton(withTitle: "Cancel")
        msg.alertStyle = .informational
        msg.messageText = "Set time limit"
        msg.window.title = "Set Time Limit"
        msg.informativeText = "Enter the max thinking time of Zero+ in the field below; the unit is in seconds and decimal values are allowed."
        
        let box = NSComboBox(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        box.addItems(withObjectValues: ["0","1","3","5", "10","15","30","60"])
        box.placeholderString = "10"
        
        msg.accessoryView = box
        let response = msg.runModal()
        
        if (response == .alertFirstButtonReturn) {
            return TimeInterval(box.stringValue) ?? TimeInterval(box.placeholderString!)!
        } else {
            return -1
        }
    }
    
    @IBAction func zeroPlusVisualization(_ sender: NSMenuItem) {
        activeController?.updateVisPref(sender.title)
    }
    
    @IBAction func textureSelected(_ sender: NSMenuItem) {
        var texture: NSImage! = nil
        for item in textureMenuItems {
            item?.state = .off
        }
        switch sender.title {
        case "Dark":
            texture = NSImage(named: "board_dark")
            darkTexture.state = .on
        case "Light":
            texture = NSImage(named: "board_light")
            lightTexture.state = .on
        case "Normal":
            texture = NSImage(named: "board")
            normalTexture.state = .on
        default: break
        }
        viewControllers.forEach{$0.boardTextureView.image = texture}
    }
    
    @IBAction func restart(_ sender: NSMenuItem) {
        activeBoard?.restart()
    }
    
    @IBAction func undo(_ sender: NSMenuItem) {
        activeBoard?.undo()
    }
    
    @IBAction func redo(_ sender: NSMenuItem) {
        activeBoard?.redo()
    }
    
    @IBAction func save(_ sender: NSMenuItem) {
        activeWindowController?.save()
    }
    
    @IBAction func open(_ sender: NSMenuItem) {
        BoardWindowController.open()
    }
    
    @IBAction func copyToClipboard(_ sender: NSMenuItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        pasteboard.setString(activeBoard?.description ?? "", forType: .string)
    }
    
    @IBAction func paste(_ sender: Any) {
        let pasteboard = NSPasteboard.general
        var clipboardItems: [String] = []
        for element in pasteboard.pasteboardItems! {
            if let str = element.string(forType: .string) {
                clipboardItems.append(str)
            }
        }
        
        // Access the item in the clipboard
        let boardStr = clipboardItems[0]
        let rows = boardStr.split(separator: "\n")
        activeBoard?.dimension = rows.count
        activeBoard?.clear()
        
        // Update board
        var player: Piece = .black
        rows.enumerated().forEach { (r, row) in
            row.split(separator: " ").enumerated().forEach { (c, p) in
                if let piece = Piece(rawValue: String(p)) {
                    activeBoard?.set((c,r), piece)
                    if piece == .none {
                        return
                    }
                    player = player.next()
                }
            }
        }
        activeBoard?.curPlayer = player
        
        // Update display
        if let pieces = activeBoard?.pieces {
            activeBoard?.delegate?.boardDidUpdate(pieces: pieces)
        }
    }
    
    
    @IBAction func new(_ sender: NSMenuItem) {
        let dim = getNewGameDimension()
        if dim != -1 {
            let boardWindowController = NSStoryboard(name: "Main", bundle: nil)
                .instantiateController(withIdentifier: "board-window") as! BoardWindowController
            boardWindowController.board.dimension = dim
            boardWindowController.fileName = boardWindowController.fileName + "" // Trigger window title update
            boardWindowController.showWindow(self)
            if let frame = activeWindowController?.window?.frame { // There's an insignificant bug here...
                let newFrame = CGRect(x: frame.minX + 10, y: frame.minY - 10, width: frame.width, height: frame.height)
                boardWindowController.window?.setFrame(newFrame, display: true, animate: true)
            }
        }
    }
    
    private func getMinimaxConfig() -> Personality? {
        let msg = NSAlert()
        msg.addButton(withTitle: "Ok")
        msg.addButton(withTitle: "Cancel")
        msg.alertStyle = .informational
        msg.messageText = "Configure search algorithm"
        msg.window.title = "ZeroPlus Search Configuration"
        msg.informativeText = "Recommended depth is between 3 and 10 while the recommended breadth is between 2 and 5. Depth of 3, for example, means ZeroPlus will look ahead 3 steps, i.e. black > white > black, etc. The larger the depth, the slower the calculation. Breadth controls the number of steps to be considered at each depth. "
        
        let accView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 48))
        
        let depthLabel = NSTextField(frame: NSRect(x: 0, y: 24, width: 300, height: 24))
        depthLabel.textColor = NSColor.systemGray
        depthLabel.stringValue = "Depth\t\t\t\t   Breadth"
        depthLabel.isBezeled = false
        depthLabel.drawsBackground = false
        depthLabel.isEditable = false
        depthLabel.isSelectable = false
        accView.addSubview(depthLabel)
        
        let depthBox = NSComboBox(frame: NSRect(x: 0, y: 0, width: 100, height: 24))
        depthBox.addItems(withObjectValues: [3,4,5,6,7,8,9,10])
        depthBox.placeholderString = "7"
        accView.addSubview(depthBox)
        
        let breadthBox = NSComboBox(frame: NSRect(x: 150, y: 0, width: 100, height: 24))
        breadthBox.addItems(withObjectValues: [2,3,4,5])
        breadthBox.placeholderString = "3"
        accView.addSubview(breadthBox)
        
        msg.accessoryView?.addSubview(accView)
        msg.accessoryView = accView
        let response = msg.runModal()
        
        if (response == .alertFirstButtonReturn) {
            let d = Int(depthBox.stringValue) ?? Int(depthBox.placeholderString!)!
            let b = Int(breadthBox.stringValue) ?? Int(breadthBox.placeholderString!)!
            return Personality.minimax(depth: d, breadth: b)
        } else {
            return nil
        }
    }

    private func getNewGameDimension() -> Int {
        let msg = NSAlert()
        msg.addButton(withTitle: "Create")
        msg.addButton(withTitle: "Cancel")
        msg.alertStyle = .informational
        msg.messageText = "Please enter board dimension"
        msg.window.title = "Create New Game"
        msg.informativeText = "* board dimension must be between between 10 and 19"
        
        let box = NSComboBox(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        box.addItems(withObjectValues: ["15 x 15","19 x 19"])
        box.placeholderString = "19 x 19"
        
        msg.accessoryView = box
        let response = msg.runModal()
        
        if (response == .alertFirstButtonReturn) {
            let dimStr = box.stringValue
            if dimStr == "" { return 19 } else {
                let idx = box.stringValue.firstIndex(of: "x")
                if idx == nil {
                    return Int(dimStr) ?? -1
                }
                var num = String(dimStr[..<idx!])
                num.removeAll{$0 == " "} // Remove spaces
                return Int(num) ?? -1
            }
        } else {
            return -1
        }
    }
    
    @IBAction func boardTexture(_ sender: NSMenuItem) {
        if let controller = activeController {
            let bool = controller.boardTextureView.isHidden
            viewControllers.forEach{$0.boardTextureView.isHidden = !bool}
            toggleTexture.title = bool ? "Hide Board Texture" : "Show Board Texture"
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if let controller = activeController {
            toggleTexture.title = controller.boardTextureView.isHidden ?
                "Show Board Texture" : "Hide Board Texture"
            let zeroPlus = activeBoard!.zeroPlus
            switch zeroPlus.personality {
            case .minimax(let depth, let breadth):
                depthMI.title = "Depth = \(depth)"
                breadthMI.title = "Breadth = \(breadth)"
                iterativeDeepening.state = zeroPlus.strategy.iterativeDeepening ? .on : .off
            default: break
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Gomoku_Zero")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

}

