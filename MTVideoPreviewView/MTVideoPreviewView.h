//
//  MTVideoPreviewView.h
//  MTVideoPreviewViewDemo
//
//  Created by zhourongqing on 16/3/2.
//  Copyright © 2016年 mtry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTVideoPreviewView : UIView

@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, readonly, getter=isPlaying) BOOL playing;
@property (nonatomic) BOOL repeatPlay;

- (void)start;
- (void)stop;

@end
