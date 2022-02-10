//
//  ALVerveMediationBannerAdapter.m
//  AppLovin MAX Demo App - ObjC
//
//  Created by Eros Garcia Ponte on 09.02.22.
//  Copyright © 2022 AppLovin Corporation. All rights reserved.
//

#import "ALVerveMediationBannerAdapter.h"
#import <HyBid.h>

@interface ALVerveMediationBannerDelegate : NSObject<HyBidAdViewDelegate>
@property (nonatomic, weak) ALVerveMediationBannerAdapter *parentAdapter;
@property (nonatomic, strong) id<MAAdViewAdapterDelegate> delegate;
- (instancetype)initWithParentAdapter:(ALVerveMediationBannerAdapter *)parentAdapter andNotify:(id<MAAdViewAdapterDelegate>)delegate;
@end

@interface ALVerveMediationBannerAdapter()

@property (nonatomic, strong) HyBidAdView *adViewAd;
@property (nonatomic, strong) ALVerveMediationBannerDelegate *adViewAdapterDelegate;

@end

@implementation ALVerveMediationBannerAdapter

- (HyBidAdSize *)sizeFromAdFormat:(MAAdFormat *)adFormat
{
    if ( adFormat == MAAdFormat.banner )
    {
        return HyBidAdSize.SIZE_320x50;
    }
    else if ( adFormat == MAAdFormat.leader )
    {
        return HyBidAdSize.SIZE_728x90;
    }
    else if ( adFormat == MAAdFormat.mrec )
    {
        return HyBidAdSize.SIZE_300x250;
    }
    else
    {
        [NSException raise: NSInvalidArgumentException format: @"Invalid ad format: %@", adFormat];
        return HyBidAdSize.SIZE_320x50;
    }
}

#pragma mark - MAAdViewAdapter Methods

- (void)loadAdViewAdForParameters:(id<MAAdapterResponseParameters>)parameters adFormat:(MAAdFormat *)adFormat andNotify:(id<MAAdViewAdapterDelegate>)delegate
{
    [self log: @"Loading %@ ad view ad...", adFormat.label];
    
    [self updateConsentWithParameters: parameters];
    [self updateMuteStateForParameters: parameters];
    
    NSString* zoneId = [parameters thirdPartyAdPlacementIdentifier];
    
    if (!zoneId || ![zoneId al_isValidString]) {
        [delegate didFailToLoadAdViewAdWithError:[MAAdapterError internalError]];
    } else {
        self.adViewAd = [[HyBidAdView alloc] initWithSize: [self sizeFromAdFormat: adFormat]];
        self.adViewAdapterDelegate = [[ALVerveMediationBannerDelegate alloc] initWithParentAdapter: self andNotify: delegate];
        self.adViewAd.delegate = self.adViewAdapterDelegate;
        
        [self.adViewAd loadWithZoneID:zoneId andWithDelegate:self.adViewAdapterDelegate];
    }
}

@end

@implementation ALVerveMediationBannerDelegate

- (instancetype)initWithParentAdapter:(ALVerveMediationBannerAdapter *)parentAdapter andNotify:(id<MAAdViewAdapterDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
        self.delegate = delegate;
    }
    return self;
}

- (void)adViewDidLoad:(HyBidAdView *)adView
{
    [self.parentAdapter log: @"AdView ad loaded"];
    [self.delegate didLoadAdForAdView: adView];
}

- (void)adView:(HyBidAdView *)adView didFailWithError:(NSError *)error
{
    [self.parentAdapter log: @"AdView failed to load: %@", error];
    
    MAAdapterError *adapterError = [ALVerveMediationBannerAdapter toMaxError: error];
    [self.delegate didFailToLoadAdViewAdWithError: adapterError];
}

- (void)adViewDidTrackImpression:(HyBidAdView *)adView
{
    [self.parentAdapter log: @"AdView did track impression: %@", adView];
    [self.delegate didDisplayAdViewAd];
}

- (void)adViewDidTrackClick:(HyBidAdView *)adView
{
    [self.parentAdapter log: @"AdView clicked: %@", adView];
    [self.delegate didClickAdViewAd];
}

@end
