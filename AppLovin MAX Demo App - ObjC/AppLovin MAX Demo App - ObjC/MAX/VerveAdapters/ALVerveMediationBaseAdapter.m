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

@end
