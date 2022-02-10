//
//  ALVerveMediationNativeAdapter.m
//  AppLovin MAX Demo App - ObjC
//
//  Created by Eros Garcia Ponte on 09.02.22.
//  Copyright © 2022 AppLovin Corporation. All rights reserved.
//

#import "ALVerveMediationNativeAdapter.h"
#import <HyBid.h>

@interface ALVerveMediationNativeAdDelegate : NSObject<HyBidNativeAdLoaderDelegate, HyBidNativeAdFetchDelegate, HyBidNativeAdDelegate>
@property (nonatomic, weak) ALVerveMediationNativeAdapter *parentAdapter;
@property (nonatomic, strong) id<MANativeAdAdapterDelegate> delegate;
@property (nonatomic, strong) NSDictionary<NSString *, id> *serverParameters;
- (instancetype)initWithParentAdapter:(ALVerveMediationNativeAdapter *)parentAdapter serverParameters:(NSDictionary<NSString *, id> *)serverParameters andNotify:(id<MANativeAdAdapterDelegate>)delegate;
@end

@interface MAVerveMediationNativeAd : MANativeAd
@property (nonatomic, weak) ALVerveMediationNativeAdapter *parentAdapter;
- (instancetype)initWithParentAdapter:(ALVerveMediationNativeAdapter *)parentAdapter builderBlock:(NS_NOESCAPE MANativeAdBuilderBlock)builderBlock;
@end

@interface ALVerveMediationNativeAdapter()

@property (nonatomic, strong) HyBidNativeAd *nativeAd;
@property (nonatomic, strong) ALVerveMediationNativeAdDelegate *nativeAdAdapterDelegate;

@end

@implementation ALVerveMediationNativeAdapter

#pragma mark - MANativeAdapter Methods

- (void)loadNativeAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MANativeAdAdapterDelegate>)delegate
{
    [self log: @"Loading rewarded ad"];
    
    [self updateConsentWithParameters: parameters];
    [self updateMuteStateForParameters: parameters];
    
    NSString* zoneId = [parameters thirdPartyAdPlacementIdentifier];
    
    if (!zoneId || ![zoneId al_isValidString]) {
        [delegate didFailToLoadNativeAdWithError:[MAAdapterError internalError]];
    } else {
        HyBidNativeAdLoader *nativeAdLoader = [[HyBidNativeAdLoader alloc] init];
        self.nativeAdAdapterDelegate = [[ALVerveMediationNativeAdDelegate alloc] initWithParentAdapter: self serverParameters: parameters.serverParameters andNotify: delegate];
        [nativeAdLoader loadNativeAdWithDelegate:self.nativeAdAdapterDelegate withZoneID:zoneId];
    }
}

@end

@implementation ALVerveMediationNativeAdDelegate

- (instancetype)initWithParentAdapter:(ALVerveMediationNativeAdapter *)parentAdapter serverParameters:(NSDictionary<NSString *,id> *)serverParameters andNotify:(id<MANativeAdAdapterDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
        self.serverParameters = serverParameters;
        self.delegate = delegate;
    }
    return self;
}

- (void)nativeLoaderDidLoadWithNativeAd:(HyBidNativeAd *)nativeAd
{
    [self.parentAdapter log: @"Native ad loaded"];
    
    if ( !self.parentAdapter.nativeAd )
    {
        [self.parentAdapter log: @"Native ad failed to load: no fill"];
        [self.delegate didFailToLoadNativeAdWithError: MAAdapterError.noFill];
            
        return;
    }
    
    self.parentAdapter.nativeAd = nativeAd;
    
    NSString *templateName = [self.serverParameters al_stringForKey: @"template" defaultValue: @""];
    BOOL isTemplateAd = [templateName al_isValidString];
    
    if ( ![self hasRequiredAssetsInAd: self.parentAdapter.nativeAd isTemplateAd: isTemplateAd] )
    {
        [self.parentAdapter e: @"Native ad (%@) does not have required assets.", nativeAd];
        [self.delegate didFailToLoadNativeAdWithError: [MAAdapterError errorWithCode: -5400 errorString: @"Missing Native Ad Assets"]];
            
        return;
    }
    
    [nativeAd fetchNativeAdAssetsWithDelegate:self];
}

- (void)nativeLoaderDidFailWithError:(NSError *)error
{
    [self.parentAdapter log: @"Native ad failed to load: %@", error];
    
    MAAdapterError *adapterError = [ALVerveMediationNativeAdapter toMaxError: error];
    [self.delegate didFailToLoadNativeAdWithError: adapterError];
}

- (void)nativeAdDidFinishFetching:(HyBidNativeAd *)nativeAd
{
    
}

- (void)nativeAd:(HyBidNativeAd *)nativeAd didFailFetchingWithError:(NSError *)error
{
    [self.parentAdapter log: @"Native ad failed to fetch assets: %@", error];
    
    MAAdapterError *adapterError = [ALVerveMediationNativeAdapter toMaxError: error];
    [self.delegate didFailToLoadNativeAdWithError: adapterError];
}

- (void)nativeAd:(HyBidNativeAd *)nativeAd impressionConfirmedWithView:(UIView *)view
{
    [self.parentAdapter log: @"Native ad shown"];
    if (self.delegate) {
        [self.delegate didDisplayNativeAdWithExtraInfo:nil];
    }
}

- (void)nativeAdDidClick:(HyBidNativeAd *)nativeAd
{
    [self.parentAdapter log: @"Native ad clicked"];
    if (self.delegate) {
        [self.delegate didClickNativeAd];
    }
}

- (BOOL)hasRequiredAssetsInAd:(HyBidNativeAd *)nativeAd isTemplateAd:(BOOL)isTemplateAd
{
    if ( isTemplateAd )
    {
        return [nativeAd.title al_isValidString];
    }
    else
    {
        return [nativeAd.title al_isValidString]
        && [nativeAd.callToActionTitle al_isValidString]
        && [nativeAd.bannerUrl al_isValidString];
    }
}

- (void)processNativeAd
{
    dispatchOnMainQueueNow(^{
        MAVerveMediationNativeAd *verveNativeAd = [[MAVerveMediationNativeAd alloc] initWithParentAdapter:self.parentAdapter builderBlock:^(MANativeAdBuilder *builder){
            
            UIView* bannerView = self.parentAdapter.nativeAd.banner;
            if (bannerView) {
                builder.mediaView = bannerView;
            }
            
            UIImage *iconImage = self.parentAdapter.nativeAd.icon;
            if (iconImage) {
                MANativeAdImage* icon = [[MANativeAdImage alloc] initWithImage: iconImage];
                builder.icon = icon;
            }
            
            if ([self.parentAdapter.nativeAd.title al_isValidString]) {
                builder.title = self.parentAdapter.nativeAd.title;
            }
            
            if ([self.parentAdapter.nativeAd.body al_isValidString]) {
                builder.body = self.parentAdapter.nativeAd.body;
            }
            
            if ([self.parentAdapter.nativeAd.callToActionTitle al_isValidString]) {
                builder.callToAction = self.parentAdapter.nativeAd.callToActionTitle;
            }
            
            HyBidContentInfoView *contentInfoView = self.parentAdapter.nativeAd.contentInfo;
            if (contentInfoView) {
                builder.optionsView = contentInfoView;
            }
        }];
        
        [self.delegate didLoadAdForNativeAd:verveNativeAd withExtraInfo:nil];
    });
}

@end

@implementation MAVerveMediationNativeAd

- (instancetype)initWithParentAdapter:(ALVerveMediationNativeAdapter *)parentAdapter builderBlock:(NS_NOESCAPE MANativeAdBuilderBlock)builderBlock
{
    self = [super initWithFormat: MAAdFormat.native builderBlock: builderBlock];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
    }
    return self;
}

- (void)prepareViewForInteraction:(MANativeAdView *)nativeAdView
{
    if (!self.parentAdapter.nativeAd) {
        [self.parentAdapter e: @"Failed to register native ad views: native ad is nil."];
        return;
    }
    
    [self.parentAdapter.nativeAd startTrackingView:nativeAdView withDelegate:self.parentAdapter.nativeAdAdapterDelegate];
}

@end
