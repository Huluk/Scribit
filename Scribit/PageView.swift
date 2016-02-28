//
//  PageView.swift
//  Scribit
//
//  Created by Lars Hansen on 2016-02-27.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

import Cocoa

class PageView: NSView {
    unowned let page: Page
    var lineViews = [Line : LineView]()
    var layers: [NSView]
    
    init(page: Page, frame: NSRect) {
        self.page = page
        self.layers = (0..<Page.layerCount).map({_ in NSView(frame: frame)})
        super.init(frame: frame)
        for layer in layers {
            addSubview(layer)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addLine(line: Line) {
        let lineView = LineView(line: line, frame: bounds)
        lineViews[line] = lineView
        layers[line.type.rawValue].addSubview(lineView)
    }
    
    func deleteLine(line: Line) {
        lineViews[line]!.removeFromSuperview()
        lineViews.removeValueForKey(line)
    }
    
    func updateLine(line: Line) {
        lineViews[line]!.update()
    }
    
    func refreshLine(line: Line) {
        lineViews[line]!.refresh()
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        page.backgroundColor.set()
        NSRectFill(dirtyRect)
    }
}
