//
//  ALVerveMediationBaseAdapter.h
//  AppLovin MAX Demo App - ObjC
//
//  Created by Eros Garcia Ponte on 09.02.22.
//  Copyright © 2022 AppLovin Corporation. All rights reserved.
//

#import <AppLovinSDK/AppLovinSDK.h>

@interface ALVerveMediationBaseAdapter : ALMediationAdapter

- (void)updateConsentWithParameters:(id<MAAdapterParameters>)parameters;
- (void)updateMuteStateForParameters:(id<MAAdapterResponseParameters>)parameters;

+ (MAAdapterError *)toMaxError:(NSError *)verveError;

@end
