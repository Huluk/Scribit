//
//  Brush.swift
//  Scribit
//
//  Created by Lars Hansen on 2016-01-02.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

import Cocoa

enum BrushType : Int {
    case Pen = 2, Highlighter = 0, Eraser = -3,
    // for testing only
    CroppedPen = 3, CroppedHighlighter = 1
}

class Brush: NSObject,NSCoding {
    let archiveSizeKey = "archiveBrushSizeKey"
    let archiveTypeKey = "archiveBrushTypeKey"
    
    var lineCapStyle: NSLineCapStyle { return .RoundLineCapStyle }
    
    var name: String
    var color: NSColor
    var size: CGFloat
    let type: BrushType
    
    static let defaultPen = Brush(
        name: NSLocalizedString("Default Pen", comment: "name of default pen brush"),
        color: NSColor.blackColor(), size: 1, type: .Pen)
    static let defaultHighlighter = Brush(
        name: NSLocalizedString("Default Highlighter", comment: "name of default highligher brush"),
        color: NSColor.yellowColor(), size: 18, type: .Highlighter)
    
    init(name: String, color: NSColor, size: CGFloat, type: BrushType) {
        self.name = name
        self.color = color
        self.size = size
        self.type = type
    }
    
    required init?(coder decoder: NSCoder) {
        self.name = decoder.decodeObject() as! String
        self.color = decoder.decodeObject() as! NSColor
        self.size = CGFloat(decoder.decodeFloatForKey(archiveSizeKey))
        self.type = BrushType(rawValue: decoder.decodeIntegerForKey(archiveTypeKey))!
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(name)
        coder.encodeObject(color)
        coder.encodeFloat(Float(size), forKey: archiveSizeKey)
        coder.encodeInteger(type.rawValue, forKey: archiveTypeKey)
    }
    
    func colorFromPressure(pressure: Float) -> NSColor {
        return color
    }
    
    func sizeFromPressure(pressure: Float) -> CGFloat {
        return size
    }
    
    var widestSize: CGFloat {
        return size
    }
}
