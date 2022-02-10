//
//  ALVerveMediationRewardedAdapter.m
//  AppLovin MAX Demo App - ObjC
//
//  Created by Eros Garcia Ponte on 09.02.22.
//  Copyright © 2022 AppLovin Corporation. All rights reserved.
//

#import "ALVerveMediationRewardedAdapter.h"
#import <HyBid.h>

@interface ALVerveMediationRewardedAdsDelegate : NSObject<HyBidRewardedAdDelegate>
@property (nonatomic, weak) ALVerveMediationRewardedAdapter *parentAdapter;
@property (nonatomic, strong) id<MARewardedAdapterDelegate> delegate;
@property (nonatomic, assign, getter=hasGrantedReward) BOOL grantedReward;
- (instancetype)initWithParentAdapter:(ALVerveMediationRewardedAdapter *)parentAdapter andNotify:(id<MARewardedAdapterDelegate>)delegate;
@end

@interface ALVerveMediationRewardedAdapter()

@property (nonatomic, strong) HyBidRewardedAd *rewardedAd;
@property (nonatomic, strong) ALVerveMediationRewardedAdsDelegate *rewardedAdapterDelegate;

@end

@implementation ALVerveMediationRewardedAdapter

#pragma mark - MARewardAdapter Methods

- (void)loadRewardedAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MARewardedAdapterDelegate>)delegate
{
    [self log: @"Loading rewarded ad"];
    
    [self updateConsentWithParameters: parameters];
    [self updateMuteStateForParameters: parameters];
    
    NSString* zoneId = [parameters thirdPartyAdPlacementIdentifier];
    
    if (!zoneId || ![zoneId al_isValidString]) {
        [delegate didFailToLoadRewardedAdWithError:[MAAdapterError internalError]];
    } else {
        self.rewardedAdapterDelegate = [[ALVerveMediationRewardedAdsDelegate alloc] initWithParentAdapter: self andNotify: delegate];
        self.rewardedAd = [[HyBidRewardedAd alloc] initWithZoneID:zoneId andWithDelegate:self.rewardedAdapterDelegate];
        
        [self.rewardedAd load];
    }
}

- (void)showRewardedAdForParameters:(id<MAAdapterResponseParameters>)parameters andNotify:(id<MARewardedAdapterDelegate>)delegate
{
    [self log: @"Showing rewarded ad..."];
    
    if ( [self.rewardedAd isReady] )
    {
        [self configureRewardForParameters: parameters];
        [self.rewardedAd showFromViewController: [ALUtils topViewControllerFromKeyWindow]];
    }
    else
    {
        [self log: @"Rewarded ad not ready"];
        [delegate didFailToDisplayRewardedAdWithError: MAAdapterError.adNotReady];
    }
}

@end

@implementation ALVerveMediationRewardedAdsDelegate

- (instancetype)initWithParentAdapter:(ALVerveMediationRewardedAdapter *)parentAdapter andNotify:(id<MARewardedAdapterDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.parentAdapter = parentAdapter;
        self.delegate = delegate;
    }
    return self;
}

- (void)rewardedDidLoad
{
    [self.parentAdapter log: @"Rewarded ad loaded"];
    [self.delegate didLoadRewardedAd];
}

- (void)rewardedDidFailWithError:(NSError *)error
{
    [self.parentAdapter log: @"Rewarded ad failed to load with error: %@", error];
    
    MAAdapterError *adapterError = [ALVerveMediationRewardedAdapter toMaxError: error];
    [self.delegate didFailToLoadRewardedAdWithError: adapterError];
}

- (void)rewardedDidTrackImpression
{
    [self.parentAdapter log: @"Rewarded ad did track impression"];
    [self.delegate didDisplayRewardedAd];
    [self.delegate didStartRewardedAdVideo];
}

- (void)rewardedDidTrackClick
{
    [self.parentAdapter log: @"Rewarded ad clicked"];
    [self.delegate didClickRewardedAd];
}

- (void)onReward
{
    [self.parentAdapter log: @"Rewarded ad reward granted"];
    self.grantedReward = YES;
}

- (void)rewardedDidDismiss
{
    [self.parentAdapter log: @"Rewarded ad did disappear"];
    [self.delegate didCompleteRewardedAdVideo];
    
    if ( [self hasGrantedReward] || [self.parentAdapter shouldAlwaysRewardUser] )
    {
        MAReward *reward = [self.parentAdapter reward];
        [self.parentAdapter log: @"Rewarded user with reward: %@", reward];
        [self.delegate didRewardUserWithReward: reward];
    }
    
    [self.parentAdapter log: @"Rewarded ad hidden"];
    [self.delegate didHideRewardedAd];
}

@end
