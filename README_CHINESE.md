# LoopMe-iOS-SDK #

Please note that this readme is compatible with the `LoopMe iOS SDK` v5.1.0.

## 概览 ##

LoopMe是最大的移动视频DSP和广告网络，全球覆盖受众超过10亿。LoopMe的全屏视频和富媒体广告格式给受众带来互动性强的移动广告经验。

如果您有任何问题，请联系support@loopmemedia.com。

## 特点 ##

* 全屏静态图片插屏广告
* 全屏富媒体插屏广告
* 横幅广告
* 预加载视频广告
* 应用内置奖励提醒（包括视频完整浏览）

## 要求 ##

在您使用`loopme-ios-sdk`前，您需要前往我们的**[系统后台](http://loopme.me/)** 注册并获取appKey。appKey是用来在我们的广告网络中识别您的应用的。（示例appKey：7643ba4d53）.

仅支持`XCode 5`及更高系统, `iOS 6.0`及更高系统。用`ARC`编译。

## 使用 ##

`loopme-ios-sdk`的对接非常简单，能在10分钟内完成。

* 下载 `loopme-ios-sdk`
* 复制 `loopme-sdk` 文件夹到您的`XCode`项目
* 请确保在 `Xcode`项目中的`build phases`加入以下框架：
  * `MessageUI.framework`
  * `StoreKit.framework`
  * `AVFoundation.framework`
  * `CoreMedia.framework`
  * `AudioToolbox.framework`
  * `AdSupport.framework`
  * `CoreTelephony.framework`
  * `SystemConfiguration.framework`  
* 把以下flags加在`Xcode`的`build settings`的Other linker flags中
  * `-ObjC`
  * `-all_load`
* 展示全屏插屏或视频广告:

```objective-c
#import "LoopMeInterstitial.h"

/* ... */  

@property (nonatomic, strong) LoopMeInterstitial *interstitial;

/* ... */

// 初始化LoopMe的插屏广告,
// 使用您在LoopMe后台注册app后得到的appKey:
self.interstitial = [LoopMeInterstitial interstitialWithAppKey:YOUR_APPKEY
                                                      delegate:self];
/* ... */

// 用这个方法来预加载插屏
//（我们也推荐在-interstitialDidDisappear delegate方法中触发以便内容更新）
[self.interstitial loadAd];

/* ... */

// LoopMe插屏广告的展示可以为用户发起的（比如：点击播放按钮）
// 或开发者发起（如游戏回合结束后）
[self.interstitial showFromViewController:self];

```
* 实现 `LoopMeInterstitialDelegate`在载入/展示广告过程中接受通知，以便您触发随后的应用内置事件：
* `-loopMeInterstitialDidLoadAd`: 当插屏广告载入广告内容时触发
* `-loopMeInterstitial: didFailToLoadAdWithError:`: 当插屏广告载入广告内容失败时触发
* `-loopMeInterstitialWillAppear`: 当插屏广告即将展示时触发
* `-loopMeInterstitialDidAppear:`: 当插屏广告完成展示时触发
* `-loopMeInterstitialWillDisappear`: 当插屏广告将在屏幕消失时触发
* `-loopMeInterstitialDidDisappear`: 当插屏广告完成从屏幕消失时触发
* `-loopMeInterstitialVideoDidReachEnd`: 当插屏视频广告完整播放时触发
* `-loopMeInterstitialDidReceiveTap`: 当插屏广告被点击时触发
* `-loopMeInterstitialDidExpire`: 当插屏广告失效并推荐重新载入时触发


* 展示横幅广告:

   ```objective-c
   #import "LoopMeBanner.h"

   /* ... */  

   @property (nonatomic, strong) LoopMeBanner *banner;

   /* ... */

   // 初始化LoopMe横幅广告
   // 使用您在LoopMe后台注册app后得到的appKey:
   self.banner = [LoopMeBanner bannerWithAppKey:YOUR_APPKEY
   delegate:self];
   /* ... */

   // 横幅广告会停留在屏幕上并且自动更新.
   // 当用户离开屏幕时，开发者有责任隐藏横幅广告并且停止发送广告请求
   [self.banner  showInView:parentView
                  withFrame:CGRectMake(x, y, LOOPME_AD_SIZE_320_50.width, LOOPME_AD_SIZE_320_50.height)];
   ```
* 实现 `LoopMeBannerDelegate`在载入/展示广告过程中接受通知，以便您触发随后的应用内置事件：
   * `-loopMeBanner: didFailToLoadAdWithError:`: 当横幅广告加载广告内容失败时触发
   * `-loopMeBannerDidAppear:`: 当横幅广告完成展示时触发
   * `-loopMeBannerDidDisappear`: 当横幅广告完成从屏幕消失时触发
   * `-loopMeBannerDidReceiveTap`: 当横幅广告被点击时触发

## 示例 ##

请查看我们的`Demo`项目 - `loopme-ios-sdk` 对接后示例.

## 更新 ##
**v4.0.1**

* 视频预加载表现改善
* 新视频广告UI设计
* 添加了完整视频播放提示

## 许可 ##

详见 [License](LICENSE.md)
