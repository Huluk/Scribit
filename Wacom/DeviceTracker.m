/*----------------------------------------------------------------------------

FILE NAME

DeviceTracker.m - Implamentation file for the DeviceTracker and Transducer
                  classes.

COPYRIGHT

Copyright WACOM Technology, Inc. 2001.

All rights reserved.

----------------------------------------------------------------------------*/
#import "DeviceTracker.h"


@implementation Transducer
///////////////////////////////////////////////////////////////////////////
-(Transducer *) init
{
   if(self = [super init])
   {
      mColor = [NSColor blackColor];
   }
   
   return self;
}



///////////////////////////////////////////////////////////////////////////
-(Transducer *) initWithIdent:(UInt16)newIdent color:(NSColor *) newColor
{
   if(self = [super init])
   {
      ident = newIdent;
      mColor = [newColor copy];
   }
   
   return self;
}



///////////////////////////////////////////////////////////////////////////
-(UInt16) ident
{
   return ident;
}



///////////////////////////////////////////////////////////////////////////
-(NSColor *) color
{
   return mColor;
}



///////////////////////////////////////////////////////////////////////////
-(void) setColor:(NSColor *)newColor
{
   mColor = [newColor copy];
}

@end




@implementation DeviceTracker
///////////////////////////////////////////////////////////////////////////
-(DeviceTracker *) init
{
   if(self = [super init])
   {
      currentDevice = NULL;
      deviceList = [[NSMutableArray alloc] init];
   }
   return self;
}



///////////////////////////////////////////////////////////////////////////
-(BOOL) setCurrentDeviceByID:(UInt16) deviceIdent
{
   NSEnumerator *enumerator = [deviceList objectEnumerator];
   id anObject;
	
   while ((anObject = [enumerator nextObject]))
   {
      if ([anObject ident] == deviceIdent)
      {
         currentDevice = anObject;
         return YES;
      }
   }
   
   return NO;
}



///////////////////////////////////////////////////////////////////////////
-(Transducer *) currentDevice
{
   return currentDevice;
}



///////////////////////////////////////////////////////////////////////////
-(void) addDevice:(Transducer *) newDevice
{
   if (newDevice != nil)
   {
      [deviceList addObject: newDevice];
   }
}

@end

