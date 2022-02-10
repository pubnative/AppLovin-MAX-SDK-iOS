//
//  ALVerveMediationInterstitialAdapter.m
//  AppLovin MAX Demo App - ObjC
//
//  Created by Eros Garcia Ponte on 09.02.22.
//  Copyright © 2022 AppLovin Corporation. All rights reserved.
//

#import "ALVerveMediationInterstitialAdapter.h"
#import <HyBid.h>

@interface ALVerveMediationInterstitialAdDelegate : NSObject<HyBidInterstitialAdDelegate>
@property (nonatomic, weak) ALVerveMediationInterstitialAdapter *parentAdapter;
@property (nonatomic, strong) id<MAInterstitialAdapterDelegate> delegate;
- (instancetype)initWithParentAdapter:(ALVerveMediationInterstitialAdapter *)parentAdapter andNotify:(id<MAInterstitialAdapterDelegate>)delegate;
@end

@interface ALVerveMediationInterstitialAdapter()

@property (nonatomic, strong) HyBidInterstitialAd *interstitialAd;
@property (nonatomic, strong) ALVerveMediationInterstitialAdDelegate *interstitialAdapterDelegate;

@end

@implementation ALVerveMediationInterstitialAdapter

#pragma mark - MAInterstitialAdapter Methods

- (void)loadInterstitialAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAInterstitialAdapterDelegate>)delegate
{
    [self log: @"Loading interstitial ad"];
    
    [self updateConsentWithParameters: parameters];
    [self updateMuteStateForParameters: parameters];
    
    NSString* zoneId = [parameters thirdPartyAdPlacementIdentifier];
    
    if (!zoneId || ![zoneId al_isValidString]) {
        [delegate didFailToLoadInterstitialAdWithError:[MAAdapterError internalError]];
    } else {
        self.interstitialAdapterDelegate = [[ALVerveMediationInterstitialAdDelegate alloc] initWithParentAdapter: self andNotify: delegate];
        self.interstitialAd = [[HyBidInterstitialAd alloc] initWithZoneID:zoneId andWithDelegate:self.interstitialAdapterDelegate];

        [self.interstitialAd load];
    }
}

- (void)showInterstitialAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MAInterstitialAdapterDelegate>)delegate
{
    [self log: @"Showing interstitial ad..."];
    
    if ( [self.interstitialAd isReady] )
    {
        [self.interstitialAd showFromViewController: [ALUtils topViewControllerFromKeyWindow]];
    }
    else
    {
        [self log: @"Interstitial ad not ready"];
        [delegate didFailToDisplayInterstitialAdWithError: MAAdapterError.adNotReady];
    }
}

@end

@implementation ALVerveMediationInterstitialAdDelegate

- (instancetype)initWithParentAdapter:(ALVerveMediationInterstitialAdapter *)parentAdapter andNotify:(id<MAInterstitialAdapterDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
        self.delegate = delegate;
    }
    return self;
}

- (void)interstitialDidLoad
{
    [self.parentAdapter log: @"Interstitial ad loaded"];
    [self.delegate didLoadInterstitialAd];
}

- (void)interstitialDidFailWithError:(NSError *)error
{
    [self.parentAdapter log: @"Interstitial ad failed to load with error: %@", error];
    
    MAAdapterError *adapterError = [ALVerveMediationInterstitialAdapter toMaxError: error];
    [self.delegate didFailToLoadInterstitialAdWithError: adapterError];
}

- (void)interstitialDidTrackImpression
{
    [self.parentAdapter log: @"Interstitial did track impression"];
    [self.delegate didDisplayInterstitialAd];
}

- (void)interstitialDidTrackClick
{
    [self.parentAdapter log: @"Interstitial clicked"];
    [self.delegate didClickInterstitialAd];
}

- (void)interstitialDidDismiss
{
    [self.parentAdapter log: @"Interstitial hidden"];
    [self.delegate didHideInterstitialAd];
}

@end
