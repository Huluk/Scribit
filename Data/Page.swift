//
//  Page.swift
//  Scribit
//
//  Created by Lars Hansen on 2015-12-29.
//  Copyright © 2015 Lars Hansen. All rights reserved.
//

import Cocoa

class Page: NSObject, NSCoding {
    static let layerCount = 4
    
    var bounds: NSRect
    var backgroundColor: NSColor
    var lines: [[Line]]
    
    init(pageRect: NSRect, backgroundColor: NSColor) {
        self.bounds = pageRect
        self.backgroundColor = backgroundColor
        self.lines = (0..<Page.layerCount).map({_ in [Line]()})
    }
    
    required init(coder: NSCoder) {
        bounds = coder.decodeRect()
        backgroundColor = coder.decodeObject() as! NSColor
        lines = coder.decodeObject() as! [[Line]]
    }
    
    func addLine(line: Line) {
        lines[layer(line)].append(line)
    }
    
    func deleteLine(line: Line) {
        deleteLineFromLayer(line, layer: &lines[layer(line)])
    }
    
    private func deleteLineFromLayer(line: Line, inout layer: [Line]) {
        if layer.last == line {
            layer.removeLast()
        } else {
            layer.removeAtIndex(layer.indexOf(line)!)
        }
    }
    
    func layer(line: Line) -> Int {
        return line.type.rawValue
    }
    
    func allLines() -> FlattenBidirectionalCollection<[[Line]]> {
        return lines.flatten()
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeRect(bounds)
        coder.encodeObject(backgroundColor)
        coder.encodeObject(lines)
    }
    
    func size() -> NSSize {
        return bounds.size
    }
}
