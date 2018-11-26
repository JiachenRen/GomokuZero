//
//  BoardTextureView.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/6/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Cocoa

@IBDesignable class BoardTextureView: NSView {

    @IBInspectable var image = NSImage(named: "board_b") {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if self.inLiveResize {
            return
        }
        self.wantsLayer = true
        image?.draw(in: dirtyRect)
    }
    
    override func viewDidEndLiveResize() {
        setNeedsDisplay(bounds)
    }
    
    
}
