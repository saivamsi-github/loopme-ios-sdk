//
//  ViewController.m
//  LoopMeMediatonDemo
//
//  Created by Dmitriy on 7/29/15.
//  Copyright (c) 2015 injectios. All rights reserved.
//

#import "LDAdRequestViewController.h"
#import "LDContentTableViewCell.h"
#import "MPNativeAdRequest.h"
#import "MPNativeAd.h"
#import "MPTableViewAdManager.h"
#import "LDAdTableViewCell.h"
#import "MPNativeAdDelegate.h"
#import "LoopMeNativeAd.h"

const int kLDAdTableViewCell = 3;

const float kLDAdViewHeight = 168.75; // Video dimension 16x9
const float kLDAdViewWidth = 320.0f;

NSString *const kLDContentCellIdentifier = @"ContentCellIdentifier";
NSString *const kLDAdCellIdentifier = @"AdCellIdentifier";
NSString *const kLDLoopMeAdCellIdentifier = @"LoopMeAdCellIdentifier";

@interface LDAdRequestViewController ()
<
    UITableViewDataSource,
    UITableViewDelegate,
    MPNativeAdDelegate,
    LoopMeAdViewDelegate,
    UIScrollViewDelegate
>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *contentItems;

@end

@implementation LDAdRequestViewController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self fillContent];
    [self.tableView registerClass:[LDAdTableViewCell class]
           forCellReuseIdentifier:kLDAdCellIdentifier];
    [self.tableView registerClass:[LDContentTableViewCell class]
           forCellReuseIdentifier:kLDContentCellIdentifier];
    
    [self triggerAds];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    /*
     * Set video ad visibility to YES in order to calculate visibility area in scrollView and resume playback
     */
    [self setAdVisible:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    /*
     * Set ad visibility to NO in order to pause video ad playback
     */
    [self setAdVisible:NO];
}

#pragma mark - Private

- (void)fillContent {
    self.contentItems = [NSMutableArray array];
    for (NSString *fontFamilyName in [UIFont familyNames]) {
        for (NSString *fontName in [UIFont fontNamesForFamilyName:fontFamilyName]) {
            [self.contentItems addObject:fontName];
        }
    }
}

- (void)triggerAds {
    
    /*
     * Trigerring ad request to Mopub
     */
    MPNativeAdRequest *adRequest1 = [MPNativeAdRequest requestWithAdUnitIdentifier:@"8e7b584dd5bf40ab9baea14d2404ab55"];
    [adRequest1 startWithCompletionHandler:^(MPNativeAdRequest *request, MPNativeAd *response, NSError *error) {
        if (!error) {
            response.delegate = self;
            [self insertAd:response atIndexPath:[NSIndexPath indexPathForRow:kLDAdTableViewCell inSection:0]];
        }
    }];
}

- (void)insertAd:(MPNativeAd *)nativeAd atIndexPath:(NSIndexPath *)indexPath
{
    /*
     * Updating dataSource and inserting new ad cell to tableView
     */
    [self.contentItems insertObject:nativeAd atIndex:indexPath.row];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UITableViewDelegate/UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.contentItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([self isAdAtIndexPath:indexPath])
    {
        UITableViewCell *adCell;
        if ([self isLoopMeAdAtIndexPath:indexPath])
            /*
             * return specific cell for video ad
             * IMPORTANT: make sure you are using different cell identifier since LoopMeAdView is added as a subView to cell
             */
            adCell = [self loopMeAdCellForIndexPath:indexPath];
        else
            // returning cell for Mopub ads
            adCell = [self adCellForIndexPath:indexPath];
        return adCell;
    }
    else
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLDContentCellIdentifier
                                                                forIndexPath:indexPath];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:kLDContentCellIdentifier];
        }
        NSString *fontName = self.contentItems[indexPath.row];
        cell.textLabel.font = [UIFont fontWithName:fontName size:14.0];
        cell.textLabel.text = fontName;
        cell.separatorInset = UIEdgeInsetsZero;
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isAdAtIndexPath:indexPath]) {
        if ([self isLoopMeAdAtIndexPath:indexPath]) {
            return kLDAdViewHeight;
        }
        return 120;
    }
    else
        return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self isAdAtIndexPath:indexPath])
    {
        MPNativeAd *adObject = (MPNativeAd *)[self.contentItems objectAtIndex:indexPath.row];
        [adObject displayContentWithCompletion:^(BOOL success, NSError *error) {}];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    /*
     * Updating ad visibility in scrollable content in order to manage video ad playback
     */
    [self updateAdViewVisibility];
}

#pragma mark - Ad Helpers 

- (BOOL)isAdAtIndexPath:(NSIndexPath *)indexPath
{
    return ([[self.contentItems objectAtIndex:indexPath.row] isKindOfClass:[MPNativeAd class]]) ? YES : NO;
}

- (BOOL)isLoopMeAdAtIndexPath:(NSIndexPath *)indexPath {
    return [self.contentItems[indexPath.row] isKindOfClass:[LoopMeNativeAd class]] ? YES : NO;
}

- (UITableViewCell *)adCellForIndexPath:(NSIndexPath *)indexPath {
    MPNativeAd *adObject = (MPNativeAd *)[self.contentItems objectAtIndex:indexPath.row];
    LDAdTableViewCell *adCell = [self.tableView dequeueReusableCellWithIdentifier:kLDAdCellIdentifier];
    if (!adCell) {
        adCell = [[LDAdTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kLDAdCellIdentifier];
    }
    // Loading assets to ad cell
    [adObject loadTextIntoLabel:adCell.mainTextLabel];
    [adObject loadTitleIntoLabel:adCell.titleLabel];
    [adObject loadIconIntoImageView:adCell.iconImageView];
    return adCell;
}

- (UITableViewCell *)loopMeAdCellForIndexPath:(NSIndexPath *)indexPath {
    LoopMeNativeAd *adObject = (LoopMeNativeAd *)[self.contentItems objectAtIndex:indexPath.row];
    UITableViewCell *adCell = [self.tableView dequeueReusableCellWithIdentifier:kLDLoopMeAdCellIdentifier];
    if (!adCell) {
        adCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kLDLoopMeAdCellIdentifier];
    }
    
    // Set up LoopMeAdView
    adObject.adView.frame = CGRectMake(0, 0, kLDAdViewWidth, kLDAdViewHeight);
    // Re-assiging delegate since we would like to display video ads here
    // note that you don't have to implement -didLoad, -didFailToLoad methods
    // since it's already loaded
    adObject.adView.delegate = self;
    adObject.adView.scrollView = self.tableView;
    // Adding LoopMeAdView as a subView to cell
    [adCell.contentView addSubview:adObject.adView];
    return adCell;
}

- (void)updateAdViewVisibility {
    for (id item in self.contentItems) {
        if ([item isKindOfClass:[LoopMeNativeAd class]]) {
            [[(LoopMeNativeAd *)item adView] updateAdVisibilityInScrollView];
        }
    }
}

- (void)setAdVisible:(BOOL)visible {
    for (id item in self.contentItems) {
        if ([item isKindOfClass:[LoopMeNativeAd class]]) {
            [[(LoopMeNativeAd *)item adView] setAdVisible:visible];
        }
    }
}

#pragma mark - MPNativeAdDelegate

- (UIViewController *)viewControllerForPresentingModalView
{
    return self;
}

#pragma mark - LoopMeAdViewDelegate

- (void)loopMeAdViewDidReceiveTap:(LoopMeAdView *)adView {
    // handle tap event if needed
}

- (void)loopMeAdViewVideoDidReachEnd:(LoopMeAdView *)adView {
    // handle "video completion" event if needed
}

- (UIViewController *)viewControllerForPresentation {
    return self;
}

@end
