//
//  MTVideoPreviewView.m
//  MTVideoPreviewViewDemo
//
//  Created by zhourongqing on 16/3/2.
//  Copyright © 2016年 mtry. All rights reserved.
//

#import "MTVideoPreviewView.h"
#import <AVFoundation/AVFoundation.h>

#pragma mark - MTVideoDecoder

@class MTVideoDecoder;

@protocol MTVideoDecoderDelegate <NSObject>

- (void)videoDecoder:(MTVideoDecoder *)decoder progressImageRef:(CGImageRef)imageRef;
- (void)videoDecoderDidFinished:(MTVideoDecoder *)decoder;

@end

@interface MTVideoDecoder : NSObject

@property (nonatomic, weak) id<MTVideoDecoderDelegate>delegate;
@property (nonatomic, readonly) NSOperationQueue *operationQueue;
@property (nonatomic, readonly) AVAssetReader *assetReader;
@property (nonatomic, readonly) AVAssetReaderTrackOutput *readerOutput;
@property (nonatomic, readonly) AVURLAsset *asset;
@property (nonatomic, readonly) NSString *urlString;
@property (nonatomic) BOOL stopDecoding;

@end

@implementation MTVideoDecoder

@synthesize operationQueue = _operationQueue;
@synthesize assetReader = _assetReader;
@synthesize readerOutput = _readerOutput;
@synthesize urlString = _urlString;

- (NSOperationQueue *)operationQueue
{
    if(!_operationQueue)
    {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    return _operationQueue;
}

- (void)decodeURLString:(NSString *)URLString
{
    _urlString = URLString;
    
    __weak typeof(self)weakSelf = self;
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        [weakSelf onBackgroundThreadDecode];
    }];
    [self.operationQueue addOperation:operation];
}

- (void)onBackgroundThreadDecode
{
    self.stopDecoding = NO;
    
    NSURL *URL = [NSURL fileURLWithPath:self.urlString];
    _asset = [[AVURLAsset alloc] initWithURL:URL options:nil];
    _assetReader = [[AVAssetReader alloc] initWithAsset:self.asset error:nil];
    if(!self.assetReader) return;
    
    NSArray *videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
    NSDictionary *outputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    _readerOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:outputSettings];
    if(![self.assetReader canAddOutput:self.readerOutput]) return;
    
    [self.assetReader addOutput:self.readerOutput];
    [self.assetReader startReading];
    
    NSTimeInterval minFrameDuration = CMTimeGetSeconds(videoTrack.minFrameDuration);
    while(!self.stopDecoding && self.assetReader.status == AVAssetReaderStatusReading && videoTrack.nominalFrameRate > 0)
    {
        CMSampleBufferRef sampleBuffer = [self.readerOutput copyNextSampleBuffer];
        if(sampleBuffer)
        {
            CGImageRef imageRef = [self imageFromSampleBufferRef:sampleBuffer];
            if(imageRef)
            {
                __weak typeof(self)weakSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.delegate videoDecoder:weakSelf progressImageRef:imageRef];
                    CGImageRelease(imageRef);
                });
            }
            CFRelease(sampleBuffer);
        }
        [NSThread sleepForTimeInterval:minFrameDuration];
    }
    
    if(self.assetReader.status != AVAssetReaderStatusCancelled)
    {
        [self.assetReader cancelReading];
    }
    
    if(!self.stopDecoding)
    {
        __weak typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegate videoDecoderDidFinished:weakSelf];
        });
    }
}

- (CGImageRef)imageFromSampleBufferRef:(CMSampleBufferRef)sampleBufferRef
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    if(!width || !height)
    {
        return nil;
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedFirst);
    CGImageRef ImageRef = CGBitmapContextCreateImage(context);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    return ImageRef;
}

- (void)setStopDecoding:(BOOL)stopDecoding
{
    _stopDecoding = stopDecoding;
}

- (void)dealloc
{
    [self.operationQueue cancelAllOperations];
    
    self.stopDecoding = YES;
    if(self.assetReader.status == AVAssetReaderStatusReading)
    {
        [self.assetReader cancelReading];
    }
}

@end

#pragma mark - MTVideoPreviewView

@interface MTVideoPreviewView ()<MTVideoDecoderDelegate>

@property (nonatomic, readonly) MTVideoDecoder *decoder;

@end

@implementation MTVideoPreviewView

@synthesize decoder = _decoder;
@synthesize playing = _playing;

- (MTVideoDecoder *)decoder
{
    if(!_decoder)
    {
        _decoder = [[MTVideoDecoder alloc] init];
        _decoder.delegate = self;
    }
    return _decoder;
}

- (BOOL)isPlaying
{
    return _playing;
}

- (void)start
{
    if(self.isPlaying)
    {
        [self stop];
    }
    
    _playing = YES;
    [self.decoder decodeURLString:self.URLString];
}

- (void)stop
{
    _playing = NO;
    self.decoder.stopDecoding = YES;
}

- (void)videoDecoder:(MTVideoDecoder *)decoder progressImageRef:(CGImageRef)imageRef
{
    if(imageRef)
    {
        self.layer.contents = (__bridge id)imageRef;
    }
}

- (void)videoDecoderDidFinished:(MTVideoDecoder *)decoder
{
    if(self.repeatPlay)
    {
        [self start];
    }
}

- (void)dealloc
{
    if(self.isPlaying)
    {
        [self stop];
    }
}

@end
