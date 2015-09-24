# LoopMe-iOS-SDK #

[点击阅读SDK对接中文说明](README_CHINESE.md)

1. **[Overview](#overview)**
2. **[Features](#features)**
3. **[Requirements](#requirements)**
4. **[Integration](#integration)**
  * **[Full screen interstitial ads](#full-screen-interstitial-ads)**
  * **[In-stream ads](#in-stream-ads)**
5. **[Sample project](#sample-project)**
6. **[What's new](#whats-new)**

## Overview ##

LoopMe is the largest mobile video DSP and Ad Network, reaching over 1 billion consumers world-wide. LoopMe’s full-screen video and rich media ad formats deliver more engaging mobile advertising experiences to consumers on smartphones and tablets.

The LoopMe SDK is distributed as source code that you must include in your application and provides facilities to retrieve, display ads in your application.

If you have questions please contact us at support@loopmemedia.com.

## Features ##

* Full-screen image interstitials
* Full-screen rich media interstitials
* Preloaded video ads
* In-stream ads
* Minimized ad
* In-app ad reward notifications, including video view completed

## Requirements ##

An appKey is required to use the `loopme-ios-sdk`. The appKey uniquely identifies your app to the LoopMe ad network. (Example appKey: 7643ba4d53.) To get an appKey visit the **[LoopMe Dashboard](http://loopme.me/)**.

Requires `XCode 6` or higher, `iOS 7.0` and above. Built using `ARC`.

## Integration ##

* Download `loopme-ios-sdk` from this repository
* Copy the  `LoopMeSDK` folder into your Xcode application project
* Make sure following frameworks are added in `Xcode` project's `build phases`
  * `MessageUI.framework`
  * `StoreKit.framework`
  * `AVFoundation.framework`
  * `CoreMedia.framework`
  * `AudioToolbox.framework`
  * `AdSupport.framework`
  * `CoreTelephony.framework`
  * `SystemConfiguration.framework`  

## Preparing Integration For iOS9 ##

To use LoopMe SDK on iOS 9 you need follow next steps:
* Ensure that `loopme-ios-sdk` has version 5.1.3 or higher
* Add the following to your app's plist file to allow any insecure connection:

```objective-c
    <key>NSAppTransportSecurity</key>
    <dict>
       <key>NSAllowsArbitraryLoads</key>
       <true/>
    </dict>
```

## Full-screen interstitial ads ##

The `LoopMenterstitial` class provides the facilities to display a full-screen ad during natural transition points in your application.

```objective-c
#import "LoopMeInterstitial.h"

/* ... */  

@property (nonatomic, strong) LoopMeInterstitial *interstitial;

/* ... */

/** 
 * Initialize the LoopMe interstitial ad
 * using the unique appKey you received when registering your app via the LoopMe Dashboard.
 * For test purposes you can use test appKeys constants defined in LoopMeInterstitial.h
 */
self.interstitial = [LoopMeInterstitial interstitialWithAppKey:YOUR_APPKEY
                                                      delegate:self];
/* ... */

/**
 * Starts loading ad content process.
 * It is recommended triggering it in advance to have interstitial ad ready 
 * and to be able to display instantly in your application.
 */
[self.interstitial loadAd];

/* ... */

/**
 * Displaying the Interstitial.
 * Can be user-initiated (e.g press on button) or publisher-initiated (e.g. end of game level)
 */
[self.interstitial showFromViewController:self];

```
 * It is recommended to implement `LoopMeInterstitialDelegate` in order to receive notifications during the loading/displaying ad processes, that you can use to trigger subsequent in-app events:
   * `-loopMeInterstitialDidLoadAd`: triggered when interstitial has been loaded the ad content
   * `-loopMeInterstitial: didFailToLoadAdWithError:`: triggered when interstitial failed to load the ad content
   * `-loopMeInterstitialVideoDidReachEnd`: triggered when interstitial video ad has been completely watched
   * `-loopMeInterstitialWillAppear`: triggered when interstitial ad will appear on the screen
   * `-loopMeInterstitialDidAppear:`: triggered when interstitial ad did appear on the screen
   * `-loopMeInterstitialWillDisappear`: triggered when interstitial ad will disappear from the screen
   * `-loopMeInterstitialDidDisappear`: triggered when interstitial ad did disappear from the screen
   * `-loopMeInterstitialDidReceiveTap`: triggered when interstitial ad was tapped


## In-stream ads ##

The `LoopMeAdView` class provides facilities to display a custom size ads during natural transition points in your application.

```objective-c
#import "LoopMeAdView.h"

/* ... */  

@property (nonatomic, strong) LoopMeAdView *adView;

/* ... */  

/**
* Initialize the LoopMe AdView 
* using the unique appKey you received when registering your app via the LoopMe Dashboard.
* For test purposes you can use test appKeys constants defined in LoopMeAdView.h    
*/
CGRect adFrame = CGRectMake(0, 0, 300, 250);
self.adView = [LoopMeAdView adViewWithAppKey:YOUR_APPKEY frame:adFrame delegate:self];

/* ... */

/**
 * Starts loading ad content process.
 * It is recommended triggering it in advance to have ad ready to be displyaed 
 * and to be able to display instantly in your application.
 */
[self.adView loadAd];

/* ... */

/**
* Add adView as a subview to your view, LoopMeAdView is inherited from UIView class.
* It is recommended to add adView to your view when the ad content was loaded
*/
- (void)loopMeAdViewDidLoadAd:(LoopMeAdView *)adView {
    [yourView addSubview:adView];
}

/**
 * Sometimes there is a necessity to pause/resume the ad's activity 
 * during natural transitions between your views or view controllers
 * You can use this method to manage ad visibility 
 */
 - (void)setAdVisible:(BOOL)visible;
   ```

**Displaying in scrollable content**
```objective-c
/**
* IMPORTANT: if adView will be added to scrollable content, 
* you should pass instance of your scrollView (f.e tableView) when initialise adView,
* to let it manage ad content activity (f.e pause/resumes video when ad visibility changes)
*/ 
self.adView = [LoopMeAdView adViewWithAppKey:YOUR_APPKEY frame:adFrame scrollView:tableView delegate:self];

/*
* Enabling minimized mode.
* Represents copy of original ad added on top of `UIWindow`'s right-bottom corner.
* Minimized ad appears/disappears on the screen during scrolling when visibility of original ad is changed
*/
self.adView.minimizedModeEnabled = YES;

/**
 * Also you should let adView know when scrolling happens
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.adView updateAdVisibilityInScrollView];
}
   ```
   
* It is recommended to implement `LoopMeAdViewDelegate` in order to receive notifications during the loading/displaying ad processes, that you can use to trigger subsequent in-app events:
   * `-loopMeAdViewDidLoadAd`: triggered when adView has been loaded the ad content
   * `-loopMeAdView: didFailToLoadAdWithError:`: triggered when adView failed to load the ad content
   * `-loopMeAdViewVideoDidReachEnd`: triggered when adView video ad has been completely watched
   * `-loopMeInterstitialDidReceiveTap`: triggered when adView ad was tapped
   * `-loopMeInterstitialDidExpire`:  triggered when the adView's loaded ad content is expired

## Sample project ##

Check out our `Demo` project as an example of `loopme-ios-sdk` integration.

## What's new ##
**v5.2.1**

Please view the [changelog](CHANGELOG.md) for details.

- Fixed redirect URL handling after clicking on Ad

## License ##

see [License](LICENSE.md)
