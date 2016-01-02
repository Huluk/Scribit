//
//  Brush.swift
//  Scribit
//
//  Created by Lars Hansen on 2016-01-02.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

import Cocoa

class Brush: NSObject,NSCoding {
    let archiveSizeKey = "archiveBrushSizeKey"
    
    var lineCapStyle: NSLineCapStyle { return .RoundLineCapStyle }
    
    var name: String
    var color: NSColor
    var size: CGFloat
    
    init(name: String, color: NSColor, size: CGFloat) {
        self.name = name
        self.color = color
        self.size = size
    }
    
    required init?(coder decoder: NSCoder) {
        self.name = decoder.decodeObject() as! String
        self.color = decoder.decodeObject() as! NSColor
        self.size = CGFloat(decoder.decodeFloatForKey(archiveSizeKey))
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(name)
        coder.encodeObject(color)
        coder.encodeFloat(Float(size), forKey: archiveSizeKey)
    }
    
    func colorFromPressure(pressure: Float) -> NSColor {
        return color
    }
    
    func sizeFromPressure(pressure: Float) -> CGFloat {
        return size
    }
}
