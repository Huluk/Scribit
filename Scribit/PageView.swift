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
    var cropTransform = NSAffineTransform()
    
    init(page: Page, frame: NSRect) {
        self.page = page
        self.layers = (0..<Page.layerCount).map({_ in NSView(frame: frame)})
        super.init(frame: frame)
        for layer in layers {
            addSubview(layer)
        }
        for (n, layer) in page.lines.enumerate() {
            for line in layer {
                addLine(line, layer: n)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addLine(line: Line, layer: Int) {
        let lineView = LineView(line: line, frame: bounds)
        lineViews[line] = lineView
        layers[layer].addSubview(lineView)
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
    
    func moveCropLayers(dx: CGFloat, _ dy: CGFloat) {
        cropTransform.translateXBy(dx, yBy: dy)
        for (n, layer) in layers.enumerate() {
            if n % 2 == 1 {
                layer.setFrameOrigin(cropTransform.transformPoint(bounds.origin))
            }
        }
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        page.backgroundColor.set()
        NSRectFill(dirtyRect)
    }
}
