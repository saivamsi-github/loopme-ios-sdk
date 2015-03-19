//
//  LDInterstitialViewController.m
//  LoopmeDemo
//
//  Copyright (c) 2015 Loopmemedia. All rights reserved.
//

#import "LDInterstitialViewController.h"
#import "UIImage+iphone5.h"

#import "LoopMeInterstitial.h"

@interface LDInterstitialViewController ()
<
    LoopMeInterstitialDelegate
>

@property (weak, nonatomic) IBOutlet UIButton *showButton;
@property (weak, nonatomic) IBOutlet UIImageView *background;
@property (nonatomic, strong) LoopMeInterstitial *interstitial;

@end

@implementation LDInterstitialViewController

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _background.image = [UIImage imageNamedForDevice:@"bg_new_main"];
    }
    [self setTitle:@"Interstitial"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.interstitial = [LoopMeInterstitial interstitialWithAppKey:TEST_APP_KEY_INTERSTITIAL_PORTRAIT delegate:self];
    if ([self.interstitial isReady]) {
        [self togglePreloadingProgress:LDButtonStateShow];
    } else {
        [self togglePreloadingProgress:LDButtonStateLoad];
    }
}

#pragma mark - Private

- (void)togglePreloadingProgress:(LDButtonState)state
{
    switch (state) {
        case LDButtonStateLoad:
            self.showButton.enabled = YES;
            [self.showButton setTitle:@"LOAD" forState:UIControlStateNormal];
            [self.showButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        
        case LDButtonStateLoading:
            self.showButton.enabled = NO;
            [self.showButton setTitle:@"PRELOADING..." forState:UIControlStateDisabled];
            [self.showButton setTitleColor:[UIColor redColor] forState:UIControlStateDisabled];
            break;
            
        case LDButtonStateShow:
            self.showButton.enabled = YES;
            [self.showButton setTitle:@"SHOW" forState:UIControlStateNormal];
            [self.showButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
            
        case LDButtonStateRetry:
            self.showButton.enabled = YES;
            [self.showButton setTitle:@"Retry" forState:UIControlStateNormal];
            [self.showButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

#pragma mark - Actions

- (IBAction)btnShow_Click:(id)sender
{
    if ([self.interstitial isReady]) {
        [self.interstitial showFromViewController:self animated:YES];
        [self togglePreloadingProgress:LDButtonStateLoad];
    } else {
        [self togglePreloadingProgress:LDButtonStateLoading];
        [self.interstitial loadAd];
    }
}
#pragma mark - LoopMeInterstitialDelegate

- (void)loopMeInterstitial:(LoopMeInterstitial *)interstitial didFailToLoadAdWithError:(NSError *)error
{
    [self togglePreloadingProgress:LDButtonStateRetry];
}

- (void)loopMeInterstitialDidLoadAd:(LoopMeInterstitial *)interstitial
{
    [self togglePreloadingProgress:LDButtonStateShow];
}

- (void)loopMeInterstitialVideoDidReachEnd:(LoopMeInterstitial *)interstitial {
    
}

- (void)loopMeInterstitialDidExpire:(LoopMeInterstitial *)interstitial
{
    [self togglePreloadingProgress:LDButtonStateLoading];
    [interstitial loadAd];
}

- (void)loopMeInterstitialDidDisappear:(LoopMeInterstitial *)interstitial
{
    [self.interstitial loadAd];
    [self togglePreloadingProgress:LDButtonStateLoading];
}

@end
