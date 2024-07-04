//
//  ALHomeViewController.m
//  DemoApp-ObjC
//
//  Created by Thomas So on 9/4/19.
//  Copyright © 2019 AppLovin Corporation. All rights reserved.
//

#import "ALHomeViewController.h"
#import <AppLovinSDK/AppLovinSDK.h>
#import <SafariServices/SafariServices.h>
#import <HyBid/HyBid.h>
#if __has_include(<HyBid/HyBid-Swift.h>)
    #import <HyBid/HyBid-Swift.h>
#else
    #import "HyBid-Swift.h"
#endif
#if __has_include(<ATOM/ATOM-Swift.h>)
    #import <ATOM/ATOM-Swift.h>
#endif

@interface ALHomeViewController()
@property (nonatomic, weak) IBOutlet UITableViewCell *mediationDebuggerCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *startAtomCell;
@property (nonatomic, weak) IBOutlet UITableViewCell *stopAtomCell;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *muteToggle;
@end

@implementation ALHomeViewController
static NSString *const kSupportLink = @"https://support.applovin.com/hc/en-us";

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addFooterLabel];
    
    self.muteToggle.image = [self muteIconForCurrentSdkMuteSetting];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
    
    if ( [tableView cellForRowAtIndexPath: indexPath] == self.mediationDebuggerCell )
    {
        [[ALSdk shared] showMediationDebugger];
    } else if ( [tableView cellForRowAtIndexPath: indexPath] == self.startAtomCell )
    {
        [self startAtom];
    } else if ( [tableView cellForRowAtIndexPath: indexPath] == self.stopAtomCell )
    {
        [self stopAtom];
    } else if ( indexPath.section == 1 )
    {
        if ( indexPath.row == 0 )
        {
            [self openSupportSite];
        }
    }
}

- (void) startAtom {
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
}

- (void) stopAtom {
    [Atom stopWithCallback:^(BOOL isSuccess) {
        if (isSuccess) {
            [HyBidLogger infoLogFromClass:NSStringFromClass([self class]) fromMethod:NSStringFromSelector(_cmd) withMessage:[NSString stringWithFormat: [[NSString alloc] initWithFormat: @"Stopping ATOM"], NSStringFromSelector(_cmd)]];
            [HyBidLogger infoLogFromClass:NSStringFromClass([self class]) fromMethod:NSStringFromSelector(_cmd) withMessage:[NSString stringWithFormat: [[NSString alloc] initWithFormat: @"ATOM: stopped"], NSStringFromSelector(_cmd)]];
        } else {
            NSString *atomStopResultMessage = [[NSString alloc] initWithFormat:@"Coultdn't stop ATOM"];
            [HyBidLogger errorLogFromClass:NSStringFromClass([self class]) fromMethod:NSStringFromSelector(_cmd) withMessage:[NSString stringWithFormat: atomStopResultMessage, NSStringFromSelector(_cmd)]];
        }
    }];
}
    

#pragma mark - Sound Toggling

- (IBAction)toggleMute:(UIBarButtonItem *)sender
{
    /**
     * Toggling the sdk mute setting will affect whether your video ads begin in a muted state or not.
     */
    ALSdk *sdk = [ALSdk shared];
    sdk.settings.muted = !sdk.settings.muted;
    sender.image = [self muteIconForCurrentSdkMuteSetting];
}

- (UIImage *)muteIconForCurrentSdkMuteSetting
{
    return [ALSdk shared].settings.muted ? [UIImage imageNamed: @"mute"] : [UIImage imageNamed: @"unmute"];
}

#pragma mark - Table View Actions

- (void)openSupportSite
{
    NSOperatingSystemVersion version = [NSProcessInfo processInfo].operatingSystemVersion;
    if ( version.majorVersion > 8 )
    {
        SFSafariViewController *safariController = [[SFSafariViewController alloc] initWithURL: [NSURL URLWithString: kSupportLink]
                                                                       entersReaderIfAvailable: YES];
        [self presentViewController: safariController animated: YES completion: nil];
    }
    else
    {
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString: kSupportLink]];
    }
}

- (void)addFooterLabel
{
    UILabel *footer = [[UILabel alloc] init];
    footer.font = [UIFont systemFontOfSize: 14.0f];
    footer.numberOfLines = 0;
    
    NSString *sdkVersion = [ALSdk version];
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    NSString *text = [NSString stringWithFormat: @"SDK Version: %@\niOS Version: %@\n\nLanguage: Objective-C", sdkVersion, systemVersion];
    
    NSMutableParagraphStyle *style  = [[NSMutableParagraphStyle alloc] init];
    style.alignment =  NSTextAlignmentCenter;
    style.minimumLineHeight = 20.0f;
    footer.attributedText = [[NSAttributedString alloc] initWithString: text attributes: @{NSParagraphStyleAttributeName : style}];
    
    CGRect frame = footer.frame;
    frame.size.height = [footer sizeThatFits: CGSizeMake(CGRectGetWidth(footer.frame), CGFLOAT_MAX)].height + 60.0f;
    footer.frame = frame;
    self.tableView.tableFooterView = footer;
}

@end
