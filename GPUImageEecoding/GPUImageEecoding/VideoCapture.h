//
//  VideoCapture.h
//  GPUImageEecoding
//
//  Created by jianqiangzhang on 16/5/27.
//  Copyright © 2016年 jianqiangzhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoStreamingConfiguration.h"
#import <AVFoundation/AVFoundation.h>

@class VideoCapture;
/** LMVideoCapture callback videoData */
@protocol VideoCaptureDelegate <NSObject>
- (void)captureOutput:(nullable VideoCapture*)capture pixelBuffer:(nullable CVImageBufferRef)pixelBuffer;
@end

@interface VideoCapture : NSObject

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================

/** The delegate of the capture. captureData callback */
@property (nullable,nonatomic, weak) id<VideoCaptureDelegate> delegate;

/** The running control start capture or stop capture*/
//@property (nonatomic, assign) BOOL running;

/** The preView will show OpenGL ES view*/
@property (null_resettable,nonatomic, strong) UIView * preView;

/** The captureDevicePosition control camraPosition ,default front*/
@property (nonatomic, assign) AVCaptureDevicePosition captureDevicePosition;

/** The beautyFace control capture shader filter empty or beautiy default YES*/
@property (nonatomic, assign) BOOL beautyFace;

/** The videoFrameRate control videoCapture output data count */
@property (nonatomic, assign) NSInteger videoFrameRate;

#pragma mark - Initializer
///=============================================================================
/// @name Initializer
///=============================================================================
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;
/**
 The designated initializer. Multiple instances with the same configuration will make the
 capture unstable.
 */
- (nullable instancetype)initWithVideoConfiguration:(nullable VideoStreamingConfiguration *)configuration NS_DESIGNATED_INITIALIZER;
/**
 *  开始预览
 */
- (void)startPreview;
/**
 *  停止预览
 */
- (void)stopPreview;
/**
 *  开始编码
 */
- (void)startEncoding;
/**
 *  停止编码
 */
- (void)stopEncoding;

@end
