//
//  VideoCapture.m
//  GPUImageEecoding
//
//  Created by jianqiangzhang on 16/5/27.
//  Copyright © 2016年 jianqiangzhang. All rights reserved.
//

#import "VideoCapture.h"
#import <GPUImage.h>
#import "GPUImageBeautifyFilter.h"
#import "GPUImageEmptyFilter.h"
#import "VideoStreamingConfiguration.h"
@interface VideoCapture()
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *gpuImageView;
@property (nonatomic, strong) UIButton *beautifyButton;
@property(nonatomic, strong) GPUImageCropFilter *cropfilter;
@property(nonatomic, strong) GPUImageOutput<GPUImageInput> *filter;
@property(nonatomic, strong) GPUImageOutput<GPUImageInput> *emptyFilter;
@property (nonatomic, strong) VideoStreamingConfiguration *configuration;
@property (nonatomic, assign) BOOL isPreviewing;
@property (nonatomic, assign) BOOL isEncoding;
@end
@implementation VideoCapture

- (void)dealloc{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_videoCamera stopCameraCapture];
}

#pragma mark -- LifeCycle
- (instancetype)initWithVideoConfiguration:(VideoStreamingConfiguration *)configuration{
    if(self = [super init]){
        _configuration = configuration;
        _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:_configuration.avSessionPreset cameraPosition:AVCaptureDevicePositionFront];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
        _videoCamera.horizontallyMirrorRearFacingCamera = NO;
        _videoCamera.frameRate = (int32_t)_configuration.videoFrameRate;
        
        _gpuImageView = [[GPUImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [_gpuImageView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
        [_gpuImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        self.beautyFace = YES;
        self.isPreviewing = NO;
    }
    return self;
}

- (void)startPreview {
    if (!_isPreviewing) {
        _isPreviewing = YES;
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        [_videoCamera startCameraCapture];
    }
    
}
- (void)stopPreview {
    if (_isPreviewing) {
        _isPreviewing = NO;
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        [_videoCamera stopCameraCapture];
    }
}

- (void)startEncoding {
    if (!_isEncoding) {
        _isEncoding = YES;
    }
}
- (void)stopEncoding {
    if (_isEncoding) {
        _isEncoding = NO;
    }
}
#pragma mark -- Setter Getter
//- (void)setRunning:(BOOL)running{
//    if(_running == running) return;
//    _running = running;
//    
//    if(!_running){
//        [UIApplication sharedApplication].idleTimerDisabled = NO;
//        [_videoCamera stopCameraCapture];
//    }else{
//        [UIApplication sharedApplication].idleTimerDisabled = YES;
//        [_videoCamera startCameraCapture];
//    }
//}

- (void)setPreView:(UIView *)preView{
    if(_gpuImageView.superview) [_gpuImageView removeFromSuperview];
    [preView insertSubview:_gpuImageView atIndex:0];
}

- (UIView*)preView{
    return _gpuImageView.superview;
}

- (void)setCaptureDevicePosition:(AVCaptureDevicePosition)captureDevicePosition{
    [_videoCamera rotateCamera];
    _videoCamera.frameRate = (int32_t)_configuration.videoFrameRate;
}

- (AVCaptureDevicePosition)captureDevicePosition{
    return [_videoCamera cameraPosition];
}

- (void)setVideoFrameRate:(NSInteger)videoFrameRate{
    if(videoFrameRate <= 0) return;
    if(videoFrameRate == _videoCamera.frameRate) return;
    _videoCamera.frameRate = (uint32_t)videoFrameRate;
}

- (NSInteger)videoFrameRate{
    return _videoCamera.frameRate;
}
- (void)setBeautyFace:(BOOL)beautyFace{
    if(_beautyFace == beautyFace) return;
    
    _beautyFace = beautyFace;
    [_emptyFilter removeAllTargets];
    [_filter removeAllTargets];
    [_cropfilter removeAllTargets];
    [_videoCamera removeAllTargets];
    
    if(_beautyFace){
        _filter = [[GPUImageBeautifyFilter alloc] init];
        _emptyFilter = [[GPUImageEmptyFilter alloc] init];
    }else{
        _filter = [[GPUImageEmptyFilter alloc] init];
    }
    
    __weak typeof(self) _self = self;
    [_filter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        [_self processVideo:output];
    }];
    
    if(_configuration.isClipVideo){///<  裁剪为16:9
        _cropfilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.125, 0, 0.75, 1)];
        [_videoCamera addTarget:_cropfilter];
        [_cropfilter addTarget:_filter];
    }else{
        [_videoCamera addTarget:_filter];
    }
    
    if (beautyFace) {
        [_filter addTarget:_emptyFilter];
        if(_gpuImageView) [_emptyFilter addTarget:_gpuImageView];
    } else {
        if(_gpuImageView) [_filter addTarget:_gpuImageView];
    }
    
}

#pragma mark -- Custom Method
- (void) processVideo:(GPUImageOutput *)output{
    if (!_isEncoding) {
        return;
    }
    __weak typeof(self) _self = self;
    @autoreleasepool {
        GPUImageFramebuffer *imageFramebuffer = output.framebufferForOutput;
        
        size_t width = imageFramebuffer.size.width;
        size_t height = imageFramebuffer.size.height;
        ///< 这里可能会影响性能，以后要尝试修改GPUImage源码 直接获取CVPixelBufferRef 目前是获取的bytes 其实更麻烦了
        if(imageFramebuffer.size.width == 360){
            width = 368;///< 必须被16整除
        }
        
        CVPixelBufferRef pixelBuffer = NULL;
        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, [imageFramebuffer byteBuffer], width * 4, nil, NULL, NULL, &pixelBuffer);
        if(pixelBuffer && _self.delegate && [_self.delegate respondsToSelector:@selector(captureOutput:pixelBuffer:)]){
            [_self.delegate captureOutput:_self pixelBuffer:pixelBuffer];
        }
        CVPixelBufferRelease(pixelBuffer);
    }
}

#pragma mark Notification

- (void)willEnterBackground:(NSNotification*)notification{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [_videoCamera pauseCameraCapture];
    runSynchronouslyOnVideoProcessingQueue(^{
        glFinish();
    });
}

- (void)willEnterForeground:(NSNotification*)notification{
    [_videoCamera resumeCameraCapture];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}



@end
