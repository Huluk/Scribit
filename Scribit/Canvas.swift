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
    @IBOutlet var delegate: CanvasWindowController!
    
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
        if delegate.cursorMode == .Draw {
            currentLine = Line(brush: currentBrush)
            document!.addLine(currentLine!, onPage: currentPage)
        } else if delegate.cursorMode == .RectSelect {
            delegate.selectionView!.origin = mousePosition
        } else if delegate.cursorMode == .Selected {
            delegate.cursorMode = .Dragging
            window!.invalidateCursorRectsForView(self) // change cursor
        }
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        let previousMousePosition = mousePosition
        super.mouseDragged(theEvent)
        if delegate.cursorMode == .Draw {
            if currentLine == nil { mouseDown(theEvent) }
            let newLineSegment = LineSegment(
                start: previousMousePosition, end: mousePosition, pressure: penPressure)
            currentLine!.addSegment(newLineSegment)
            pageView(currentPage).updateLine(currentLine!)
            setNeedsDisplayInRect(newLineSegment.bounds)
        } else if delegate.cursorMode == .RectSelect {
            delegate.selectionView!.selectTo(mousePosition)
        } else if delegate.cursorMode == .Dragging {
            // TODO later: not only on current page
            pageView(currentPage).moveCropLayers(
                mousePosition.x-previousMousePosition.x,
                mousePosition.y-previousMousePosition.y)
        }
        
        /*var keepDragging = true
        while (keepDragging) {
            if let event = window!.nextEventMatchingMask(
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
        if delegate.cursorMode == .Draw {
            currentLine!.addSegment(LineSegment(start: previousMousePosition, end: mousePosition, pressure: penPressure))
            currentLine!.finishDrawing()
            pageView(currentPage).refreshLine(currentLine!)
            currentLine = nil
        } else if delegate.cursorMode == .RectSelect {
            delegate.cursorMode = .Selected
            document.select(rect: delegate.selectionView!.selection, additive: true) // TODO cleanup
            window!.invalidateCursorRectsForView(self) // change cursor
        } else if delegate.cursorMode == .Dragging {
            // TODO change lines
            delegate.cursorMode = .Selected
            window!.invalidateCursorRectsForView(self) // change cursor
        }
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
    
    func clearPageCache(page: Page) {
        pageViews[page] = PageView(page: page, frame: bounds)
        if page == currentPage { reload() }
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
        pageView(document.pages[pageIndex]).addLine(line, layer: line.type.rawValue)
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
    
    override func resetCursorRects() {
        switch (delegate.cursorMode) {
        case .Draw:
            // TODO make beautiful drawing cursor or something
            break
        case .RectSelect:
            addCursorRect(visibleRect, cursor:NSCursor.crosshairCursor())
        case .Selected:
            addCursorRect(visibleRect, cursor:NSCursor.openHandCursor())
        case .Dragging:
            addCursorRect(visibleRect, cursor:NSCursor.closedHandCursor())
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
