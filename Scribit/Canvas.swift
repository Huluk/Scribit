//
//  Canvas.swift
//  Scribit
//
//  Created by Lars Hansen on 2015-12-29.
//  Copyright © 2015 Lars Hansen. All rights reserved.
//

import Cocoa

class Canvas: WTView {
    @IBOutlet var document: Document!
    
    var currentPageIndex = 0
    
    func drawLine(line: Line) {
        line.color.set()
        let path = NSBezierPath()
        path.moveToPoint(line.start)
        path.lineToPoint(line.end)
        path.stroke()
    }
    
    override func drawRect(dirtyRect: NSRect) {
        currentPage().backgroundColor.set()
        NSRectFill(dirtyRect)
        for line in currentPage().lines { // TODO use only lines in rect
            drawLine(line)
        }
    }
    
    override func keyDown(event: NSEvent) {
        switch event.keyCode {
        case 123: previousPage() // left arrow
        case 124: nextPage() // right arrow
        default: break
        }
    }
    
    func currentPage() -> Page {
        return document.pages[currentPageIndex]
    }
    
    func nextPage() {
        if currentPageIndex < document.pages.count - 1 {
            currentPageIndex++
            needsDisplay = true
        }
    }
    
    func previousPage() {
        if currentPageIndex > 0 {
            currentPageIndex--
            needsDisplay = true
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
