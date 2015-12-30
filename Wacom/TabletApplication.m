/*----------------------------------------------------------------------------

NAME

	TabletApplication.m -- Header file, adds Proximity events to the App.
                    This is a subclass of NSApplication. It's purpose is to
                    catch Proximity events and Post a kProximityNotification
                    to any object that is listening for them. This is
                    preferable than sending a proximity event, because more
                    than one object may need to know about each proximity
                    event. Furthermore, if an object is not in the current
                    event chain, it would also miss the proximity event.
	

COPYRIGHT

	Copyright WACOM Technologies, Inc. 2001
	All rights reserved.

-----------------------------------------------------------------------------*/

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

#import "TabletApplication.h"

#import "TabletEvents.h"
#import "Wacom.h"
#import "WacomTabletDriver.h"

typedef struct UPoint32
{
	UInt32 y;
	UInt32 x;
} UPoint32;

@implementation TabletApplication
/////////////////////////////////////////////////////////////////////////////
- (id)init
{
   if(self = [super init])
   {
      _needToWatchMouseEvents = [self checkIfNeedToWatchMouseEvents];
      [self tabletInfo];
   }
   return self;
}



/////////////////////////////////////////////////////////////////////////////
- (void)sendEvent:(NSEvent *)theEvent
{
   EventRef inEvent;
   UInt32	eventClass;
   
   inEvent = (EventRef)[theEvent eventRef];
   eventClass = GetEventClass(inEvent);
   
   switch (eventClass)
   {
      case kEventClassTablet:
         if ( [theEvent isTabletProximityEvent] )
			{
				[self handleProximityEvent:theEvent];
			}
         else
			{
				// Pure tablet event? Probably from a second concurrent device.
				//
				// If you wish to use dual inputs, email me, rledet@wacom.com,
				// and I will help you.
			}
      break;
      
      case kEventClassMouse:
			if(_needToWatchMouseEvents)
			{
				[self handleMouseEvent:theEvent];
			}
			else
			{
				[super sendEvent:theEvent];
			}
      break;
      
      default:
         [super sendEvent:theEvent];
      break;
   }
}



//////////////////////////////////////////////////////////////////////////////
- (void) handleMouseEvent:(NSEvent *)theEvent
{
   OSStatus		result;
   EventRef inEvent;
   UInt32	eventType;

   switch( [theEvent type] )
   {
      case kEventMouseDown:
      case kEventMouseUp:
      case kEventMouseMoved:
      case kEventMouseDragged:
         inEvent = (EventRef)[theEvent eventRef];
         result = GetEventParameter(inEvent, kEventParamTabletEventType, 
                                 typeUInt32, NULL, 
                                 sizeof( eventType ), NULL, 
                                 &eventType	);
         
         if ( result == noErr )
         {
            if ( eventType == kEventTabletProximity )
            {
               [self handleProximityEvent:theEvent];
            }
         }
         
         [super sendEvent:theEvent];
      break;
         
      default:
         [super sendEvent:theEvent];
      break;
   }
}



//////////////////////////////////////////////////////////////////////////////
- (void) handleProximityEvent:(NSEvent *)theEvent
{
   OSStatus		result;
   EventRef inEvent;
   TabletProximityRec	proximityEventRecord;
 
   inEvent = (EventRef)[theEvent eventRef];
   result = GetEventParameter(inEvent,
                     kEventParamTabletProximityRec, 
                     typeTabletProximityRec,	NULL, 
                     sizeof( TabletProximityRec ), NULL,
                     &proximityEventRecord );
   
   if ( result == noErr )
   {
      // Set up the keys that are used to extract the data from the
      // Dictionary we provided with the Proximity Notification
      NSArray *keys = [NSArray arrayWithObjects:kVendorID,
                        kTabletID, kPointerID, kDeviceID,
                        kSystemTabletID, kVendorPointerType,
                        kPointerSerialNumber, kUniqueID,
                        kCapabilityMask, kPointerType,
                        kEnterProximity, nil];
                        
      // Setup the data aligned with the keys above to easily create
      // the Dictionary
      NSArray *values = [NSArray arrayWithObjects:
         [NSValue valueWithBytes: &proximityEventRecord.vendorID
                  objCType:@encode(UInt16)],
         [NSValue valueWithBytes: &proximityEventRecord.tabletID
                  objCType:@encode(UInt16)],
         [NSValue valueWithBytes: &proximityEventRecord.pointerID
                  objCType:@encode(UInt16)],
         [NSValue valueWithBytes: &proximityEventRecord.deviceID
                  objCType:@encode(UInt16)],
         [NSValue valueWithBytes: &proximityEventRecord.systemTabletID
                  objCType:@encode(UInt16)],
         [NSValue valueWithBytes: &proximityEventRecord.vendorPointerType
                  objCType:@encode(UInt16)],
         [NSValue valueWithBytes: &proximityEventRecord.pointerSerialNumber
                  objCType:@encode(UInt32)],
         [NSValue valueWithBytes: &proximityEventRecord.uniqueID
                  objCType:@encode(UInt64)],
         [NSValue valueWithBytes: &proximityEventRecord.capabilityMask
                  objCType:@encode(UInt32)],
         [NSValue valueWithBytes: &proximityEventRecord.pointerType
                  objCType:@encode(UInt8)],
         [NSValue valueWithBytes: &proximityEventRecord.enterProximity
                  objCType:@encode(UInt8)],
         nil];
      
      // Create the dictionary
      NSDictionary* proximityDict = [NSDictionary dictionaryWithObjects:values
                        forKeys:keys];
      
      // Send the Procimity Notification
      [[NSNotificationCenter defaultCenter]
               postNotificationName: kProximityNotification
               object: self
               userInfo: proximityDict];
   }
}



//////////////////////////////////////////////////////////////////////////////
- (BOOL) checkIfNeedToWatchMouseEvents
{
	NumVersion 	theVerData;

	// If the user is running tablet driver version 4.7.5 or higher, then all
	// proximity events are sent as pure proximity event. However, if the
	// user is using an older version of the tablet driver, then you will need
	// to inspect all mouse events for embedded prximty events.


	// Use Apple Events to ask the Tablet Driver what it's version is.
	NSAppleEventDescriptor *versionResponse = nil;
	
	versionResponse = [WacomTabletDriver dataForAttribute:pVersion
																  ofType:typeVersion
														  routingTable:[WacomTabletDriver routingTableForDriver]];
	
	if(versionResponse)
	{
        [[versionResponse data] getBytes:&theVerData length:[[versionResponse data] length]];
		
		if ( ( theVerData.majorRev > 4 ) ||
			((theVerData.majorRev >= 4) && (theVerData.minorAndBugRev >= 75)) )
		{
			// Set a global flag so that we know we can use 4.7.5 features.
			return NO;
		}
		else
		{
			// of coase, if we get an answer via AE then we must be running
			// tablet driver ver 4.7.5 or higher, so this else block should
			// never run.
			return YES;
		}
	}
	else
	{
		// Dang, this means that you are running a pre 4.7.5 driver, or
		// running on pre 10.2. That's a bummer.
		return YES;
	}

	return YES;
}



//////////////////////////////////////////////////////////////////////////////
- (void) tabletInfo
{
	OSErr 	err			= noErr;
	UInt32	numTablets	= [WacomTabletDriver tabletCount];
	UInt32	index 		= 0;
	
	if ( err == noErr )
	{
		printf( "I see %d tablets attached\n", (int)numTablets );
		
		for (index = 1; index <= numTablets; index++ )
		{
			[self printInfoForTabletIndex:index];
		}
	}
	else
	{
		printf( "Got an error of %d", err );
	}
}



//////////////////////////////////////////////////////////////////////////////
- (void) printInfoForTabletIndex:(UInt32)tabletIndex
{
   OSErr	   err			   = noErr;
   LongRect	tabletSizeOut	= {};

	NSAppleEventDescriptor *nameResponse = nil;
	NSAppleEventDescriptor *sizeResponse = nil;
	
	
	nameResponse = [WacomTabletDriver dataForAttribute:pName
															  ofType:typeUTF8Text
													  routingTable:[WacomTabletDriver routingTableForTablet:tabletIndex]];
	
	sizeResponse = [WacomTabletDriver dataForAttribute:pTabletSize
															  ofType:typeLongRectangle
													  routingTable:[WacomTabletDriver routingTableForTablet:tabletIndex]];

	if ( nameResponse != nil && sizeResponse != nil )
	{
		NSString *tabletName = [nameResponse stringValue];
        [[sizeResponse data] getBytes:&tabletSizeOut length:[[sizeResponse data] length]];
		
		NSLog(@"Tablet %d [%@] is %d by %d\n", (int)tabletIndex, tabletName,
			 (int)tabletSizeOut.bottom, (int)tabletSizeOut.right );
	}
	else
	{
		NSLog(@"Couldn't get tablet dimensions, error back = %d", err );
	}
}

@end
