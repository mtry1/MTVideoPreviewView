//
//  ViewController.m
//  MTVideoPreviewViewDemo
//
//  Created by zhourongqing on 16/3/2.
//  Copyright © 2016年 mtry. All rights reserved.
//

#import "ViewController.h"
#import "MTVideoPreviewView.h"

static const CGFloat MTVideoSize = 100.0f;
static const CGFloat MTVideoSpace = 10.0f;
static const NSInteger MTMaxRow = 30;
static const NSInteger MTMaxFileNameNumber = 5;

@interface MTVideoViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation MTVideoViewController

@synthesize tableView = _tableView;

- (UITableView *)tableView
{
    if(!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (NSArray *)videoURLStrings
{
    NSMutableArray *array = [NSMutableArray array];
    for(NSInteger i = 0; i < MTMaxRow; i++)
    {
        NSString *fileName = [NSString stringWithFormat:@"%ld", i % MTMaxFileNameNumber + 1];
        [array addObject:[[NSBundle mainBundle] pathForResource:fileName ofType:@"mp4"]];
    }
    return array;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:self.tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self videoURLStrings].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return MTVideoSize + MTVideoSpace * 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"aaaa"];
    if(!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"aaaa"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        MTVideoPreviewView *previewView = [[MTVideoPreviewView alloc] initWithFrame:CGRectMake(MTVideoSpace, MTVideoSpace, MTVideoSize, MTVideoSize)];
        previewView.repeatPlay = YES;
        previewView.tag = 10086;
        previewView.backgroundColor = [UIColor grayColor];
        [cell.contentView addSubview:previewView];
    }
    
    MTVideoPreviewView *previewView = [cell.contentView viewWithTag:10086];
    previewView.URLString = [self videoURLStrings][indexPath.row];
    [previewView start];
    
    return cell;
}

@end

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    button.center = self.view.center;
    [button setTitle:@"start" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor brownColor]];
    [button addTarget:self action:@selector(touchUpInsideButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)touchUpInsideButton:(UIButton *)button
{
    MTVideoViewController *controller = [MTVideoViewController new];
    [self.navigationController pushViewController:controller animated:YES];
}

@end

