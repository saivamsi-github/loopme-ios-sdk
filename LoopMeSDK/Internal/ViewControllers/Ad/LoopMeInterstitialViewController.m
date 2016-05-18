//
//  LoopMeHTMLInterstitialViewController.m
//  LoopMeSDK
//
//  Created by Dmitriy Lihachov on 8/21/12.
//  Copyright (c) 2012 LoopMe. All rights reserved.
//

#import "LoopMeAdConfiguration.h"
#import "LoopMeInterstitialViewController.h"

@interface LoopMeInterstitialViewController ()
@property (nonatomic, assign, getter = isApplicationHasStatusBar) BOOL applicationHasStatusBar;
@property (nonatomic, assign) LoopMeAdOrientation adOrientation;
@end

@implementation LoopMeInterstitialViewController

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.applicationHasStatusBar = ![UIApplication sharedApplication].isStatusBarHidden;
    [self setApplicationStatusBarHidden:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self setApplicationStatusBarHidden:!self.isApplicationHasStatusBar];
}

#pragma mark - Private

- (void)setApplicationStatusBarHidden:(BOOL)hidden
{
    UIStatusBarAnimation animation = hidden ?
        UIStatusBarAnimationFade : UIStatusBarAnimationNone;
    [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:animation];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark Orientation handling

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if (self.adOrientation == LoopMeAdOrientationLandscape) {
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return [UIApplication sharedApplication].statusBarOrientation;
        }
        return UIInterfaceOrientationLandscapeLeft;
    } else {
        return UIInterfaceOrientationPortrait;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    UIInterfaceOrientationMask applicationSupportedOrientations =
    [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:[UIApplication sharedApplication].keyWindow];
    UIInterfaceOrientationMask interstitialSupportedOrientations = applicationSupportedOrientations;
    
    if (self.adOrientation == LoopMeAdOrientationPortrait) {
        interstitialSupportedOrientations |=
        (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
    } else if (self.adOrientation == LoopMeAdOrientationLandscape) {
        interstitialSupportedOrientations |= UIInterfaceOrientationMaskLandscape;
    }
    
    return interstitialSupportedOrientations;
}

#pragma mark - Public

- (void)setOrientation:(LoopMeAdOrientation)orientation {
    self.adOrientation = orientation;
}

#pragma mark Notifications

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceShaken" object:self];
    }
}

#pragma mark - Public

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    if ([self.delegate respondsToSelector:@selector(viewWillTransitionToSize:)]) {
        [self.delegate viewWillTransitionToSize:size];
    }
}

@end
