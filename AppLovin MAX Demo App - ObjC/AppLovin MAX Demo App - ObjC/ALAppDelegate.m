//
//  ALAppDelegate.m
//  DemoApp-ObjC
//
//  Created by Thomas So on 9/4/19.
//  Copyright © 2019 AppLovin Corporation. All rights reserved.
//

#import "ALAppDelegate.h"
#import <Adjust/Adjust.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import <HyBid/HyBid.h>
#if __has_include(<HyBid/HyBid-Swift.h>)
    #import <HyBid/HyBid-Swift.h>
#else
    #import "HyBid-Swift.h"
#endif
#if __has_include(<ATOM/ATOM-Swift.h>)
    #import <ATOM/ATOM-Swift.h>
#endif

@implementation ALAppDelegate

// If you want to test your own AppLovin SDK key, change the value here and update the bundle identifier in the xcodeproj.
static NSString *const YOUR_SDK_KEY = @"sMRyqsHzbW5B55p5RLfJTNaXBH1rFzvkU5_LGa_Kerigolzf62Jl6iwzLtMIqn2XRt0tDol1bAc8g0N7C7c51N";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Create the initialization configuration
    ALSdkInitializationConfiguration *initConfig = [ALSdkInitializationConfiguration configurationWithSdkKey: YOUR_SDK_KEY builderBlock:^(ALSdkInitializationConfigurationBuilder *builder) {

        builder.mediationProvider = ALMediationProviderMAX;
        
        // Enable test mode by default for the current device.
        /*NSString *currentIDFV = UIDevice.currentDevice.identifierForVendor.UUIDString;
        if ( currentIDFV.length > 0 )
        {
            builder.testDeviceAdvertisingIdentifiers = @[currentIDFV];
        }*/
    }];

    // Initialize the SDK with the configuration
    [[ALSdk shared] initializeWithConfiguration: initConfig completionHandler:^(ALSdkConfiguration *sdkConfig) {
        // AppLovin SDK is initialized, start loading ads now or later if ad gate is reached
        
        // Initialize Adjust SDK
        ADJConfig *adjustConfig = [ADJConfig configWithAppToken: @"{YourAppToken}" environment: ADJEnvironmentSandbox];
        [Adjust appDidLaunch: adjustConfig];
        
        NSError *atomError = nil;
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        [Atom startWithApiKey:bundleID isTest:NO error:&atomError withCallback:^(BOOL isSuccess) {
                if (isSuccess) {
                    NSArray *atomCohorts = [Atom getCohorts];
                    [HyBidLogger infoLogFromClass:NSStringFromClass([self class]) fromMethod:NSStringFromSelector(_cmd) withMessage:[NSString stringWithFormat: [[NSString alloc] initWithFormat: @"ATOM: Received ATOM cohorts: %@", atomCohorts], NSStringFromSelector(_cmd)]];
                    [HyBidLogger infoLogFromClass:NSStringFromClass([self class]) fromMethod:NSStringFromSelector(_cmd) withMessage:[NSString stringWithFormat: [[NSString alloc] initWithFormat: @"ATOM: started"], NSStringFromSelector(_cmd)]];
                } else {
                    NSString *atomInitResultMessage = [[NSString alloc] initWithFormat:@"Coultdn't initialize ATOM with error: %@", [atomError localizedDescription]];
                    [HyBidLogger errorLogFromClass:NSStringFromClass([self class]) fromMethod:NSStringFromSelector(_cmd) withMessage:[NSString stringWithFormat: atomInitResultMessage, NSStringFromSelector(_cmd)]];
                }
            }];
    }];
    
    UIColor *barTintColor = [UIColor colorWithRed: 10/255.0 green: 131/255.0 blue: 170/255.0 alpha: 1.0];
    if ( @available(iOS 15.0, *) )
    {
        UINavigationBarAppearance *navigationBarAppearance = [[UINavigationBarAppearance alloc] init];
        [navigationBarAppearance configureWithOpaqueBackground];
        navigationBarAppearance.backgroundColor = barTintColor;
        navigationBarAppearance.titleTextAttributes = @{NSForegroundColorAttributeName : UIColor.whiteColor};
        [UINavigationBar appearance].standardAppearance = navigationBarAppearance;
        [UINavigationBar appearance].scrollEdgeAppearance = navigationBarAppearance;
        [UINavigationBar appearance].tintColor = UIColor.whiteColor;
    }
    else
    {
        // Fallback on earlier versions
        [UINavigationBar appearance].barTintColor = barTintColor;
        [UINavigationBar appearance].titleTextAttributes = @{NSForegroundColorAttributeName : UIColor.whiteColor};
        [UINavigationBar appearance].tintColor = UIColor.whiteColor;
    }
    
    return YES;
}

@end
