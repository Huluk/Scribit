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
    
    var pageViews = [Page : PageView]()
    
    func linkDocument(document: Document) {
        self.document = document
        goToPage(currentPageIndex)
    }
    
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        currentLine = Line(brush: currentBrush)
        document!.addLineOnPage(line: currentLine!, page: currentPage)
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        let previousMousePosition = mousePosition
        super.mouseDragged(theEvent)
        currentLine!.addSegment(LineSegment(start: previousMousePosition, end: mousePosition, pressure: penPressure))
        needsDisplay = true
        pageView(currentPage).updateLine(currentLine!)
        
        /*var keepDragging = true
        while (keepDragging) {
            if let event = self.window!.nextEventMatchingMask(
                Int(NSEventMask.LeftMouseUpMask.union(.LeftMouseDraggedMask).rawValue))
            {
                switch(event.type) {
                case .LeftMouseDragged: drawCurrentDataFromEvent(event)
                case .LeftMouseUp: keepDragging = false
                default: break
                }
            }
        }*/
    }
    
    override func mouseUp(theEvent: NSEvent) {
        let previousMousePosition = mousePosition
        super.mouseUp(theEvent)
        currentLine!.addSegment(LineSegment(start: previousMousePosition, end: mousePosition, pressure: penPressure))
        currentLine!.finishDrawing()
        pageView(currentPage).refreshLine(currentLine!)
        currentLine = nil
    }
    
    /*
    func drawCurrentDataFromEvent(event: NSEvent) {
        let path = NSBezierPath()
        let currentLoc = convertPoint(event.locationInWindow, fromView: nil)
        let pressure = event.pressure
        lockFocus()
        path.lineCapStyle = currentBrush.lineCapStyle
        path.lineWidth = currentBrush.sizeFromPressure(pressure)
        currentBrush.colorFromPressure(pressure).set()
        path.moveToPoint(mousePosition)
        path.lineToPoint(currentLoc)
        path.stroke()
        unlockFocus()
        mousePosition = currentLoc
        window!.flushWindow() // TODO change
        NSLog("fr \(frame) bou \(bounds) last \(mousePosition) curr \(currentLoc)")
        
    }*/
    
    func reload() {
        rescale(currentPage.size())
        if let _ = subviews.last as? PageView {
            subviews.removeLast()
        }
        addSubview(pageView(currentPage))
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
    
    func addLine(line: Line, onPage pageIndex: Int) {
        pageView(document.pages[pageIndex]).addLine(line)
        if (pageIndex != currentPageIndex) {
            goToPage(pageIndex)
        }
    }
    
    func deleteLine(line: Line, onPage pageIndex: Int) {
        pageView(document.pages[pageIndex]).deleteLine(line)
        if (pageIndex != currentPageIndex) {
            goToPage(pageIndex)
        }
    }
    
    var currentPage: Page! {
        if document != nil {
            return document.pages[currentPageIndex]
        } else {
            return nil
        }
    }
    
    var currentBrush: Brush {
        return document.brushes[currentBrushIndex]
    }
    
    func goToPage(pageIndex: Int) -> Bool {
        if pageIndex >= 0 && pageIndex < document.pages.count {
            currentPageIndex = pageIndex
            reload()
            document.updateWindowTitle()
            return true
        } else {
            return false
        }
    }
    
    private func pageView(page: Page) -> PageView {
        if pageViews[page] == nil {
            pageViews[page] = PageView(page: page, frame: bounds)
        }
        return pageViews[page]!
    }
    
    // Return the number of pages available for printing
    override func knowsPageRange(range: NSRangePointer) -> Bool {
        range.initialize(NSMakeRange(1, document.pages.count))
        return true
    }
    
    // Return the drawing rectangle for a particular page number
    override func rectForPage(pageIndex: Int) -> NSRect {
        currentPageIndex = pageIndex - 1
        reload()
        return document.pages[currentPageIndex].bounds
    }
}
