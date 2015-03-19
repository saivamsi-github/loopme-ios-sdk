//
//  ViewController.m
//  LoopmeDemo
//
//  Copyright (c) 2015 Loopmemedia. All rights reserved.
//

#import "LDScrollableViewController.h"
#import "TableCityCell.h"

#import "LoopMeAdView.h"
#import "LoopMeLogging.h"

@interface LDScrollableViewController ()
<
    UITableViewDataSource,
    UITableViewDelegate,
    LoopMeAdViewDelegate
>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) LoopMeAdView *mpuVideo;
@property (nonatomic, strong) NSMutableArray *cities;

@end

@implementation LDScrollableViewController

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cities = [self dictionaryWithContentsOfJSONString:@"source.json"];
    
    CGRect mpuFrame = CGRectMake(10, 0, 300, 250);
    self.mpuVideo = [LoopMeAdView adViewWithAppKey:TEST_APP_KEY_MPU frame:mpuFrame scrollView:self.tableView delegate:self];
    self.mpuVideo.tag = 8;
    [self.mpuVideo loadAd];
    
    [self setTitle:@"Ad View in scrollable container"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.mpuVideo updateAdVisibilityInScrollView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.mpuVideo setAdVisible:NO];
}

#pragma mark - private

- (id)dictionaryWithContentsOfJSONString:(NSString*)fileLocation
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:[fileLocation stringByDeletingPathExtension] ofType:[fileLocation pathExtension]];
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    __autoreleasing NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data
                                                options:NSJSONReadingMutableContainers error:&error];
    
    if (error != nil) return nil;
    return result;
}

#pragma mark - UITableViewDelegate | UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cities.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = self.cities[indexPath.row];
    if ([item isKindOfClass:[LoopMeAdView class]]) {
        return self.mpuVideo.bounds.size.height;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 150.0f;
    } else {
        return 65.0f;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = self.cities[indexPath.row];
    if ([item isKindOfClass:[LoopMeAdView class]]) {
        NSString *identifier = @"AdCell";
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }
        [cell addSubview:self.mpuVideo];
        return cell;
    } else {
        static NSString *CityCellIdentifier = @"CityCell";
        TableCityCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CityCellIdentifier forIndexPath:indexPath];
        if (!cell) {
            cell = (TableCityCell *)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CityCellIdentifier];
        }
        cell.showsReorderControl = YES;
        cell.data = item;
        return cell;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.mpuVideo updateAdVisibilityInScrollView];
}

#pragma mark - LoopMeAdViewDelegate

- (void)loopMeAdViewDidLoadAd:(LoopMeAdView *)adView
{
    [self.cities insertObject:adView atIndex:2];
    //  Update dataSource & insert ad spots (IndexPaths) into table view
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

- (void)loopMeAdView:(LoopMeAdView *)adView didFailToLoadAdWithError:(NSError *)error {
    
}

- (UIViewController *)viewControllerForPresentation
{
    return self;
}

@end
