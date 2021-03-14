//
//  DownloadViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 2/3/18.
//  Copyright © 2018 Sam Gardner. All rights reserved.
//

#import "DownloadViewController.h"
#include <sys/sysctl.h>
#import "Objective-Zip/Objective-Zip/Objective-Zip.h"
#import "Objective-Zip/Objective-Zip/OZZipReadStream.h"
#import "HomePageViewController.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "NSTask.h"

@interface DownloadViewController ()

@end

@implementation DownloadViewController
@synthesize deviceBuild;
@synthesize deviceModel;
@synthesize deviceVersion;
NSArray *listVersions;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup background image
    
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    char *modelChar = malloc(size);
    sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
    
    // Load preferences
    _divisePrefs = [NSMutableDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.moski.Divise.plist"];
    _dualbootPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.moski.dualboot.plist"];
    // Set up UI
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self downloadProgressBar] setHidden:TRUE];
        self.activityLabel.text = @"";
        [[self unzipActivityIndicator] setHidden:TRUE];
        
    });
    
    // This creates a font that is 'monospaced', (each character is the same width). This font is later used for the download progress label, since that label is rapidly updated, monospacing the font makes it readable.
    UIFont *systemFont = [UIFont systemFontOfSize:17];
    UIFontDescriptor *monospacedNumberFontDescriptor = [systemFont.fontDescriptor fontDescriptorByAddingAttributes: @{UIFontDescriptorFeatureSettingsAttribute: @[@{UIFontFeatureTypeIdentifierKey: @6, UIFontFeatureSelectorIdentifierKey: @0}]}];
    _monospacedNumberSystemFont = [UIFont fontWithDescriptor:monospacedNumberFontDescriptor size:0];
    
    // Check to see if the user has provided their own IPSW, and if so, offer to extract it instead of downloading one
    if ([[self->_divisePrefs objectForKey:@"found_local_ipsw"] isEqual:@(1)]) {
        
            [self->_startDownloadButton setEnabled:FALSE];
            [self->_startDownloadButton setHidden:TRUE];
            
            [self->_unzipButton setEnabled:TRUE];
            [self->_unzipButton setHidden:FALSE];
        
            [self->_iosPicker setHidden:TRUE];
            
        }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:
                             [NSURL URLWithString:[NSString stringWithFormat:@"https://api.ipsw.me/v4/device/%@?type=ipsw", self.deviceModel]]];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSError *jsonError;
    NSDictionary *parsedThing = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    NSMutableArray *firmwaresToPickFrom = [[NSMutableArray alloc]init];;
    if (parsedThing == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            exit(0);
        });
    } else {
        NSString *version = [[UIDevice currentDevice] systemVersion];
        NSArray *firmwares = parsedThing[@"firmwares"];
        int dictSize = (int)firmwares.count;
        for (int i = 0; i < dictSize; i++) {
            NSString *compare = [NSString stringWithFormat:@"%@", firmwares[i][@"version"]];
            if (([compare containsString:@"9."] || [compare containsString:@"8."] || [compare containsString:@"7."]) || ([compare containsString:@"14."] && ![version containsString:@"14."])) {
                // Do nothing
            } else {
                [firmwaresToPickFrom addObject:(NSString *)[NSString stringWithFormat:@"%@", firmwares[i][@"version"]]];
            }
        }
    }
    
    listVersions = [[NSOrderedSet orderedSetWithArray:firmwaresToPickFrom] array];
    [self->_iosPicker setDelegate:self];
    [self->_iosPicker setDataSource:self];
    
    }

- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView
{
        return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView
      numberOfRowsInComponent:(NSInteger)component
{
        return [listVersions count];
}
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 37)];
    label.text = [NSString stringWithFormat:@"%@", listVersions[row]];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    return label;
}
- (IBAction)backButtonAction:(id)sender {
    // Go back to the home page
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)unzipLocalIPSW:(UIButton *)sender {
    
    // Need to warn user about the app crashing, need to look into why at some point
    
    if (![[self->_divisePrefs objectForKey:@"custom_ipsw_path"] isEqual:@"/var/mobile/Media/Divise/ipsw.ipsw"]) {
        
        // Moving incorrectly named IPSW to ipsw.ipsw :)
        
        [[NSFileManager defaultManager] moveItemAtPath:[self->_divisePrefs objectForKey:@"custom_ipsw_path"] toPath:@"/var/mobile/Media/Divise/ipsw.ipsw" error:nil];
        
        [self->_divisePrefs setObject:@"/var/mobile/Media/Divise/ipsw.ipsw" forKey:@"custom_ipsw_path"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [self->_divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
        
    }
    
    UIAlertController *crashWarn = [UIAlertController alertControllerWithTitle:@"Warning: Divise will crash after extracting the local IPSW" message:@"Relaunch the app, after the crash, to continue the dualboot/tethered downgrade process.\nPress OK to continue" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self->_unzipButton setEnabled:FALSE];
        [self->_unzipButton setBackgroundColor:[UIColor darkGrayColor]];
        [self->_unzipButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        
        [UIApplication sharedApplication].idleTimerDisabled = YES; // Make sure the device doesn't sleep while we are extracting the local IPSW
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(queue, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self unzipActivityIndicator] setHidden:FALSE];
                self.activityLabel.text = @"Unzipping...";
                [self->_startDownloadButton setEnabled:FALSE];
                [self->_startDownloadButton setTitle:@"Working..." forState:UIControlStateNormal];
                [self->_startDownloadButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            });
            self->_needsDecryption = FALSE;
            [self postDownload];
        });
        
    }];
    [crashWarn addAction:useDefualtPathAction];
    [self presentViewController:crashWarn animated:TRUE completion:nil];

    
}
- (IBAction)startDownloadButtonAction:(id)sender {
    // Set Up UI and run code under -(void)startDownload
    [_startDownloadButton setEnabled:FALSE];
    [_startDownloadButton setTitle:@"Working..." forState:UIControlStateNormal];
    [[UIApplication sharedApplication] setIdleTimerDisabled:TRUE];
    [_startDownloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _startDownloadButton.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    [self prepareDownload];
}

-(void)prepareDownload{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.activityLabel.text = @"Preparing download...";
    });
    // If the iOS version is older than iOS 10, the root filesystem DMG is encrypted. Let's make sure we can do that.
    if (kCFCoreFoundationVersionNumber < 1300) {
        _needsDecryption = TRUE;
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/dmg"]) {
            // Before we continue, let's make sure there's a key available for the device we're looking for.
            NSString *rootfsKey = [self getRFSKey];
            if (![rootfsKey isEqualToString:@"Failed."]){
                [self startDownload];
            }
        } else {
            UIAlertController *needsXPwn = [UIAlertController alertControllerWithTitle:@"Divisé requires additional components to be installed" message:@"Please install xpwn from the saurik/Telesphoreo repo." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                exit(0);
            }];
            [needsXPwn addAction:exitAction];
            [self presentViewController:needsXPwn animated:TRUE completion:nil];
        }
    } else {
        _needsDecryption = FALSE;
        [self startDownload];
    }
}

-(void)startDownload {
    
    [self->_iosPicker setHidden:TRUE];
    
    // Removes all files in /var/mobile/Media/Divise to delete any mess from previous uses
    NSString *workingDir = @"/var/mobile/Media/Divise/";
    NSArray *itemsToDelete = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:workingDir error:nil];
    for (NSString *item in itemsToDelete) {
        [[NSFileManager defaultManager] removeItemAtPath:[workingDir stringByAppendingString:item] error:nil];
    }
    // Deletes partial downloads in Divise's sandbox folder
    NSString *tmpDir = NSTemporaryDirectory();
    NSArray *tmpToDelete = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tmpDir error:nil];
    for (NSString *item in tmpToDelete) {
        if ([item containsString:@"CFNetworkDownload"]) {
            [[NSFileManager defaultManager] removeItemAtPath:[tmpDir stringByAppendingString:item] error:nil];
        }
    }
    // Creates /var/mobile/Media/Divise in case dpkg didn't do so, or if the user deleted it
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Media/Divise/" withIntermediateDirectories:TRUE attributes:nil error:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.activityLabel.text = @"Finding IPSW...";
    });
    
    // ipsw.me has an API that provides the apple download link to an ipsw for a specific device/iOS build number. If you want, you can try this, typing https://api.ipsw.me/v2/iPhone10,3/16C104/url/ into a web broswer returns http://updates-http.cdn-apple.com/2018FallFCS/fullrestores/041-28434/A2958D62-02EA-11E9-9292-C8F3416D60E4/iPhone10,3,iPhone10,6_12.1.2_16C104_Restore.ipsw

    // Here I need a popup that asks for the desiered iOS version, then passes that into the ipswAPIURLString as deviceBuild
    // Kindy dodgy as it asks for a iOS version number (e.g 13.2.2) instead of a build number, but ispw.me's api works fine with either so *shrug*

    //_startDownloadButton.backgroundColor = [UIColor clearColor];
        NSLog(@"Downloading iOS version: %@",  listVersions[[self->_iosPicker selectedRowInComponent:0]]);
        if ([[self->_divisePrefs objectForKey:@"dualboot"] isEqual:@(1)]) {
            // No need to save this to disk if we aren't dualbooting :)
            [self->_dualbootPrefs setObject: listVersions[[self->_iosPicker selectedRowInComponent:0]] forKey:@"Version"];
            [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" error:nil];
            [self->_dualbootPrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" atomically:TRUE];
        }
        [self logToFile:@"Making sure user is aware of SEP stuff" atLineNumber:__LINE__];
            
        NSArray *unsupportedDevices = @[@"iPad8,9", @"iPad8,10", @"iPad8,11", @"iPad8,12", @"iPad11,3", @"iPad11,4", @"iPad11,1", @"iPad11,2", @"iPhone11,8", @"iPhone11,2", @"iPhone11,4", @"iPhone11,6", @"iPhone12,1", @"iPhone12,3", @"iPhone12,5", @"iPhone12,8"]; // Note that this is only unsupported 64 bit devices, I'm way to lazy to add 32 bit devices
        
        BOOL *supportedDeviceCheck = [unsupportedDevices containsObject:(self->deviceModel)];
        if (supportedDeviceCheck){
            NSLog(@"Device is not supported by Checkm8 currently, erroring");
            NSString *devicemodelerror = [NSString stringWithFormat:@"Your %@ is not compatible right now sorry", self->deviceModel];
            UIAlertController *alertController2 = [UIAlertController alertControllerWithTitle:devicemodelerror message:@"Press OK to return to the main screen" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
            [alertController2 addAction:confirmAction];
            [self presentViewController:alertController2 animated:YES completion:nil];
        } else {
            NSLog(@"Device is supported by Checkm8!");
            if ([listVersions[[self->_iosPicker selectedRowInComponent:0]] containsString:@"14."]) {
                NSURL *targetURL = [NSURL URLWithString:@"https://ramiel.app/check"];
                NSURLRequest *request = [NSURLRequest requestWithURL:targetURL];
                NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                NSString *dataString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                if ([dataString containsString:@"0"]) {
                    // Inform user that you won't be able to boot 14.x versions just yet, let them know about Ramiel.app :)
                    UIAlertController *ios14checkfailed = [UIAlertController alertControllerWithTitle:@"Warning: Ramiel has not been released yet, meaning there will be no way for you to boot the second iOS 14 OS." message:@"Feel free to continue with the dualboot, it will complete fine, you just won't be able to boot into it for a little bit. Please follow @ramielapp on twitter for updates." preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *continueButton = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        self->deviceBuild =  listVersions[[self->_iosPicker selectedRowInComponent:0]];
                        NSString *ipswAPIURLString = [NSString stringWithFormat:@"https://api.ipsw.me/v2/%@/%@/url/", self->deviceModel, self->deviceBuild];
                               // to use the API mentioned above, I create a string that incorporates the iOS buildnumber and device model, then it is converted into an NSURL...
                        NSURL *ipswAPIURL = [NSURL URLWithString:ipswAPIURLString];
                               // and after a little UI config...
                        NSLog(@"Downloading IPSW from : %@", ipswAPIURL);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[self downloadProgressBar] setHidden:FALSE];
                        });
                               
                               // the request is made, and the string received from ipsw.me is passed to an NSData object called 'data' in the completion handler. Note that the request is created below, but it is not actually run until [getDownloadLinkTask resume];
                            NSURLSessionDataTask *getDownloadLinkTask = [[NSURLSession sharedSession] dataTaskWithURL:ipswAPIURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                   // so now we have a direct link to where apple is hosting the IPSW for the user's device/firmware, but it's in a rather useless NSData object, so let's convet that to an NSString
                            NSString * downloadLinkString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                   // update the UI, but unless the user has a really really slow device, they probably won't ever see this:
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[self activityLabel] setText:[NSString stringWithFormat:@"Found IPSW at %@", downloadLinkString]];
                            });
                                   // now we reference _downloadLink, created in DownloadViewController.h, and set it equal to the NSURL version of the string we received from ipsw.me
                            self->_downloadLink = [NSURL URLWithString:downloadLinkString];
                            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
                                   // set the timeout for the download request to 200 minutes (12000 seconds), that should be enough time, eh?
                            sessionConfig.timeoutIntervalForRequest = 12000.0;
                            sessionConfig.timeoutIntervalForResource = 12000.0;
                                   // define a download task with the custom timeout and download link
                            NSURLSessionDownloadTask *task = [[NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]] downloadTaskWithURL:self->_downloadLink];
                                   // start the ipsw download task. NSURLSessionDownloadTasks call
                                   //
                                   // "-(void) URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite"
                                   //
                                   // frequently throughout the download process, which is where my code for updating the UI is. They also call
                                   //
                                   // - (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
                                   //
                                   // when finished, which is where I have my code for what to do once the download is finished
                            NSLog(@"DIVISETESTING: STARTED!");
                            [task resume];
                        }];
                        [getDownloadLinkTask resume];
                    }];
                    UIAlertAction *backButton = [UIAlertAction actionWithTitle:@"Back" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        
                        [self dismissViewControllerAnimated:YES completion:nil];
                        
                    }];
                    UIAlertAction *openSiteButton = [UIAlertAction actionWithTitle:@"Visit Ramiel.app" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        NSDictionary *URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://ramiel.app"] options:URLOptions completionHandler:nil];
                        sleep(3);
                        [self dismissViewControllerAnimated:YES completion:nil];
                        
                    }];
                    [ios14checkfailed addAction:continueButton];
                    [ios14checkfailed addAction:openSiteButton];
                    [ios14checkfailed addAction:backButton];
                    
                    [self presentViewController:ios14checkfailed animated:TRUE completion:nil];
                }
            } else {
                self->deviceBuild =  listVersions[[self->_iosPicker selectedRowInComponent:0]];
                NSString *ipswAPIURLString = [NSString stringWithFormat:@"https://api.ipsw.me/v2/%@/%@/url/", self->deviceModel, self->deviceBuild];
                       // to use the API mentioned above, I create a string that incorporates the iOS buildnumber and device model, then it is converted into an NSURL...
                NSURL *ipswAPIURL = [NSURL URLWithString:ipswAPIURLString];
                       // and after a little UI config...
                NSLog(@"Downloading IPSW from : %@", ipswAPIURL);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[self downloadProgressBar] setHidden:FALSE];
                });
                       
                       // the request is made, and the string received from ipsw.me is passed to an NSData object called 'data' in the completion handler. Note that the request is created below, but it is not actually run until [getDownloadLinkTask resume];
                    NSURLSessionDataTask *getDownloadLinkTask = [[NSURLSession sharedSession] dataTaskWithURL:ipswAPIURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                           // so now we have a direct link to where apple is hosting the IPSW for the user's device/firmware, but it's in a rather useless NSData object, so let's convet that to an NSString
                    NSString * downloadLinkString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                           // update the UI, but unless the user has a really really slow device, they probably won't ever see this:
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[self activityLabel] setText:[NSString stringWithFormat:@"Found IPSW at %@", downloadLinkString]];
                    });
                           // now we reference _downloadLink, created in DownloadViewController.h, and set it equal to the NSURL version of the string we received from ipsw.me
                    self->_downloadLink = [NSURL URLWithString:downloadLinkString];
                    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
                           // set the timeout for the download request to 200 minutes (12000 seconds), that should be enough time, eh?
                    sessionConfig.timeoutIntervalForRequest = 12000.0;
                    sessionConfig.timeoutIntervalForResource = 12000.0;
                           // define a download task with the custom timeout and download link
                    NSURLSessionDownloadTask *task = [[NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]] downloadTaskWithURL:self->_downloadLink];
                           // start the ipsw download task. NSURLSessionDownloadTasks call
                           //
                           // "-(void) URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite"
                           //
                           // frequently throughout the download process, which is where my code for updating the UI is. They also call
                           //
                           // - (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
                           //
                           // when finished, which is where I have my code for what to do once the download is finished
                    NSLog(@"DIVISETESTING: STARTED!");
                    [task resume];
                }];
                [getDownloadLinkTask resume];
            }
        }
}

-(NSString *)getRFSKey{
    // Let's fetch the rootfilesystem decryption key from theiphonewiki. TheiPhoneWiki's URLs are annoyingly machine unfriendly, formatted as https://www.theiphonewiki.com/wiki/<iOS_Codename>_<Buildnumber>_(<Machine ID>)
    // The hard part here is the version codename. Muirey03 suggested to me that it might be possible to obtain the codename from MobileGestalt, but every time I tried to call it, Succession would crash. So, hardcoding! Hooray for lack of future-proofing! (or in this case, past-proofing? idk.)
    NSDictionary *codenameForVersion = @{
        @"7.0" : @"Innsbruck",
        @"7.0.1" : @"Innsbruck",
        @"7.0.2" : @"Innsbruck",
        @"7.0.3" : @"InnsbruckTaos",
        @"7.0.4" : @"InnsbruckTaos",
        @"7.0.5" : @"InnsbruckTaos",
        @"7.0.6" : @"InnsbruckTaos",
        @"7.1" : @"Sochi",
        @"7.1.1" : @"SUSochi",
        @"7.1.2" : @"Sochi",
        @"8.0" : @"Okemo",
        @"8.0.1" : @"Okemo",
        @"8.0.2" : @"Okemo",
        @"8.1" : @"OkemoTaos",
        @"8.1.1" : @"SUOkemoTaos",
        @"8.1.2" : @"SUOkemoTaos",
        @"8.1.3" : @"SUOkemoTaosTwo",
        @"8.2" : @"OkemoZurs",
        @"8.3" : @"Stowe",
        @"8.4" : @"Copper",
        @"8.4.1" : @"Donner",
        @"9.0" : @"Monarch",
        @"9.0.1" : @"Monarch",
        @"9.0.2" : @"Monarch",
        @"9.1" : @"Boulder",
        @"9.2" : @"Castlerock",
        @"9.2.1" : @"Dillon",
        @"9.3" : @"Eagle",
        @"9.3.1" : @"Eagle",
        @"9.3.2" : @"Frisco",
        @"9.3.3" : @"Genoa",
        @"9.3.4" : @"Genoa",
        @"9.3.5" : @"Genoa",
        @"9.3.6" : @"Genoa"
    };
    // Hopefully that's accurate, if it isnt... welp.
    // SO! back to what we were doing, let's figure out what codename goes with this iOS version.
    // First let's check to make sure there isn't some edge case where I don't have the codename for the user's iOS version, getting the value for a nonexistent key results in a crash.
    if ([[codenameForVersion allKeys] containsObject:deviceVersion]) {
        // yay, I have the codename for the user's iOS version. Let's make it useful.
        NSString *codename = [codenameForVersion objectForKey:deviceVersion];
        // Now, the easiest way I could think of to obtain the decryption keys was to download the HTML page of theiphonewiki, convert it to a string, and parse, like so:
        NSURL *keyPageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://theiphonewiki.com/wiki/%@_%@_(%@)", codename, deviceBuild, deviceModel]];
        // Get the data of the page at keyPageURL
        NSData *keyPageData = [NSData dataWithContentsOfURL:keyPageURL];
        // Convert the data to a string
        NSString *keyPageString = [NSString stringWithUTF8String:[keyPageData bytes]];
        // Now let's check to see if theiphonewiki actually has the key we need
        if ([keyPageString containsString:@"<code id=\"keypage-rootfs-key\">"]) {
            // yay! it does. Lets parse now.
            // separate the into an array to isolate the rfs key
            NSArray *keyPageStringSeparated = [keyPageString componentsSeparatedByString:@"<code id=\"keypage-rootfs-key\">"];
            // get all the text after "keypage-rootfs-key>"
            NSString *theFunPartOfKeyPageString = [keyPageStringSeparated objectAtIndex:1];
            // trim it down further
            NSArray *theFunPartSeparated = [theFunPartOfKeyPageString componentsSeparatedByString:@"</code>"];
            [self logToFile:[theFunPartSeparated firstObject] atLineNumber:__LINE__];
            return [theFunPartSeparated firstObject];
        } else {
            // oof. key isnt available. :rip:
            [self logToFile:[NSString stringWithFormat:@"Key for %@ %@ not available.", deviceModel, deviceBuild] atLineNumber:__LINE__];
            UIAlertController *deviceNotSupported = [UIAlertController alertControllerWithTitle:@"Device not supported." message:@"The filesystem for your iOS version is encrypted, and a decryption key is not publicly available. If you are a researcher with a private key, please decrypt the DMG yourself using xpwn and place it in /var/mobile/Media/Divise/rfs.dmg (oh, and could you also pretty please post it to theiphonewiki)." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                exit(0);
            }];
            [deviceNotSupported addAction:exitAction];
            [self presentViewController:deviceNotSupported animated:TRUE completion:nil];
            return @"Failed.";
        }
        
    } else {
        // If the iOS version isn't in the dict above, then :rip:
        [self errorAlert:[NSString stringWithFormat:@"Couldn't get codename for your iOS %@\nPlease email me samgisaninja@unc0ver.dev or dm me on reddit u/Samg_is_a_Ninja", deviceBuild]];
        return @"Failed.";
    }
}

- (void) URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    // So, iOS provides A LOT of information to us during the download, the oly thing I'm really interested in is the totalBytesWritten and the totalBytesExpectedToWrite. Here I convert them into float values so that I can do math with them easier. I also convert them to MB, as bytes aren't really user-friendly
    float totalSize = (totalBytesExpectedToWrite/1024)/1024.f;
    float writtenSize = (totalBytesWritten/1024)/1024.f;
    // The if statments were done to fix a bug I was having where the "unzipping" wouldn't appear, even after the download was complete, so I say "ok, if the download is 'close enough', then show the user that it's done." This is dirty. oops.
    if (writtenSize < (totalSize - 0.1)) {
        // I use a mutable attributed string here. It's attributed so that I can change the font to that monospaced font I created earlier in viewDidLoad, and its mutable so that I can apply that font after the string's creation.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableAttributedString *activityLabelText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Downloading IPSW:\n%.2f of %.2f MB", writtenSize, totalSize]];
            // apply the font
            [activityLabelText addAttribute:NSFontAttributeName value:self->_monospacedNumberSystemFont range:NSMakeRange(0, activityLabelText.string.length)];
            // set the label equal to my attributed string
            [self->_activityLabel setAttributedText:activityLabelText];
        });
        // set the progressbar equal to the ratio of writtenSize to total file size.
        dispatch_async(dispatch_get_main_queue(), ^{
            self.downloadProgressBar.progress = (writtenSize/totalSize);
            [[self downloadProgressBar] setHidden:FALSE];
            [[self unzipActivityIndicator] setHidden:TRUE];
        });
    }
    if (writtenSize > (totalSize - 0.1)) {
        // if the download is "close enough" to being done, show the unzip UI.
        dispatch_async(dispatch_get_main_queue(), ^{
            self.activityLabel.text = @"Unzipping...";
            [[self downloadProgressBar] setHidden:TRUE];
            [[self unzipActivityIndicator] setHidden:FALSE];
        });
    }
}

- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    // so this method gets executed when "a download finished, and it's located at the NSString returned by [location path]". This presents the problem of, "well, was it a beta version, and it just downloaded the beta information plist from my github, or did it just finish downloading an IPSW?". The filename and extension are not preserved, so the best way I could think of to determine which was to check if the file was big (IPSW) or small (plist).
    NSString *downloadTaskURL = [[[downloadTask currentRequest] URL] absoluteString];
    NSLog(@"URL IS: %@", downloadTaskURL);
    if ([downloadTaskURL containsString:@".plist"]) {
        // Create a dictionary with the contents of the downloaded plist
        if ([downloadTaskURL containsString:@"sep"]) {
            NSDictionary *sepLinks = [NSDictionary dictionaryWithContentsOfFile:[location path]];
            // Check whether given iOS version has compatible SEP or not
            NSLog(@"ios: %@", deviceBuild);

            if ([deviceBuild length] >= 3)
                deviceBuild = [deviceBuild substringToIndex:3];
            else{
                
                NSLog(@"Given iOS version is malformed");
                UIAlertController *alertController2 = [UIAlertController alertControllerWithTitle:@"You entered an invalid iOS version" message:@"Press OK to return to the main screen and try again" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }];
                [alertController2 addAction:confirmAction];
                [self presentViewController:alertController2 animated:YES completion:nil];
                
            }
            
            NSLog(@"Major iOS version is: %@", deviceBuild);
            if ([sepLinks objectForKey:deviceModel]) {
                // Get bool for whether or not the device is supported, with true (1) being supported and false (0) being unsupported
                BOOL pog =[[[sepLinks objectForKey:deviceModel] objectForKey:deviceBuild] boolValue];
                if (pog) {
                // Get bool for deseired iOS version, with true (1) being supported and false (0) being unsupported
                    NSString *sepLinkFinal = [NSString stringWithFormat:@"%@", [[sepLinks objectForKey:deviceModel] objectForKey:deviceBuild]];
                    NSLog(@"Is SEP supported equals: %@", sepLinkFinal);
                    return;
                }else {
                    NSLog(@"Unlucky, unsupported device...");
                    
                    UIAlertController *alertController2 = [UIAlertController alertControllerWithTitle:@"You entered either an unsupported iOS version or mistyped something" message:@"Press OK to return to the main screen and try again\nIgnore if the IPSW starts to download, I'm too stupid to fix that" preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self.navigationController popToRootViewControllerAnimated:YES];
                    }];
                    [alertController2 addAction:confirmAction];
                    
                    [self presentViewController:alertController2 animated:YES completion:nil];
                    
                }
            }else{
                NSLog(@"Unsupported device");
                UIAlertController *alertController2 = [UIAlertController alertControllerWithTitle:@"Unsupported device" message:@"Press OK to return to the main screen." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }];
                [alertController2 addAction:confirmAction];
                [self presentViewController:alertController2 animated:YES completion:nil];
            }
        }
    } else {
        unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:[location path] error:nil] fileSize];
        if (fileSize < 96000000) {
            if ([[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:[location path]] encoding:NSUTF8StringEncoding] containsString:@"Denied"]) {
                UIAlertController *alertController2 = [UIAlertController alertControllerWithTitle:@"Download of IPSW is being blocked by Apple" message:@"Press OK to return to the main screen and try again or pick another iOS version" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }];
                [alertController2 addAction:confirmAction];
                
                [self presentViewController:alertController2 animated:YES completion:nil];
                return;
            }
        }
        // so, the IPSW download is now complete, but it's in... well we don't really know. but iOS knows! to be specific, it exists at [location path]. [location path] is not nearly as easy to work with as /var/mobile/Media/Succession/ipsw.ipsw, so let's move it there.
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self downloadProgressBar] setHidden:TRUE];
            [[self activityLabel] setText:@"Retrieving Download..."];
            [[self unzipActivityIndicator] setHidden:FALSE];
        });
        NSError * error;
        // NSFileManager lets us do pretty much anything with files, and also, if there's an error, error information will be stored in the NSError object I created above.
        [[NSFileManager defaultManager] moveItemAtPath:[location path] toPath:[_divisePrefs objectForKey:@"custom_ipsw_path"] error:&error];
        // I've never come across an error with this, but it's better to have error handling than to... not. Assuming there's no error, continue on to -(void)postDownload
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self activityLabel] setText:[NSString stringWithFormat:@"Error moving downloaded ipsw: %@", [error localizedDescription]]];
            });
        } else {
            [self postDownload];
        }
    }
}

- (void) postDownload {
    [self logToFile:@"Started PostDownload" atLineNumber:__LINE__];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self unzipActivityIndicator] setHidden:FALSE];
        [[self activityLabel] setText:@"Verifying IPSW..."];
        
    });
    //[[NSFileManager defaultManager] moveItemAtPath:[_divisePrefs objectForKey:@"custom_ipsw_path"] toPath:@"/var/mobile/Media/Divise/ipsw.ipsw" error:nil];
    OZZipFile *zip= [[OZZipFile alloc] initWithFileName:@"/var/mobile/Media/Divise/ipsw.ipsw" mode:OZZipFileModeUnzip];
    NSMutableData *buffer = [[NSMutableData alloc] initWithLength:1024];
    NSArray *zipContentList= [zip listFileInZipInfos];
    for (OZFileInZipInfo *fileInZipInfo in zipContentList) {
        if ([[fileInZipInfo name] isEqualToString:@"BuildManifest.plist"]) {
            // Create file
            [[self activityLabel] setText:@"Extracting RootFS...\nThis may take a while!"];
            NSString *filePath = [NSString stringWithFormat:@"/var/mobile/Media/Divise/%@", fileInZipInfo.name];
            [[NSFileManager defaultManager] createFileAtPath:filePath contents:[NSData data] attributes:nil];
            NSFileHandle *file= [NSFileHandle fileHandleForWritingAtPath:filePath];
            [zip locateFileInZip:fileInZipInfo.name];
            OZZipReadStream *readStream= [zip readCurrentFileInZip];
            [buffer setLength:1024];
            int totalBytesRead= 0;
            do {
                int bytesRead= [readStream readDataWithBuffer:buffer];
                if (bytesRead > 0) {
                    [buffer setLength:bytesRead];
                    [file writeData:buffer];
                    [self logToFile:[NSString stringWithFormat:@"Writing %@, %d of %llu bytes...", [fileInZipInfo name], totalBytesRead, [fileInZipInfo length]] atLineNumber:__LINE__];
                    totalBytesRead += bytesRead;
                    
                } else
                    break;
            } while (YES);
            [file closeFile];
            [readStream finishedReading];
        }
    }
    [zip close];
    NSDictionary *IPSWBuildManifest = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Media/Divise/BuildManifest.plist"];
    if ([[IPSWBuildManifest objectForKey:@"ProductBuildVersion"] isEqualToString:deviceBuild]) {
        [self logToFile:[NSString stringWithFormat:@"Build number in BuildManifest %@ matches deviceBuild %@", [IPSWBuildManifest objectForKey:@"ProductBuildVersion"], deviceBuild] atLineNumber:__LINE__];
        if ([[IPSWBuildManifest objectForKey:@"SupportedProductTypes"] containsObject:deviceModel]) {
            [self logToFile:[NSString stringWithFormat:@"Product Type in BuildManifest %@ matches deviceBuild %@", [IPSWBuildManifest objectForKey:@"SupportedProductTypes"], deviceModel] atLineNumber:__LINE__];
            [self logToFile:@"Successfully verified IPSW" atLineNumber:__LINE__];
            [self extractDMG];
        } else {
            [self logToFile:@"We out here making it easier to bootloop devices (thats just a meme but its kinda true sorry)" atLineNumber:__LINE__];
            [self extractDMG];
        }
    } else {
        [self logToFile:@"We out here making bootlooping easier (just a meme but also true sorry)" atLineNumber:__LINE__];
        [self extractDMG];
    }
}

-(void) extractDMG {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self unzipActivityIndicator] setHidden:FALSE];
        [[self activityLabel] setText:@"Identifying rfs in compressed IPSW..."];
    });
    OZZipFile *unzipIPSW;
    if (sizeof(void *) == 4) {
        unzipIPSW = [[OZZipFile alloc] initWithFileName:@"/var/mobile/Media/Divise/ipsw.ipsw" mode:OZZipFileModeUnzip legacy32BitMode:TRUE];
    } else {
        unzipIPSW = [[OZZipFile alloc] initWithFileName:@"/var/mobile/Media/Divise/ipsw.ipsw" mode:OZZipFileModeUnzip legacy32BitMode:TRUE];
    }
    [unzipIPSW locateFileInZip:@"BuildManifest.plist"];
    NSMutableDictionary *namesAndSizes = [[NSMutableDictionary alloc] init];
    NSArray *infos = [unzipIPSW listFileInZipInfos];
    NSMutableArray *fileSizes = [[NSMutableArray alloc] init];
    for (OZFileInZipInfo *info in infos) {
        if ([info.name hasSuffix:@".dmg"]) {
            [self logToFile:[NSString stringWithFormat:@"%@ is a DMG of size %llu!", [info name], [info length]] atLineNumber:__LINE__];
            [namesAndSizes setObject:[info name] forKey:[NSNumber numberWithUnsignedLongLong:[info length]]];
            [fileSizes addObject:[NSNumber numberWithUnsignedLongLong:[info length]]];
        }
    }
    NSNumber *largestFileSize = [fileSizes valueForKeyPath:@"@max.self"];
    [self logToFile:[NSString stringWithFormat:@"Largest file size is %@", largestFileSize] atLineNumber:__LINE__];
    NSString *largestFileName = [namesAndSizes objectForKey:largestFileSize];
    [unzipIPSW locateFileInZip:largestFileName];
    [self logToFile:[NSString stringWithFormat:@"Name of largest file is %@", largestFileName] atLineNumber:__LINE__];
    
    unsigned long long dmgLengthULL = (unsigned long long)[[namesAndSizes allKeysForObject:largestFileName] firstObject];
    float dmgLength = (float)dmgLengthULL;
    OZZipReadStream *read = [unzipIPSW readCurrentFileInZip];
    NSMutableData *data = [[NSMutableData alloc] initWithLength:32768];
    [[NSFileManager defaultManager] createFileAtPath:@"/var/mobile/Media/Divise/rfs.dmg" contents:nil attributes:nil];
    float unzipProgress = 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self unzipActivityIndicator] setHidden:TRUE];
        [[self downloadProgressBar] setHidden:FALSE];
        [[self activityLabel] setText:@"Extracting RootFS...\nThis may take a while!"];
    });
    do {
        
        // Reset buffer length
        [data setLength:32768];
        
        // Read bytes and check for end of file
        int bytesRead= (int)[read readDataWithBuffer:data];
        if (bytesRead <= 0)
            break;
        [data setLength:bytesRead];
        unzipProgress = unzipProgress + bytesRead;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self downloadProgressBar] setProgress:(unzipProgress/dmgLength)];
        });
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:@"/var/mobile/Media/Divise/rfs.dmg"];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
        [fileHandle closeFile];
        NSLog(@"Extracting DMG, %d bytes extracted, %f of %f total", bytesRead, unzipProgress, dmgLength);
        [self logToFile:[NSString stringWithFormat:@"Extracting DMG, %d bytes extracted, %f of %f total", bytesRead, unzipProgress, dmgLength] atLineNumber:__LINE__];
    } while (YES);
    [read finishedReading];
    [unzipIPSW close];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self unzipActivityIndicator] setHidden:FALSE];
        [[self downloadProgressBar] setHidden:TRUE];
        [[self activityLabel] setText:[NSString stringWithFormat:@"Cleaning up..."]];
    });
    // Delete everything else
    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Media/Divise/ipsw.ipsw" error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Media/Divise/BuildManifest.plist" error:nil];
    // Need to look at why it crashes after removing the other files....
    [self logToFile:@"extraction complete" atLineNumber:__LINE__];
    // If the DMG needs decryption, decrypt it now.
    // Let the user know that download is now complete
    
    NSString *message = @"The rootfilesystem was successfully extracted to /var/mobile/Media/Succession/rfs.dmg\nIf the app hangs here just close it in app switcher and reopen";
    UIAlertController *downloadComplete = [UIAlertController alertControllerWithTitle:@"Download/Extraction Complete" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *backToHomePage = [UIAlertAction actionWithTitle:@"Back" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [downloadComplete addAction:backToHomePage];
    [self presentViewController:downloadComplete animated:TRUE completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)errorAlert:(NSString *)message{
    [self logToFile:[NSString stringWithFormat:@"ERROR! %@", message] atLineNumber:__LINE__];
    UIAlertController *errorAlertController = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        exit(0);
    }];
    [errorAlertController addAction:exitAction];
    [self presentViewController:errorAlertController animated:TRUE completion:nil];
}

- (void)logToFile:(NSString *)message atLineNumber:(int)lineNum {
    if ([[self->_divisePrefs objectForKey:@"log-file"] isEqual:@(1)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/mobile/Divise.log"]) {
                [[NSFileManager defaultManager] createFileAtPath:@"/private/var/mobile/Divise.log" contents:nil attributes:nil];
            }
            NSString *stringToLog = [NSString stringWithFormat:@"[DIVISELOG %@: %@] Line %@: %@\n", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [NSDate date], [NSString stringWithFormat:@"%d", lineNum], message];
            NSLog(@"%@", stringToLog);
            NSFileHandle *logFileHandle = [NSFileHandle fileHandleForWritingAtPath:@"/private/var/mobile/Divise.log"];
            [logFileHandle seekToEndOfFile];
            [logFileHandle writeData:[stringToLog dataUsingEncoding:NSUTF8StringEncoding]];
            [logFileHandle closeFile];
        });
    }
}

@end
