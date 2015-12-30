/*----------------------------------------------------------------------------

FILE NAME

WTView.m - Implementation file for WTView class.

COPYRIGHT

Copyright WACOM Technology, Inc. 2001.

All rights reserved.

----------------------------------------------------------------------------*/
#import "WTView.h"

#import "TabletApplication.h"
#import "TabletEvents.h"
#import "Wacom.h"
#import "WacomTabletDriver.h"

NSString *WTViewUpdatedNotification = @"WTViewStatsUpdatedNotification";

#define maxBrushSize 50.0;

@implementation WTView
///////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code here.
        mAdjustOpacity = YES;
        mAdjustSize = NO;
        mCaptureMouseMoves = [NSApp checkIfNeedToWatchMouseEvents];
        mUpdateStatsDuringDrag = YES;
        knownDevices = [[DeviceTracker alloc] init];
    }
    return self;
}



///////////////////////////////////////////////////////////////////////////
- (void)awakeFromNib
{
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
   [self setCaptureMouseMoves:[self mCaptureMouseMoves]];
   
   //Must register to be notified when device come in and out of Prox
   [[NSNotificationCenter defaultCenter] addObserver:self
               selector:@selector(handleProximity:)
               name:kProximityNotification
               object:nil];
}



///////////////////////////////////////////////////////////////////////////
- (void)mouseDown:(NSEvent *)theEvent
{
   [self handleMouseEvent:theEvent];
   
   // Save the loc the mouse down occurred at. This will be used by the
   // Drawing code during a Drag event to follow.
   mLastLoc = [self convertPoint:[theEvent locationInWindow]
                  fromView:nil];
}



///////////////////////////////////////////////////////////////////////////
- (void)mouseDragged:(NSEvent *)theEvent
{
   BOOL keepOn = YES;

	if ([theEvent isTabletPointerEvent])
	{
		if ([theEvent deviceID] != [[knownDevices currentDevice] ident])
		{
			// The deviceID the event came from does not match the deviceID of
			// the device that was thought to be on the Tablet. Must have
			// missed a Proximity Notification. Get the Tablet to resend it.
			
			[WacomTabletDriver resendLastTabletEventOfType:eEventProximity];
			return;
		}
	}
   
   // Updating the text display of the stats can take up a lot of time.
   // This can lead to less smooth curves being drawn. Toggle the
   // Update Stats During Drag menu option to see the difference.  
   if(mUpdateStatsDuringDrag)
   {
      [self drawCurrentDataFromEvent:theEvent];
      [self handleMouseEvent:theEvent];
   }
   else //Smoother Drawing
   {
      // This portion of code was copied almost verbatim from Apple's
      // Documentation on NSView.
      while (keepOn)
      {
         theEvent = [[self window] nextEventMatchingMask:NSLeftMouseUpMask |
                     NSLeftMouseDraggedMask];
         
         switch ([theEvent type])
         {
            case NSLeftMouseDragged:
               [self drawCurrentDataFromEvent:theEvent];
            break;
            
            case NSLeftMouseUp:
               keepOn = NO;
            break;
            
            default:
                     /* Ignore any other kind of event. */
            break;
         }
      }
   }
}



///////////////////////////////////////////////////////////////////////////
- (void)mouseMoved:(NSEvent *)theEvent
{
	if ([theEvent isTabletPointerEvent])
	{
		if ([theEvent deviceID] != [[knownDevices currentDevice] ident])
		{
			// The deviceID the event came from does not match the deviceID of
			// the device that was thought to be on the Tablet. Must have
			// missed a Proximity Notification. Get the Tablet to resend it.
			
			[WacomTabletDriver resendLastTabletEventOfType:eEventProximity];
			return;
		}
	}
   
   [self handleMouseEvent:theEvent];
}



///////////////////////////////////////////////////////////////////////////
- (void)mouseUp:(NSEvent *)theEvent
{
    [self handleMouseEvent:theEvent];
}



///////////////////////////////////////////////////////////////////////////

// - (void)handleMouseEvent:(NSEvent *)theEvent

//

// All of the Mouse Events are funneled through this function so that we
// do not have to duplicate this code. If you do something like this,
// you must be careful because certain fields are only valid for particular
// events. For example, [NSEvent pressure] is not valid for Mouse Moves!

//

- (void)handleMouseEvent:(NSEvent *)theEvent
{
   NSPoint	loc;
   NSPoint	tilt;
   
   mEventType	= [theEvent type];
   
   loc = [theEvent locationInWindow];
   mMouseX	= loc.x;
   mMouseY	= loc.y;
   
   mSubX	= 0.0;//loc.x;
   mSubY	= 0.0;//loc.y;
   
   // pressure: is not valid for MouseMove events
   if(mEventType != NSMouseMoved)
   {
      mPressure	= [theEvent pressure];
   }
   else
   {
      mPressure = 0.0;
   }
   
   mTabletRawPressure = [theEvent rawTabletPressure];
   mTabletScaledPressure = [theEvent scaledTabletPressure];
   [theEvent getAbsoluteX:&mAbsX Y:&mAbsY Z:NULL];
   
   tilt = [theEvent tilt];
   mTiltX = tilt.x;
   mTiltY = tilt.y;
    
   mRotDeg = [theEvent rotationInDegrees];
   mRotRad = [theEvent rotationInRadians];
   
   mDeviceID =  [theEvent deviceID];
   
   // Notify objects that care that this object's stats have been updated
   [[NSNotificationCenter defaultCenter]
         postNotificationName:WTViewUpdatedNotification
         object: self];
}



///////////////////////////////////////////////////////////////////////////

// - (void) handleProximity:(NSNotification *)proxNotice

//

// The proximity notification is based on the Proximity Event.
// (see CarbonEvents.h). The proximity notification will give you detailed
// information about the device that was either just placed on, or just
// taken off of the tablet.
// 
// In this sample code, the Proximity notification is used to determine if
// the pen TIP or ERASER is being used. This information is not provided in
// the embedded tablet event.
//
// Also, on the Intous line of tablets, each trasducer has a unique ID,
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



///////////////////////////////////////////////////////////////////////////

// - (void) drawCurrentDataFromEvent:(NSEvent *)theEvent

//

// This is where the pretty colors are drawn to the screen!
// A 'Real' app would probably keep track of this information so that the
// - (void) drawRect; function can properly re-draw it.

//

- (void) drawCurrentDataFromEvent:(NSEvent *)theEvent
{
   NSBezierPath *path = [NSBezierPath bezierPath];
   NSPoint currentLoc;
   float pressure;
   float opacity;
   float brushSize;
   
   currentLoc = [self convertPoint:[theEvent locationInWindow]
                  fromView:nil];
   pressure = [theEvent pressure];
   
   if(mAdjustSize)
   {
      brushSize = pressure * maxBrushSize;
   }
   else
   {
      brushSize = 0.5 * maxBrushSize;
   }
   
   if(mAdjustOpacity)
   {
      opacity = pressure;
   }
   else
   {
      opacity = 1.0;
   }
   
   // Don't forget to lockFocus when drawing to a view without
   // being inside - (void) drawRect;
   [self lockFocus];
      if ( erasing )
      {
         [[[NSColor whiteColor] colorWithAlphaComponent:opacity] set];
      }
      else
      {
         Transducer *currentDevice = [knownDevices currentDevice];
         
         if(currentDevice != NULL)
         {
            [[[currentDevice color] colorWithAlphaComponent:opacity] set];
         }
         else
         {
            [[[NSColor blackColor] colorWithAlphaComponent:opacity] set];
         }
      }
      
      [path setLineWidth:brushSize];
      [path setLineCapStyle:NSRoundLineCapStyle];
      
      if (useSecondLoc)
      {
         [path moveToPoint:mSecondLoc];
      }
      else
      {
         [path moveToPoint:mLastLoc];
      }
      
      [path lineToPoint:currentLoc];
      [path stroke];
   [self unlockFocus];
   
   // If we are not updating the stats during a drag, then the
   // window will not recieve an update message during the drag.
   // So I explicitly force the window to flush it's contents after
   // drawing each line segment. A 'Real' app would probably want to
   // be smarter about this.
   [[self window] flushWindow];
   
   mLastLoc = currentLoc;
}



///////////////////////////////////////////////////////////////////////////

// - (void)drawRect:(NSRect)rect

// A 'Real' app would probably keep track of the drawing information done
// during Mouse Drags so that it can properly be re-drawn here. I just
// clear the drawing region. (Resize the window and all the drawing is
// erased!)

//

- (void)drawRect:(NSRect)rect
{
   // You do not need to call [self lockFocus] here. Callers of this
   // function are responsible for locking and unlocking the focus for
   // this required method. See the Apple docs on NSView.
   [[NSColor whiteColor] set];
   NSRectFill([self bounds]);
}



///////////////////////////////////////////////////////////////////////////
- (BOOL)isOpaque
{
    // Makes sure that this view is not Transparant!
    return YES;
}



///////////////////////////////////////////////////////////////////////////
- (BOOL)acceptsFirstResponder
{
    // The view only gets MouseMoved events when the view is the First
    // Responder in the Responder event chain
    return YES;
}



///////////////////////////////////////////////////////////////////////////
- (BOOL)becomeFirstResponder
{
	// If do not use the notification method to send proximity events to
	// all objects then you will need to ask the Tablet Driver to resend
	// the last proximity event every time your view becomes the first
	// responder. You can do that here by uncommenting the following line.
	
   // ResendLastTabletEventofType(eEventProximity);
   return YES;
}



///////////////////////////////////////////////////////////////////////////
- (int) mEventType
{
    return mEventType;
}



///////////////////////////////////////////////////////////////////////////
- (UInt16) mDeviceID
{
    return mDeviceID;
}



///////////////////////////////////////////////////////////////////////////
- (float) mMouseX
{
    return mMouseX;
}



///////////////////////////////////////////////////////////////////////////
- (float) mMouseY
{
    return mMouseY;
}



///////////////////////////////////////////////////////////////////////////
- (float) mSubX
{
    return mSubX;
}



///////////////////////////////////////////////////////////////////////////
- (float) mSubY
{
    return mSubY;
}



///////////////////////////////////////////////////////////////////////////
- (float) mPressure
{
    return mPressure;
}



///////////////////////////////////////////////////////////////////////////
- (float) mTabletRawPressure
{
    return mTabletRawPressure;
}



///////////////////////////////////////////////////////////////////////////
- (float) mTabletScaledPressure
{
    return mTabletScaledPressure;
}



///////////////////////////////////////////////////////////////////////////
- (SInt32) mAbsX
{
    return mAbsX;
}



///////////////////////////////////////////////////////////////////////////
- (SInt32) mAbsY
{
    return mAbsY;
}



///////////////////////////////////////////////////////////////////////////
- (float) mTiltX
{
    return mTiltX;
}



///////////////////////////////////////////////////////////////////////////
- (float) mTiltY
{
    return mTiltY;
}



///////////////////////////////////////////////////////////////////////////
- (float) mRotDeg
{
    return mRotDeg;
}



///////////////////////////////////////////////////////////////////////////
- (float) mRotRad
{
    return mRotRad;
}



///////////////////////////////////////////////////////////////////////////
- (NSColor *) mForeColor
{
   Transducer *currentDevice = [knownDevices currentDevice];
   
   if(currentDevice != NULL)
   {
      return [currentDevice color];
   }
   
   return [NSColor blackColor];
}



///////////////////////////////////////////////////////////////////////////
- (void) setForeColor:(NSColor *)newColor
{
   Transducer *currentDevice = [knownDevices currentDevice];
   if(currentDevice != NULL)
   {
      [currentDevice setColor:newColor];
   }
}



///////////////////////////////////////////////////////////////////////////
- (BOOL) mAdjustOpacity
{
   return mAdjustOpacity;
}



///////////////////////////////////////////////////////////////////////////
- (void) setAdjustOpacity:(BOOL)adjust
{
   mAdjustOpacity = adjust;
}



///////////////////////////////////////////////////////////////////////////
- (BOOL) mAdjustSize
{
   return mAdjustSize;
}



///////////////////////////////////////////////////////////////////////////
- (void) setAdjustSize:(BOOL)adjust
{
   mAdjustSize = adjust;
}



///////////////////////////////////////////////////////////////////////////
- (BOOL) mCaptureMouseMoves
{
   return mCaptureMouseMoves;
}



///////////////////////////////////////////////////////////////////////////
- (void) setCaptureMouseMoves:(BOOL)value
{
   mCaptureMouseMoves = value;
   [[self window] setAcceptsMouseMovedEvents:mCaptureMouseMoves];
}



///////////////////////////////////////////////////////////////////////////
- (BOOL) mUpdateStatsDuringDrag
{
   return mUpdateStatsDuringDrag;
}



///////////////////////////////////////////////////////////////////////////
- (void) setUpdateStatsDuringDrag:(BOOL)value
{
   mUpdateStatsDuringDrag = value;
}

@end
