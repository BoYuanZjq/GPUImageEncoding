//
//  SecondViewController.m
//  GPUImageEecoding
//
//  Created by jianqiangzhang on 16/5/27.
//  Copyright © 2016年 jianqiangzhang. All rights reserved.
//

#import "SecondViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "VideoCapture.h"
#import "VideoStreamingConfiguration.h"
#import "UIControl+YYAdd.h"
#import "UIView+YYAdd.h"

@interface SecondViewController ()<VideoCaptureDelegate>
@property (nonatomic, strong) VideoCapture *videoCapture;
@property (nonatomic, strong) UIButton *beautyButton;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *startLiveButton;
@property (nonatomic, strong) UIView *containerView;
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self requestAccessForVideo];
    [self requestAccessForAudio];
    
    [self.view addSubview:self.containerView];
    [self.containerView addSubview:self.closeButton];
    [self.containerView addSubview:self.cameraButton];
    [self.containerView addSubview:self.beautyButton];
    [self.containerView addSubview:self.startLiveButton];
    
}

#pragma mark -- Public Method
- (void)requestAccessForVideo{
    __weak typeof(self) _self = self;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            // 许可对话没有出现，发起授权许可
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                         [_self.videoCapture startPreview];
                    });
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            // 已经开启授权，可继续
            [_self.videoCapture startPreview];
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            // 用户明确地拒绝授权，或者相机设备无法访问
            
            break;
        default:
            break;
    }
}

- (void)requestAccessForAudio{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            break;
        default:
            break;
    }
}
#pragma mark - VideoCaptureDelegate
- (void)captureOutput:(nullable VideoCapture*)capture pixelBuffer:(nullable CVImageBufferRef)pixelBuffer {
    NSLog(@"d");
}
#pragma mark - set/get
- (VideoCapture*)videoCapture {
    if (!_videoCapture) {
        VideoStreamingConfiguration *configuration = [VideoStreamingConfiguration defaultConfiguration];
        
        _videoCapture = [[VideoCapture alloc] initWithVideoConfiguration:configuration];
        _videoCapture.preView = self.view;
        _videoCapture.delegate = self;
    }
    return _videoCapture;
}

- (UIView*)containerView{
    if(!_containerView){
        _containerView = [UIView new];
        _containerView.frame = self.view.bounds;
        _containerView.backgroundColor = [UIColor clearColor];
        _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _containerView;
}

- (UIButton*)closeButton{
    if(!_closeButton){
        _closeButton = [UIButton new];
        _closeButton.size = CGSizeMake(44, 44);
        _closeButton.left = self.view.width - 10 - _closeButton.width;
        _closeButton.top = 20;
        [_closeButton setImage:[UIImage imageNamed:@"close_preview"] forState:UIControlStateNormal];
        _closeButton.exclusiveTouch = YES;
        [_closeButton addBlockForControlEvents:UIControlEventTouchUpInside block:^(id sender) {
            
        }];
    }
    return _closeButton;
}

- (UIButton*)cameraButton{
    if(!_cameraButton){
        _cameraButton = [UIButton new];
        _cameraButton.size = CGSizeMake(44, 44);
        _cameraButton.origin = CGPointMake(_closeButton.left - 10 - _cameraButton.width, 20);
        [_cameraButton setImage:[UIImage imageNamed:@"camra_preview"] forState:UIControlStateNormal];
        _cameraButton.exclusiveTouch = YES;
        __weak typeof(self) _self = self;
        [_cameraButton addBlockForControlEvents:UIControlEventTouchUpInside block:^(id sender) {
            AVCaptureDevicePosition devicePositon = _self.videoCapture.captureDevicePosition;
            _self.videoCapture.captureDevicePosition = (devicePositon == AVCaptureDevicePositionBack) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
        }];
    }
    return _cameraButton;
}

- (UIButton*)beautyButton{
    if(!_beautyButton){
        _beautyButton = [UIButton new];
        _beautyButton.size = CGSizeMake(44, 44);
        _beautyButton.origin = CGPointMake(_cameraButton.left - 10 - _beautyButton.width,20);
        [_beautyButton setImage:[UIImage imageNamed:@"camra_beauty"] forState:UIControlStateSelected];
        [_beautyButton setImage:[UIImage imageNamed:@"camra_beauty_close"] forState:UIControlStateNormal];
        _beautyButton.exclusiveTouch = YES;
        _beautyButton.selected = YES;
        __weak typeof(self) _self = self;
        [_beautyButton addBlockForControlEvents:UIControlEventTouchUpInside block:^(id sender) {
            _self.videoCapture.beautyFace = !_self.videoCapture.beautyFace;
            _self.beautyButton.selected = _self.videoCapture.beautyFace;
        }];
    }
    return _beautyButton;
}

- (UIButton*)startLiveButton{
    if(!_startLiveButton){
        _startLiveButton = [UIButton new];
        _startLiveButton.size = CGSizeMake(self.view.width - 60, 44);
        _startLiveButton.left = 30;
        _startLiveButton.bottom = self.view.height - 50;
        _startLiveButton.layer.cornerRadius = _startLiveButton.height/2;
        [_startLiveButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_startLiveButton.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [_startLiveButton setTitle:@"开始直播" forState:UIControlStateNormal];
        [_startLiveButton setBackgroundColor:[UIColor grayColor]];
        _startLiveButton.exclusiveTouch = YES;
        __weak typeof(self) _self = self;
        [_startLiveButton addBlockForControlEvents:UIControlEventTouchUpInside block:^(id sender) {
            _self.startLiveButton.selected = !_self.startLiveButton.selected;
            if(_self.startLiveButton.selected){
                [_self.startLiveButton setTitle:@"结束直播" forState:UIControlStateNormal];
                [_self.videoCapture startEncoding];
            }else{
                [_self.startLiveButton setTitle:@"开始直播" forState:UIControlStateNormal];
               [_self.videoCapture stopEncoding];
            }
        }];
    }
    return _startLiveButton;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
