/*----------------------------------------------------------------------------

FILE NAME

WTView.h - Header file for WTView class.

COPYRIGHT

Copyright WACOM Technology, Inc. 2001.

All rights reserved.

----------------------------------------------------------------------------*/

#import <AppKit/AppKit.h>
#import "DeviceTracker.h"

@interface WTView : NSView {
    int		mEventType;
    UInt16	mDeviceID;
    float	mMouseX;
    float	mMouseY;
    float	mSubX;
    float	mSubY;
    float	mPressure;
    float	mTabletRawPressure;
    float	mTabletScaledPressure;
    SInt32	mAbsX;
    SInt32	mAbsY;
    float	mTiltX;
    float	mTiltY;
    float	mRotDeg;
    float	mRotRad;
    
    DeviceTracker* knownDevices;
    BOOL		mAdjustOpacity;
    BOOL		mAdjustSize;
    BOOL		mCaptureMouseMoves;
    BOOL		mUpdateStatsDuringDrag;
    
    
    //Private
    BOOL		erasing;
    NSPoint mLastLoc;
    BOOL		useSecondLoc;
    NSPoint mSecondLoc;
}

- (int) mEventType;
- (UInt16) mDeviceID;
- (float) mMouseX;
- (float) mMouseY;
- (float) mSubX;
- (float) mSubY;
- (float) mPressure;
- (float) mTabletRawPressure;
- (float) mTabletScaledPressure;
- (SInt32) mAbsX;
- (SInt32) mAbsY;
- (float) mTiltX;
- (float) mTiltY;
- (float) mRotDeg;
- (float) mRotRad;
    
- (NSColor *) mForeColor;
- (void) setForeColor:(NSColor *)newColor;

- (BOOL) mAdjustOpacity;
- (void) setAdjustOpacity:(BOOL)adjust;
- (BOOL) mAdjustSize;
- (void) setAdjustSize:(BOOL)adjust;

- (BOOL) mCaptureMouseMoves;
- (void) setCaptureMouseMoves:(BOOL)value;
- (BOOL) mUpdateStatsDuringDrag;
- (void) setUpdateStatsDuringDrag:(BOOL)value;

- (void) handleMouseEvent:(NSEvent *)theEvent;
- (void) handleProximity:(NSNotification *)proxNotice;
- (void) drawCurrentDataFromEvent:(NSEvent *)theEvent;

@end

extern NSString *WTViewUpdatedNotification;
