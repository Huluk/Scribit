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
        addLine(line, crop: false)
    }
    
    func addLine(line: Line, crop: Bool) {
        lines[line.defaultLayer() + Int(crop)].append(line)
    }
    
    func deleteLine(line: Line) {
        let n = line.defaultLayer()
        if lines[n].last == line {
            lines[n].removeLast()
        } else if lines[n+1].last == line {
            lines[n+1].removeLast()
        } else if let index = lines[n].indexOf(line) {
            lines[n].removeAtIndex(index)
        } else if let index = lines[n+1].indexOf(line) {
            lines[n+1].removeAtIndex(index)
        } else {
            NSException(name: "line not found",
                reason:"could not delete line `\(line)' on page `\(self)'!",
                userInfo: nil).raise()
        }
    }
    
    func cropLine(line: Line) {
        let n = line.defaultLayer()
        let index = lines[n].indexOf(line)!
        lines[n+1].append(lines[n].removeAtIndex(index))
    }
    
    func uncropLine(line: Line) {
        let n = line.defaultLayer()
        let index = lines[n+1].indexOf(line)!
        lines[n].append(lines[n+1].removeAtIndex(index))
    }
    
    func allLines() -> FlattenBidirectionalCollection<[[Line]]> {
        return lines.flatten()
    }
    
    func crop(rect rect: NSRect, undoManager: NSUndoManager) {
        for n in 0..<Page.layerCount {
            if (n % 2 == 1) { continue }
            var keepInLayer = [Line]()
            for line in lines[n] {
                let (inside: ins, outside: outs) = line.intersectingSegmentRanges(rect)
                if ins.isEmpty {
                    keepInLayer.append(line)
                } else if outs.isEmpty {
                    addLine(line, crop: true)
                    undoManager.prepareWithInvocationTarget(self).uncropLine(line)
                } else {
                    undoManager.prepareWithInvocationTarget(self).addLine(line)
                    addSplits(line, ins, crop: true, undoManager: undoManager)
                    addSplits(line, outs, crop: false, undoManager: undoManager)
                    keepInLayer.append(lines[n].last!)
                }
            }
            lines[n] = keepInLayer
        }
    }
    
    func addSplits(line: Line, _ selection: [Range<Int>], crop: Bool, undoManager: NSUndoManager) {
        for range in selection {
            addLine(Line(line: line, segmentRange: range), crop: crop)
            undoManager.prepareWithInvocationTarget(self).deleteLine(line)
        }
    }
    
    func uncropAll(undoManager undoManager: NSUndoManager) {
        for n in 0..<Page.layerCount {
            if n % 2 == 1 { // crop layer
                for line in lines[n] {
                    uncropLine(line)
                    undoManager.prepareWithInvocationTarget(self).cropLine(line)
                }
            }
        }
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
