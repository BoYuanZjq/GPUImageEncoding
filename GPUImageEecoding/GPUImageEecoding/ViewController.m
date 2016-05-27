//
//  ViewController.m
//  GPUImageEecoding
//
//  Created by jianqiangzhang on 16/5/27.
//  Copyright © 2016年 jianqiangzhang. All rights reserved.
//

#import "ViewController.h"
#import "GPUImageBeautifyFilter.h"
#import "GPUImageEmptyFilter.h"
#import "VideoStreamingConfiguration.h"

#define KScreenWidth        [UIScreen mainScreen].bounds.size.width
#define KScreenHeight       [UIScreen mainScreen].bounds.size.height
@interface ViewController ()
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) UIButton *beautifyButton;
@property(nonatomic, strong) GPUImageOutput<GPUImageInput> *filter;
@property(nonatomic, strong) GPUImageOutput<GPUImageInput> *emptyFilter;
@property (nonatomic, strong) VideoStreamingConfiguration *videoConfiguration;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.videoConfiguration = [VideoStreamingConfiguration defaultConfiguration];
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:self.videoConfiguration.avSessionPreset cameraPosition:(int)self.videoConfiguration.capturePosition];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.videoCamera.frameRate = (int32_t)self.videoConfiguration.videoFrameRate;
    self.filterView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    [self.filterView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
    [self.filterView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    self.filterView.center = self.view.center;
    
    [self.view addSubview:self.filterView];
    [self.videoCamera addTarget:self.filterView];
    [self.videoCamera startCameraCapture];
    
    self.beautifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.beautifyButton.frame = CGRectMake(0, KScreenHeight - 40, KScreenWidth, 40);
    self.beautifyButton.backgroundColor = [UIColor whiteColor];
    [self.beautifyButton setTitle:@"开启" forState:UIControlStateNormal];
    [self.beautifyButton setTitle:@"关闭" forState:UIControlStateSelected];
    [self.beautifyButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.beautifyButton addTarget:self action:@selector(beautify) forControlEvents:UIControlEventTouchUpInside];
    self.beautifyButton.selected = YES;
    [self beautify];
    [self.view addSubview:self.beautifyButton];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
}
- (void)beautify {
    if (self.beautifyButton.selected) {
        self.beautifyButton.selected = NO;
        [_filter removeAllTargets];
        [_emptyFilter removeAllTargets];
        [self.videoCamera removeAllTargets];
        _filter = [[GPUImageEmptyFilter alloc] init];
        [self.videoCamera addTarget:_filter];
        [_filter addTarget:self.filterView];
    }
    else {
        self.beautifyButton.selected = YES;
        [_filter removeAllTargets];
        
        [self.videoCamera removeAllTargets];
        _filter = [[GPUImageBeautifyFilter alloc] init];
        [self.videoCamera addTarget:_filter];
        [_filter addTarget:self.filterView];
    }
    __weak typeof(self) _self = self;
    [_filter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        [_self processVideo:output];
    }];

}
#pragma mark -- Custom Method
- (void) processVideo:(GPUImageOutput *)output{
    __weak typeof(self) _self = self;
    @autoreleasepool {
        GPUImageFramebuffer *imageFramebuffer = output.framebufferForOutput;
        
        size_t width = imageFramebuffer.size.width;
        size_t height = imageFramebuffer.size.height;
        if(imageFramebuffer.size.width == 360){
            width = 368;///< 必须被16整除
        }
        
        CVPixelBufferRef pixelBuffer = NULL;
        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, [imageFramebuffer byteBuffer], width * 4, nil, NULL, NULL, &pixelBuffer);
        NSLog(@"");
        //        if(pixelBuffer && _self.delegate && [_self.delegate respondsToSelector:@selector(captureOutput:pixelBuffer:)]){
        //            [_self.delegate captureOutput:_self pixelBuffer:pixelBuffer];
        //        }
        CVPixelBufferRelease(pixelBuffer);
    }
}

#pragma mark Notification

- (void)willEnterBackground:(NSNotification*)notification{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.videoCamera pauseCameraCapture];
    runSynchronouslyOnVideoProcessingQueue(^{
        glFinish();
    });
}

- (void)willEnterForeground:(NSNotification*)notification{
    [self.videoCamera resumeCameraCapture];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
