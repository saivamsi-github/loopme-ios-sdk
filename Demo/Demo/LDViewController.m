//
//  LDViewController.m
//  Demo
//
//  Copyright (c) 2014 loopmemedia. All rights reserved.
//

#import "LDViewController.h"
#import "LoopMeInterstitial.h"
#import "LoopMeLogging.h"
#import "UIImage+iphone5.h"

NSString * const kLoopMeInterstitialAdAppKey = @"3ee6fc7a45";

@interface LDViewController ()
<
    LoopMeInterstitialDelegate
>

@property (nonatomic, strong) LoopMeInterstitial *i;
@property (nonatomic, weak) IBOutlet UIButton *interstitialButton;

@end

@implementation LDViewController

#pragma mark - Services

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.background.image = [UIImage imageNamedForDevice:@"background.png"];
    }
    
    self.interstitialButton.layer.cornerRadius = 5;
    self.interstitialButton.layer.borderWidth = 1;
    self.interstitialButton.layer.borderColor = [UIColor redColor].CGColor;
    
    self.i = [LoopMeInterstitial interstitialWithAppKey:kLoopMeInterstitialAdAppKey delegate:self];
    setLoopMeLogLevel(LoopMeLogLevelDebug);
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self hideStatusBar];
}

#pragma mark - Actions

- (IBAction)interstitialButtonTapped:(id)sender {
    if (self.i.isReady) {
        [self.i showFromViewController:self];
    } else {
        [self.i loadAd];
        [self setInterstitialButtonTitle:@"Loading..."];
    }
}

#pragma mark - Hide statusbar

-(void)hideStatusBar {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    // iOS 7.0 or later
    [self setNeedsStatusBarAppearanceUpdate];
#else
    // less than 7.0
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
#endif
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

#pragma mark - Private

- (void)setInterstitialButtonTitle:(NSString *)title {
    [self.interstitialButton setTitle:title forState:UIControlStateNormal];
}

#pragma mark - LoopMe delegate

- (void)loopMeInterstitial:(LoopMeInterstitial *)interstitial didFailToLoadAdWithError:(NSError *)error {
    [self setInterstitialButtonTitle:@"Load Ad"];
}

- (void)loopMeInterstitialDidDisappear:(LoopMeInterstitial *)interstitial {
//   Trigger loading ad every time it dismissed
    [self.i loadAd];
    [self setInterstitialButtonTitle:@"Loading..."];
}

- (void)loopMeInterstitialDidLoadAd:(LoopMeInterstitial *)interstitial {
    [self setInterstitialButtonTitle:@"Show Ad"];
}

- (void)loopMeInterstitialDidExpire:(LoopMeInterstitial *)interstitial {
    [self.i loadAd];
    [self setInterstitialButtonTitle:@"Loading..."];
}

@end
