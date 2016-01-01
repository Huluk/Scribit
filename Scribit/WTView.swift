//
//  WTView.swift
//  Scribit
//
//  Created by Lars Hansen on 2016-01-01.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

import Cocoa

class WTView : NSView {
    let WTViewUpdatedNotification = "WTViewStatsUpdatedNotification"
    
    override var opaque: Bool { return true }
    override var acceptsFirstResponder: Bool { return true }
    
    var knownDevices = DeviceTracker()
    var mousePosition = NSPoint()
    var penPressure: Float = 0.0
    
    override func becomeFirstResponder() -> Bool {
        // If do not use the notification method to send proximity events to
        // all objects then you will need to ask the Tablet Driver to resend
        // the last proximity event every time your view becomes the first
        // responder. You can do that here by uncommenting the following line.
        
        // ResendLastTabletEventofTye(eEventProximity)
        return true
    }
    
    override func awakeFromNib() {
        // Must inform the window that we want mouse moves after all object
        // are created and linked.
        // Let our internal routine make the API call so that everything
        // stays in sych. Change the value in the init routine to change
        // the default behavior
    
        // If you are running Tablet Driver version 4.7.5 or higher, you do not
        // need to listen for embedded proximity events in mouse moves. Proximity
        // events will always be issued as pure tablet proximity events. (Embedded
        // proximity events are also issued for backwards compatability.
        // However, if you are running 4.7.3 or less, Mouse moves must be captured
        // if you want to recieve Proximity Events
        window!.acceptsMouseMovedEvents = true
    
        //Must register to be notified when device come in and out of Prox
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleProximity:", name: kProximityNotification, object: nil)
    }
    
    private func handleMouseEvent(mouseEvent: NSEvent) {
        mousePosition = convertPoint(mouseEvent.locationInWindow, fromView: nil)
        penPressure = mouseEvent.type == NSEventType.MouseMoved ? 0.0 : mouseEvent.pressure
        
        /*
         * mouseEvent.rawTabletPressure / .scaledTabletPressure
         * mouseEvent.getAbsoluteX:Y:Z:
         * possible things to extract:
         * mouseEvent.tilt -> NSPoint x y
         * mouseEvent.rotationInDegrees / .rotationInRadians
         *
         * mouseEvent.deviceID
         */
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            WTViewUpdatedNotification, object: self)
    }
    
    override func mouseDown(theEvent: NSEvent) {
        handleMouseEvent(theEvent)
    }
    
    override func mouseUp(theEvent: NSEvent) {
        handleMouseEvent(theEvent)
    }
    
    override func mouseMoved(theEvent: NSEvent) {
        if (!validTabletDevice(theEvent)) { return }
        handleMouseEvent(theEvent)
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        if (!validTabletDevice(theEvent)) { return }
        handleMouseEvent(theEvent)
    }
    
    private func validTabletDevice(theEvent: NSEvent) -> Bool {
        if (theEvent.isTabletPointerEvent()) {
            if (theEvent.deviceID() != knownDevices.currentDevice().ident()) {
                // The deviceID the event came from does not match the deviceID of
                // the device that was thought to be on the Tablet. Must have
                // missed a Proximity Notification. Get the Tablet to resend it.
                WacomTabletDriver.resendLastTabletEventOfType(ProximityEvent)
                return false
            }
        }
        return true
    }

    /*
    // - (void) handleProximity:(NSNotification *)proxNotice
    
    // The proximity notification is based on the Proximity Event.
    // (see CarbonEvents.h). The proximity notification will give you detailed
    // information about the device that was either just placed on, or just
    // taken off of the tablet.
    //
    // In this sample code, the Proximity notification is used to determine if
    // the pen TIP or ERASER is being used. This information is not provided in
    // the embedded tablet event.
    //
    // Also, on the Intous line of tablets, each transducer has a unique ID,
    // even when different transducers are of the same type. We get that
    // information here so we can keep track of the Color assigned to each
    // transducer.
    //
    - (void) handleProximity:(NSNotification *)proxNotice
    {
    NSDictionary *proxDict = [proxNotice userInfo];
    UInt8	enterProximity;
    UInt8 pointerType;
    UInt16 deviceID;
    UInt16 pointerID;
    
    [[proxDict objectForKey:kEnterProximity] getValue:&enterProximity];
    [[proxDict objectForKey:kPointerID] getValue:&pointerID];
    
    // Only interested in Enter Proximity for 1st concurrent device
    if(enterProximity != 0 && pointerID == 0)
    {
    [[proxDict objectForKey:kPointerType] getValue:&pointerType];
    erasing = (pointerType == EEraser);
    
    [[proxDict objectForKey:kDeviceID] getValue:&deviceID];
    
    if ([knownDevices setCurrentDeviceByID: deviceID] == NO)
    {
    //must be a new device
    Transducer *newDevice = [[Transducer alloc]
    initWithIdent: deviceID
    color: [NSColor blackColor]];
    
    [knownDevices addDevice:newDevice];
    [knownDevices setCurrentDeviceByID: deviceID];
    }
    
    [[NSNotificationCenter defaultCenter]
    postNotificationName:WTViewUpdatedNotification
    object: self];
    }
    }
*/
}
