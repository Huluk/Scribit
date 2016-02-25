//
//  Canvas.swift
//  Scribit
//
//  Created by Lars Hansen on 2015-12-29.
//  Copyright © 2015 Lars Hansen. All rights reserved.
//

import Cocoa

class Canvas: WTView {
    let margin:CGFloat = 300
    
    @IBOutlet var document: Document!
    
    var currentPageIndex = 0
    var currentBrushIndex = 0
    var currentLine: Line?
    
    func drawLine(line: Line) {
        line.brush.color.set()
        line.bezierPath().stroke()
    }
    
    override func drawRect(dirtyRect: NSRect) {
        currentPage().backgroundColor.set()
        NSRectFill(dirtyRect)
        for line in currentPage().lines {
            if NSIntersectsRect(line.bounds, dirtyRect) {
                drawLine(line)
            }
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        currentLine = Line(brush: currentBrush())
        document!.addLineOnPage(line: currentLine!, page: currentPage())
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        let previousMousePosition = mousePosition
        super.mouseDragged(theEvent)
        currentLine!.addSegment(LineSegment(start: previousMousePosition, end: mousePosition, pressure: penPressure))
        needsDisplay = true
        setNeedsDisplayInRect(currentLine!.bounds)
    }
    
    override func mouseUp(theEvent: NSEvent) {
        let previousMousePosition = mousePosition
        super.mouseUp(theEvent)
        currentLine!.addSegment(LineSegment(start: previousMousePosition, end: mousePosition, pressure: penPressure))
        currentLine!.interpolateCurves()
        setNeedsDisplayInRect(currentLine!.bounds)
        currentLine = nil
    }
    
    func reload() {
        rescale(currentPage().size())
        document.updateWindowTitle()
        setNeedsDisplayInRect(bounds)
    }
    
    func rescale(targetSize: NSSize) {
        let desktop = NSMakeRect(0, 0,
            targetSize.width + 2*margin,
            targetSize.height + 2*margin)
        superview!.frame = desktop
        superview!.bounds = desktop
        frame = NSRect(origin: NSMakePoint(margin, margin), size: targetSize)
        bounds = NSRect(origin: NSPoint(), size: targetSize)
    }
    
    func currentPage() -> Page {
        return document.pages[currentPageIndex]
    }
    
    func currentBrush() -> Brush {
        return document.brushes[currentBrushIndex]
    }
    
    func goToPage(pageIndex: Int) -> Bool {
        if pageIndex >= 0 && pageIndex < document.pages.count {
            currentPageIndex = pageIndex
            reload()
            return true
        } else {
            return false
        }
    }
    
    func setNeedsDisplayInRect(invalidRect: NSRect, onPage pageIndex: Int) {
        if pageIndex == currentPageIndex {
            setNeedsDisplayInRect(invalidRect)
        } else {
            goToPage(pageIndex)
        }
    }
    
    // Return the number of pages available for printing
    override func knowsPageRange(range: NSRangePointer) -> Bool {
        range.initialize(NSMakeRange(1, document.pages.count))
        return true
    }
    
    // Return the drawing rectangle for a particular page number
    override func rectForPage(page: Int) -> NSRect {
        currentPageIndex = page-1
        return document.pages[currentPageIndex].bounds
    }
}
