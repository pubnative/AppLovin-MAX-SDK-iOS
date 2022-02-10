//
//  ALVerveMediationBaseAdapter.m
//  AppLovin MAX Demo App - ObjC
//
//  Created by Eros Garcia Ponte on 09.02.22.
//  Copyright © 2022 AppLovin Corporation. All rights reserved.
//

#import "ALVerveMediationBaseAdapter.h"
#import <HyBid.h>

#define VERVE_ADAPTER_VERSION @"2.11.0.0"

@implementation ALVerveMediationBaseAdapter

static ALAtomicBoolean *ALVerveInitialized;
static MAAdapterInitializationStatus ALVerveInitializationStatus = NSIntegerMin;

+ (void)initialize
{
    [super initialize];
    ALVerveInitialized = [[ALAtomicBoolean alloc] init];
}

#pragma mark - ALMediationAdapter Methods

- (void)initializeWithParameters:(id<MAAdapterInitializationParameters>)parameters completionHandler:(void (^)(MAAdapterInitializationStatus, NSString * _Nullable))completionHandler
{
    if ( [ALVerveInitialized compareAndSet: NO update: YES] )
    {
        ALVerveInitializationStatus = MAAdapterInitializationStatusInitializing;
        
        NSString *appToken = [parameters.serverParameters al_stringForKey: @"app_token" defaultValue: @""];
        [self log: @"Initializing Verve SDK with app token: %@...", appToken];
        
        if ( [parameters isTesting] )
        {
            [HyBid setTestMode: YES];
            [HyBidLogger setLogLevel: HyBidLogLevelDebug];
        }
        
        [HyBid setLocationUpdates: NO];
        [HyBid initWithAppToken: appToken completion:^(BOOL success) {
            if ( success )
            {
                [self log: @"Verve SDK initialized"];
                ALVerveInitializationStatus = MAAdapterInitializationStatusInitializedSuccess;
            }
            else
            {
                [self log: @"Verve SDK failed to initialize"];
                ALVerveInitializationStatus = MAAdapterInitializationStatusInitializedFailure;
            }
            
            completionHandler(ALVerveInitializationStatus, nil);
        }];
    }
    else
    {
        [self log: @"Verve attempted to intialize already - marking initialization as %ld", ALVerveInitializationStatus];
        completionHandler(ALVerveInitializationStatus, nil);
    }
}

- (NSString *)SDKVersion
{
    return [HyBid getSDKVersionInfo];
}

- (NSString *)adapterVersion
{
    return VERVE_ADAPTER_VERSION;
}

- (void)destroy
{
    [super destroy];
}

#pragma mark - Shared Methods

- (void)updateConsentWithParameters:(id<MAAdapterParameters>)parameters
{
    if ( self.sdk.configuration.consentDialogState == ALConsentDialogStateApplies )
    {
        NSNumber *hasUserConsent = parameters.hasUserConsent;
        if ( hasUserConsent )
        {
            [[HyBidUserDataManager sharedInstance] setIABGDPRConsentString: hasUserConsent.boolValue ? @"1" : @"0"];
        }
        else { /* Don't do anything if huc value not set */ }
    }
    
    NSNumber *isAgeRestrictedUser = parameters.ageRestrictedUser;
    if ( isAgeRestrictedUser )
    {
        [HyBid setCoppa: isAgeRestrictedUser.boolValue];
    }
    
    if ( ALSdk.versionCode >= 61100 )
    {
        NSNumber *isDoNotSell = parameters.doNotSell;
        if ( isDoNotSell && isDoNotSell.boolValue )
        {
            [[HyBidUserDataManager sharedInstance] setIABUSPrivacyString: @"1NYN"];
        }
        else
        {
            [[HyBidUserDataManager sharedInstance] removeIABUSPrivacyString];
        }
    }
}

- (void)updateMuteStateForParameters:(id<MAAdapterResponseParameters>)parameters
{
    NSDictionary<NSString *, id> *serverParameters = parameters.serverParameters;
    if ( [serverParameters al_containsValueForKey: @"is_muted"] )
    {
        BOOL muted = [serverParameters al_numberForKey: @"is_muted"].boolValue;
        if ( muted )
        {
            [HyBid setVideoAudioStatus: HyBidAudioStatusMuted];
        }
        else
        {
            [HyBid setVideoAudioStatus: HyBidAudioStatusDefault];
        }
    }
}

+ (MAAdapterError *)toMaxError:(NSError *)verveError
{
    NSInteger verveErrorCode = verveError.code;
    MAAdapterError *adapterError = MAAdapterError.unspecified;
    switch ( verveErrorCode )
    {
        case 1: // No Fill
        case 6: // Null Ad
            adapterError = MAAdapterError.noFill;
            break;
        case 2: // Parse Error
        case 3: // Server Error
            adapterError = MAAdapterError.serverError;
            break;
        case 4: // Invalid Asset
        case 5: // Unsupported Asset
            adapterError = MAAdapterError.invalidConfiguration;
            break;
        case 7: // Invalid Ad
        case 8: // Invalid Zone ID
        case 9: // Invalid Signal Data
            adapterError = MAAdapterError.badRequest;
            break;
        case 10: // Not Initialized
            adapterError = MAAdapterError.notInitialized;
            break;
        case 11: // Auction No Ad
        case 12: // Rendering Banner
        case 13: // Rendering Interstitial
        case 14: // Rendering Rewarded
            adapterError = MAAdapterError.adNotReady;
            break;
        case 15: // Mraid Player
        case 16: // Vast Player
        case 17: // Tracking URL
        case 18: // Tracking JS
        case 19: // Invalid URL
        case 20: // Internal
            adapterError = MAAdapterError.internalError;
            break;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [MAAdapterError errorWithCode: adapterError.errorCode
                             errorString: adapterError.errorMessage
                  thirdPartySdkErrorCode: verveErrorCode
               thirdPartySdkErrorMessage: verveError.localizedDescription];
#pragma clang diagnostic pop
}

@end
