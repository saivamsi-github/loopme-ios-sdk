# LoopMe-iOS-SDK #

[点击阅读SDK对接中文说明](README_CHINESE.md)

## Overview ##

LoopMe is the largest mobile video DSP and Ad Network, reaching over 1 billion consumers world-wide. LoopMe’s full-screen video and rich media ad formats deliver more engaging mobile advertising experiences to consumers on smartphones and tablets.

If you have questions please contact us at support@loopmemedia.com.

## Features ##

* Full-screen image interstitials
* Full-screen rich media interstitials
* Banner ads
* Preloaded video ads
* In-app ad reward notifications, including video view completed

## Requirements ##

An appKey is required to use the `loopme-ios-sdk`. The appKey uniquely identifies your app to the LoopMe ad network. (Example appKey: 7643ba4d53.) To get an appKey visit the **[LoopMe Dashboard](http://loopme.me/)**.

Requires `XCode 5` or higher, `iOS 6.0` and above. Built using `ARC`.

## Usage ##

Integrating the `loopme-ios-sdk` is very simple and should take less than 10 minutes.

* Download `loopme-ios-sdk`
* Copy the `loopme-sdk` folder to your `XCode` project
* Make sure following frameworks are added in `Xcode` project's `build phases`
  * `MessageUI.framework`
  * `StoreKit.framework`
  * `AVFoundation.framework`
  * `CoreMedia.framework`
  * `AudioToolbox.framework`
  * `AdSupport.framework`
  * `CoreTelephony.framework`
  * `SystemConfiguration.framework`  
* Add following flags to other linker flags in `XCode` project's `build settings`
  * `-ObjC`
  * `-all_load`
* Display full-screen interstitial or video ads:

```objective-c
#import "LoopMeInterstitial.h"

/* ... */  

@property (nonatomic, strong) LoopMeInterstitial *interstitial;

/* ... */

// Initialize the LoopMe interstitial,
// using the unique appKey you received when registering your app via the LoopMe Dashboard:
self.interstitial = [LoopMeInterstitial interstitialWithAppKey:YOUR_APPKEY
                                                      delegate:self];
/* ... */

// Use this method to preload the interstitial for display
// (we also recommend to trigger it in -interstitialDidDisappear delegate method to keep content up-to-date)
[self.interstitial loadAd];

/* ... */

// Displaying the LoopMe Interstitial can be user-initiated (e.g press on button)
// or publisher-initiated (e.g. end of game level)
[self.interstitial showFromViewController:self];

```
* Implement `LoopMeInterstitialDelegate` in order to receive notifications during the loading/displaying ad processes, that you can use to trigger subsequent in-app events:
   * `-loopMeInterstitialDidLoadAd`: triggered when interstitial has been loaded the ad content
   * `-loopMeInterstitial: didFailToLoadAdWithError:`: triggered when interstitial failed to load the ad content
   * `-loopMeInterstitialWillAppear`: triggered when interstitial ad will appear on the screen
   * `-loopMeInterstitialDidAppear:`: triggered when interstitial ad did appear on the screen
   * `-loopMeInterstitialWillDisappear`: triggered when interstitial ad will disappear from the screen
   * `-loopMeInterstitialDidDisappear`: triggered when interstitial ad did disappear from the screen
   * `-loopMeInterstitialVideoDidReachEnd`: triggered when interstitial video ad has been completely watched
   * `-loopMeInterstitialDidReceiveTap`: triggered when interstitial ad was clicked
   * `-loopMeInterstitialDidExpire`: triggered when interstitial ad is expired, it is recommended to re-load


* Display banner ads:

   ```objective-c
   #import "LoopMeBanner.h"

   /* ... */  

   @property (nonatomic, strong) LoopMeBanner *banner;

   /* ... */

   // Initialize the LoopMe banner,
   // using the unique appKey you received when registering your app via the LoopMe Dashboard:
   self.banner = [LoopMeBanner bannerWithAppKey:YOUR_APPKEY
   delegate:self];
   /* ... */

   // Banner ad remains on the screen and refreshes automatically.
   // If the user leaves screen this is developer's responsibility to hide banner and stop sending ad requests.
   [self.banner  showInView:parentView
                  withFrame:CGRectMake(x, y, LOOPME_AD_SIZE_320_50.width, LOOPME_AD_SIZE_320_50.height)];
   ```
* Implement `LoopMeBannerDelegate` in order to receive notifications during the loading/displaying ad processes, that you can use to trigger subsequent in-app events:
   * `-loopMeBanner: didFailToLoadAdWithError:`: triggered when interstitial failed to load the ad content
   * `-loopMeBannerDidAppear:`: triggered when banner ad did appear on the screen
   * `-loopMeBannerDidDisappear`: triggered when banner ad did disappear from the screen
   * `-loopMeBannerDidReceiveTap`: triggered when banner ad was clicked

## Sample project ##

Check out our `Demo` project as an example of `loopme-ios-sdk` integration.

## What's new ##
**v4.0.1**

* Video preloading performance improvements
* New video ad UI design
* Completed video view notification added

## License ##

see [License](LICENSE.md)
