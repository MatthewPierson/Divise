//
//  ViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 9/27/17.
//  Copyright © 2017 Sam Gardner. All rights reserved.
//

#import "HomePageViewController.h"
#import "DownloadViewController.h"
#include <sys/sysctl.h>
#include <CoreFoundation/CoreFoundation.h>
#include <spawn.h>
#include "NSTask.h"
#include <sys/stat.h>

@interface HomePageViewController ()

@end

@implementation HomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[[self navigationController] navigationBar] setHidden:TRUE];
    
    // Create a size_t and set it to the size used to allocate modelChar
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    //Gets iOS device model (ex iPhone9,1 == iPhone 7 GSM) and changes label.
    char *modelChar = malloc(size);
    sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
    _deviceModel = [NSString stringWithUTF8String:modelChar];
    free(modelChar);
    self.deviceModelLabel.text = [NSString stringWithFormat:@"%@", _deviceModel];
    if ([_deviceModel containsString:@"iPad"]) {
        
        UIImageView * bgImage =[[UIImageView alloc]initWithFrame:self.view.frame];

        bgImage.image = [UIImage imageNamed:@"background-iPad.jpg"]; [self.view addSubview:bgImage];
        
        bgImage.contentMode = UIViewContentModeScaleAspectFill;
        
        bgImage.alpha = 0.75;

        [self.view sendSubviewToBack:bgImage];
        
    } else {
        
        UIImageView * bgImage =[[UIImageView alloc]initWithFrame:self.view.frame];

        bgImage.image = [UIImage imageNamed:@"background-iPhone.jpg"]; [self.view addSubview:bgImage];
        
        bgImage.contentMode = UIViewContentModeScaleAspectFill;
        
        bgImage.alpha = 0.75;

        [self.view sendSubviewToBack:bgImage];
        
    }
    _installedCurrent.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    _maininstallLabel.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    _dataLabel.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    _maininstallLabel.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    _dualbootedVersion.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    _dualbootedDiskID.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    _databLabel.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    _mainInstalledVersion.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    _modelLabel.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    _mainbuildLabel.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    _mainversionLabel.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    _deviceModelLabel.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    _iOSVersionLabel.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    _iOSBuildLabel.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    _titleLabel.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.75f];
    
    //Gets iOS version and changes label.
    _deviceVersion = [[UIDevice currentDevice] systemVersion];
    self.iOSVersionLabel.text = [NSString stringWithFormat:@"%@", _deviceVersion];
    self.mainInstalledVersion.text = [NSString stringWithFormat:@"%@", _deviceVersion];
    _betaLabel.text = [NSString stringWithFormat:@"Beta Version %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    
    if ([_deviceVersion containsString:@"10."]){
        
        UIAlertController *ios10Warning = [UIAlertController alertControllerWithTitle:@"Warning: iOS 10 Support is currently broken!" message:@"Be warned that the dualboot/tethered downgrade will likely not work at the moment!" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [ios10Warning addAction:useDefualtPathAction];
        [self presentViewController:ios10Warning animated:TRUE completion:nil];
        
    }
    
    // Set size to the size used to allocate buildChar
    sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    
    //Gets iOS device build number (ex 10.1.1 == 14B100 or 14B150) and changes label.
    //Thanks, Apple, for releasing two versions of 10.1.1, you really like making things hard on us.
    char *buildChar = malloc(size);
    sysctlbyname("kern.osversion", buildChar, &size, NULL, 0);
    _deviceBuild = [NSString stringWithUTF8String:buildChar];
    free(buildChar);
    self.iOSBuildLabel.text = [NSString stringWithFormat:@"%@", _deviceBuild];
    // Don't run on the 6s on 9.X due to activation issue
    if ([_deviceModel isEqualToString:@"iPhone8,1"] || [_deviceModel isEqualToString:@"iPhone8,2"]) {
        if ([_deviceVersion hasPrefix:@"9."]) {
            UIAlertController *activationError = [UIAlertController alertControllerWithTitle:@"Divisé is disabled" message:@"Apple does not allow the iPhone 6s or 6s Plus to activate on iOS 9.X. Running Divisé would force you to restore to the latest version of iOS, and is therefore disabled. Sorry about that :/" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                exit(0);
            }];
            [activationError addAction:exitAction];
            [self presentViewController:activationError animated:TRUE completion:nil];
        }
    }
    NSMutableDictionary *dualbootPrefs = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist"]];
    if (![dualbootPrefs objectForKey:@"dualbooted"]) {
        [dualbootPrefs setObject:@(0) forKey:@"dualbooted"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" error:nil];
        [dualbootPrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" atomically:TRUE];
    }
    if (![dualbootPrefs objectForKey:@"SystemB"]) {
        [dualbootPrefs setObject:@"Aquila" forKey:@"SystemB"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" error:nil];
        [dualbootPrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" atomically:TRUE];
    }
    if (![dualbootPrefs objectForKey:@"DataB"]) {
        [dualbootPrefs setObject:@"Rosinha" forKey:@"DataB"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" error:nil];
        [dualbootPrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" atomically:TRUE];
    }
    if (![dualbootPrefs objectForKey:@"Version"]) {
        [dualbootPrefs setObject:@"1.1.1" forKey:@"Version"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" error:nil];
        [dualbootPrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" atomically:TRUE];
    }
    NSMutableDictionary *divisePrefs = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist"]];
    _divisePrefs = divisePrefs;
    if (![divisePrefs objectForKey:@"firstLaunch"]) {
        [divisePrefs setObject:@(1) forKey:@"firstLaunch"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
    }
    if (![divisePrefs objectForKey:@"log-file"]) {
        [divisePrefs setObject:@(0) forKey:@"log-file"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
    }
    if (![divisePrefs objectForKey:@"dualboot"]) {
        [divisePrefs setObject:@(0) forKey:@"dualboot"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
    }
    if (![divisePrefs objectForKey:@"custom_rsync_path"]) {
        [divisePrefs setObject:@"/usr/bin/rsync" forKey:@"custom_rsync_path"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
    }
    if (![divisePrefs objectForKey:@"custom_ipsw_path"]) {
        [divisePrefs setObject:@"/var/mobile/Media/Divise/ipsw.ipsw" forKey:@"custom_ipsw_path"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
    }
    if (![divisePrefs objectForKey:@"found_local_ipsw"]) {
        [divisePrefs setObject:@(0) forKey:@"found_local_ipsw"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
    }
    
    if ([[dualbootPrefs objectForKey:@"dualbooted"] isEqual:@(1)]) {
        // No need to save this to disk if we aren't dualbooting :)
        NSString *dualbootedVersion = [dualbootPrefs objectForKey:@"Version"];
        NSString *dualbootedSystemB = [dualbootPrefs objectForKey:@"SystemB"];
        NSString *dualbootedDataB = [dualbootPrefs objectForKey:@"DataB"];
        // Make sure that we set the labels so the user knows what is installed where
        
        self.dualbootedVersion.text = dualbootedVersion;
        
        self.dualbootedDiskID.text = [NSString stringWithFormat:@"%@/%@", dualbootedSystemB, dualbootedDataB];
        [_dualbootedDiskID setHidden:false];
        [_dualbootedVersion setHidden:false];
        [_databLabel setHidden:false];
        
        [_prepareToRestoreButton setHidden:TRUE];
        [_prepareToRestoreButton setEnabled:FALSE];
        [_dualbootSettings setHidden:false];
        [_dualbootSettings setEnabled:true];
       
    } else {
        // Make sure labels are hidden if user is not dualbooting/dualbooted
        [_dualbootedDiskID setHidden:true];
        [_dualbootedVersion setHidden:true];
        [_databLabel setHidden:true];
        [_dualbootSettings setHidden:true];
        [_dualbootSettings setEnabled:false];
    }
    if ([[divisePrefs objectForKey:@"firstLaunch"]  isEqual: @(1)]) {
        
        [divisePrefs setObject:@(0) forKey:@"firstLaunch"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
        
        // Show UIAlert with the choice to dualboot/tethered downgrade
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Welcome to Divisé!" message:@"What would you like to do?\nThis can be changed in the Settings page at any time." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *dualbootButton = [UIAlertAction actionWithTitle:@"Dualboot" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [divisePrefs setObject:@(1) forKey:@"dualboot"];
            [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
            [divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
            if ([[dualbootPrefs objectForKey:@"dualbooted"] isEqual:@(0)]) {
                
                // This code is real hacky, there is probably a much cleaner way to check for extra entries in /dev/disk0s1s* and write them to a NSMutableArray
                
                bool *checkDelete = FALSE;
                self.diskDeletion = [[NSMutableArray alloc] init];
                
                NSString *path = @"/etc/fstab";
                NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
                
                if ([self->_deviceVersion containsString:@"13."]) {
                    for (int i = 6; i < 100; i++) {
                        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/dev/disk0s1s%d", i]]) {
                            
                            if (![content containsString:[NSString stringWithFormat:@"/dev/disk0s1s%d", i]]) {
                                
                                [self->_diskDeletion addObject:[NSString stringWithFormat:@"/dev/disk0s1s%d", i]];
                                checkDelete = TRUE;
                                
                            } else {
                                checkDelete = FALSE;
                            }
                        }
                    }
                } else {
                    for (int i = 4; i < 100; i++) {
                                   
                       if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/dev/disk0s1s%d", i]]) {
                           
                           if (![content containsString:[NSString stringWithFormat:@"/dev/disk0s1s%d", i]]) {
                               
                               [self->_diskDeletion addObject:[NSString stringWithFormat:@"/dev/disk0s1s%d", i]];
                               checkDelete = TRUE;
                               
                           } else {
                               checkDelete = FALSE;
                           }
                       }
                    }
                }
                [self logToFile:[NSString stringWithFormat:@"About to delete:\n\n%@", self->_diskDeletion] atLineNumber:__LINE__];
                if (checkDelete) {
                    
                    // We can't show a UIAlert within a loop so have to use the checkDelete bool to see whether we should show the UIAlert or not
                    
                    UIAlertController *unmountCheck = [UIAlertController alertControllerWithTitle:@"Warning: Divisé has detected unexpected entries in '/dev/' which will need to be deleted." message:@"Divisé may have issues if these entries are not deleted.\n\nThis will uninstall any manually installed dual/multiboots.\n\nPress OK to delete these unexpected entries." preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        
                        for (int i = 0; i < [self->_diskDeletion count]; i++) {
                            
                            // Thankfully NSTasks work fine within loops :)
                            
                            NSTask *deleteDisk = [[NSTask alloc] init];
                            [deleteDisk setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
                            NSArray *deleteDiskArgs = [NSArray arrayWithObjects:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"apfs_deletefs"], [NSString stringWithFormat:@"%@", self->_diskDeletion[i]], nil];
                            [deleteDisk setArguments:deleteDiskArgs];
                            [deleteDisk launch];
                            [deleteDisk waitUntilExit];
                        }
                    }];
                    [unmountCheck addAction:useDefualtPathAction];
                    
                    UIAlertAction *exitButton = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        // Since the app will likely break if they choose not to remove the entries, the app will exit
                        exit(0);
                        
                    }];
                    [unmountCheck addAction:exitButton];
                    
                    [self presentViewController:unmountCheck animated:TRUE completion:nil];
                }
                
                
            }
            
            UIAlertController *dualbootInfo = [UIAlertController alertControllerWithTitle:@"Important: Please read the following arm64 Dualboot information popups" message:@"Press Start to continue" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"Start" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                    UIAlertController *infopart1 = [UIAlertController alertControllerWithTitle:@"arm64 Dualbooting" message:@"Do NOT set a password on the 2nd OS. This will break both installs." preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"Next" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        
                            UIAlertController *infopart2 = [UIAlertController alertControllerWithTitle:@"arm64 Dualbooting" message:@"You can uninstall the second OS at any time via the\n'Manage Installed Versions'\nbutton on the homepage." preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"Next" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                
                                    UIAlertController *infopart3 = [UIAlertController alertControllerWithTitle:@"arm64 Dualbooting" message:@"You will not be able to jailbreak most dualbooted OS's, with some execptions. This may change in the future!" preferredStyle:UIAlertControllerStyleAlert];
                                    UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"Next" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                        
                                            UIAlertController *infopart4 = [UIAlertController alertControllerWithTitle:@"arm64 Dualbooting" message:@"The versions you can dualboot are limited by the SEP compatibility of what you currently have installed." preferredStyle:UIAlertControllerStyleAlert];
                                            UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"Next" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                
                                                    UIAlertController *infopart5 = [UIAlertController alertControllerWithTitle:@"arm64 Dualbooting" message:@"Do NOT run\n'Erase All Content and Settings'\non the second OS, this will break the second OS and cause issues on the main OS." preferredStyle:UIAlertControllerStyleAlert];
                                                    UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"Next" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                        
                                                            UIAlertController *finalinfo = [UIAlertController alertControllerWithTitle:@"Done!" message:@"Thank you for reading! To start the dualbooting process, simply press the\n'Download IPSW'\nbutton and follow what Divisé tells you to do." preferredStyle:UIAlertControllerStyleAlert];
                                                            UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                                
                                                                    // Next one if needed
                                                                
                                                            }];
                                                            [finalinfo addAction:useDefualtPathAction];
                                                            [self presentViewController:finalinfo animated:TRUE completion:nil];
                                                        
                                                    }];
                                                    [infopart5 addAction:useDefualtPathAction];
                                                    [self presentViewController:infopart5 animated:TRUE completion:nil];
                                                
                                            }];
                                            [infopart4 addAction:useDefualtPathAction];
                                            [self presentViewController:infopart4 animated:TRUE completion:nil];
                                        
                                    }];
                                    [infopart3 addAction:useDefualtPathAction];
                                    [self presentViewController:infopart3 animated:TRUE completion:nil];
                                
                            }];
                            [infopart2 addAction:useDefualtPathAction];
                            [self presentViewController:infopart2 animated:TRUE completion:nil];
                        
                    }];
                    [infopart1 addAction:useDefualtPathAction];
                    [self presentViewController:infopart1 animated:TRUE completion:nil];
                
            }];
            [dualbootInfo addAction:useDefualtPathAction];
            [self presentViewController:dualbootInfo animated:TRUE completion:nil];

            
        }];
        
        [alertController addAction:dualbootButton];
        UIAlertAction *tetheredButton = [UIAlertAction actionWithTitle:@"Tethered Downgrade" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [divisePrefs setObject:@(0) forKey:@"dualboot"];
            [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
            [divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
            
        }];
        
        [alertController addAction:tetheredButton];
        [self presentViewController:alertController animated:YES completion:nil];
        
    }
    
    // Check if we are a beta build, and if so show the red label on the homepage
    
    if ([[NSString stringWithFormat:@"%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]] containsString:@"beta"]) {
    
        [self->_betaLabel setHidden:FALSE];
        
    } else {
        
        [self->_betaLabel setHidden:TRUE];
        
    }
    
    if ([[dualbootPrefs objectForKey:@"dualbooted"] isEqual:@(0)]) {
        
        bool *checkDelete = FALSE;
        self.diskDeletion = [[NSMutableArray alloc] init];
        
        NSString *path = @"/etc/fstab";
        NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        
        if ([_deviceVersion containsString:@"13."]) {
            for (int i = 6; i < 100; i++) {
                if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/dev/disk0s1s%d", i]]) {
                    
                    if (![content containsString:[NSString stringWithFormat:@"/dev/disk0s1s%d", i]]) {
                        
                        [self->_diskDeletion addObject:[NSString stringWithFormat:@"/dev/disk0s1s%d", i]];
                        checkDelete = TRUE;
                        
                    } else {
                        checkDelete = FALSE;
                    }
                }
            }
        } else {
            for (int i = 4; i < 100; i++) {
                           
               if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/dev/disk0s1s%d", i]]) {
                   
                   if (![content containsString:[NSString stringWithFormat:@"/dev/disk0s1s%d", i]]) {
                       
                       [self->_diskDeletion addObject:[NSString stringWithFormat:@"/dev/disk0s1s%d", i]];
                       checkDelete = TRUE;
                       
                   } else {
                       checkDelete = FALSE;
                   }
               }
            }
        }
        [self logToFile:[NSString stringWithFormat:@"About to delete:\n\n%@", _diskDeletion] atLineNumber:__LINE__];
        if (checkDelete) {
            
            // We can't show a UIAlert within a loop so have to use the checkDelete bool to see whether we should show the UIAlert or not
            
            UIAlertController *unmountCheck = [UIAlertController alertControllerWithTitle:@"Warning: Divisé has detected unexpected entries in '/dev/' which will need to be deleted." message:@"Divisé may have issues if these entries are not deleted.\n\nThis will uninstall any manually installed dual/multiboots.\n\nPress OK to delete these unexpected entries." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                for (int i = 0; i < [self->_diskDeletion count]; i++) {
                    
                    // Thankfully NSTasks work fine within loops :)
                    
                    NSTask *deleteDisk = [[NSTask alloc] init];
                    [deleteDisk setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
                    NSArray *deleteDiskArgs = [NSArray arrayWithObjects:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"apfs_deletefs"], [NSString stringWithFormat:@"%@", self->_diskDeletion[i]], nil];
                    [deleteDisk setArguments:deleteDiskArgs];
                    [deleteDisk launch];
                    [deleteDisk waitUntilExit];
                }
            }];
            [unmountCheck addAction:useDefualtPathAction];
            
            UIAlertAction *exitButton = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                // Since the app will likely break if they choose not to remove the entries, the app will exit
                
                exit(0);
                
            }];
            [unmountCheck addAction:exitButton];
            
            [self presentViewController:unmountCheck animated:TRUE completion:nil];
        }
        
    }
    
    // I know this is ugly and could be done better, but it works so :)
    
   NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
   long long freeSpaceSize = [[dictionary objectForKey:NSFileSystemFreeSize] longLongValue];
   double freespaceGB = (freeSpaceSize / 1024);
   double freespaceGB1 = (freespaceGB / 1024);
   double freespaceGB2 = (freespaceGB1 / 1024);
    
    if (freespaceGB2 < 9.0f) { // Around 9 GB free is needed for this to work :)
    
        
        UIAlertController *freeSpaceError = [UIAlertController alertControllerWithTitle:@"Error: Not enough free disk space" message:[NSString stringWithFormat:@"Divisé needs at least 9.0 GB of free disk space and you currently only have %.2f GB of free space.\nPlease free up %.2f GB and then reopen Divisé.", freespaceGB2, 9.0f - freespaceGB2] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *exitButton = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            exit(0);
            
        }];
        [freeSpaceError addAction:exitButton];
        
        [self presentViewController:freeSpaceError animated:TRUE completion:nil];
        
    }
    
}

- (void) viewDidAppear:(BOOL)animated{
    [[[self navigationController] navigationBar] setHidden:TRUE];
    //Checks to see if DMG has already been downloaded and sets buttons accordingly
    NSDictionary *divisePrefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist"];
    NSArray *contentsOfDiviseFolder = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Media/Divise/" error:nil];
    NSMutableDictionary *dualbootPrefs = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist"]];
    
        if ([[dualbootPrefs objectForKey:@"dualbooted"] isEqual:@(1)]) {
            
            // No need to save this to disk if we aren't dualbooting :)
            NSString *dualbootedVersion = [dualbootPrefs objectForKey:@"Version"];
            NSString *dualbootedSystemB = [dualbootPrefs objectForKey:@"SystemB"];
            NSString *dualbootedDataB = [dualbootPrefs objectForKey:@"DataB"];
            // Make sure that we set the labels so the user knows what is installed where
            self.dualbootedVersion.text = dualbootedVersion;
            
            self.dualbootedDiskID.text = [NSString stringWithFormat:@"%@/%@", dualbootedSystemB, dualbootedDataB];
            [_dualbootedDiskID setHidden:false];
            [_dualbootedVersion setHidden:false];
            [_databLabel setHidden:false];
            
            [_prepareToRestoreButton setHidden:TRUE];
            [_prepareToRestoreButton setEnabled:FALSE];
            [_dualbootSettings setHidden:false];
            [_dualbootSettings setEnabled:true];
                
            [_downloadDMGButton setHidden:TRUE];
            [_downloadDMGButton setEnabled:FALSE];
                
            [_prepareToRestoreButton setHidden:TRUE];
            [_prepareToRestoreButton setEnabled:FALSE];
                
            [_decryptDMGButton setHidden:TRUE];
            [_decryptDMGButton setEnabled:FALSE];
       
    } else {
        
            // Make sure labels are hidden if user is not dualbooting/dualbooted
            [_dualbootedDiskID setHidden:true];
            [_dualbootedVersion setHidden:true];
            [_databLabel setHidden:true];
            [_dualbootSettings setHidden:true];
            [_dualbootSettings setEnabled:false];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Divise/rfs.dmg"]) {
                [_downloadDMGButton setHidden:TRUE];
                [_downloadDMGButton setEnabled:FALSE];
                [_prepareToRestoreButton setHidden:FALSE];
                [_prepareToRestoreButton setEnabled:TRUE];
                if ([[divisePrefs objectForKey:@"dualboot"] isEqual:@(1)]) {
                    
                    [_prepareToRestoreButton setTitle:@"Dualboot Device!" forState:UIControlStateNormal];
                    
                }
                [_decryptDMGButton setHidden:TRUE];
                [_decryptDMGButton setEnabled:FALSE];
                for (NSString *file in contentsOfDiviseFolder) {
                    if (![file isEqualToString:@"rfs.dmg"]) {
                        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/var/mobile/Media/Divise/%@", file] error:nil];
                    }
                }
            } else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Divise/encrypted.dmg"]) {
                [_downloadDMGButton setHidden:TRUE];
                [_downloadDMGButton setEnabled:FALSE];
                [_prepareToRestoreButton setHidden:TRUE];
                [_prepareToRestoreButton setEnabled:FALSE];
                [_decryptDMGButton setHidden:FALSE];
                [_decryptDMGButton setEnabled:TRUE];
                for (NSString *file in contentsOfDiviseFolder) {
                    if (![file isEqualToString:@"encrypted.dmg"]) {
                        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/var/mobile/Media/Divise/%@", file] error:nil];
                    }
                }
            } else {
                if ([[NSFileManager defaultManager] fileExistsAtPath:[divisePrefs objectForKey:@"custom_ipsw_path"]]) {
                    
                    UIAlertController *unmountCheck = [UIAlertController alertControllerWithTitle:@"Local IPSW Found" message:@"Press OK to unzip it or Delete to delete the local IPSW" preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        
                            [self->_divisePrefs setObject:@(1) forKey:@"found_local_ipsw"];
                            [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
                            [self->_divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
                            
                            [self performSegueWithIdentifier: @"deviceInfoShare" sender: self];
                        
                    }];
                    [unmountCheck addAction:useDefualtPathAction];
                    UIAlertAction *deleteButton = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        
                            [self->_divisePrefs setObject:@(0) forKey:@"found_local_ipsw"];
                            [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
                            [self->_divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
                            
                            [[NSFileManager defaultManager] removeItemAtPath:[divisePrefs objectForKey:@"custom_ipsw_path"] error:nil];
                        
                    }];
                    [unmountCheck addAction:deleteButton];
                    [self presentViewController:unmountCheck animated:TRUE completion:nil];

                } else {
                    for (NSString *file in contentsOfDiviseFolder) {
                        if ([file containsString:@".ipsw"]) {
                            UIAlertController *unmountCheck = [UIAlertController alertControllerWithTitle:@"Local IPSW Found" message:@"Press OK to unzip it or Delete to delete the local IPSW" preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                
                                    [self->_divisePrefs setObject:@(1) forKey:@"found_local_ipsw"];
                                    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
                                    [self->_divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
                                
                                    [self->_divisePrefs setObject:[NSString stringWithFormat:@"/var/mobile/Media/Divise/%@", file] forKey:@"custom_ipsw_path"];
                                    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
                                    [self->_divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
                                    
                                    [self performSegueWithIdentifier: @"deviceInfoShare" sender: self];
                                
                            }];
                            [unmountCheck addAction:useDefualtPathAction];
                            UIAlertAction *deleteButton = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                
                                    [self->_divisePrefs setObject:@(0) forKey:@"found_local_ipsw"];
                                    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
                                    [self->_divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
                                    
                                    [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
                                
                            }];
                            [unmountCheck addAction:deleteButton];
                            [self presentViewController:unmountCheck animated:TRUE completion:nil];
                        }
                    }
                }
                [_downloadDMGButton setHidden:FALSE];
                [_downloadDMGButton setEnabled:TRUE];
                [_prepareToRestoreButton setHidden:TRUE];
                [_prepareToRestoreButton setEnabled:FALSE];
                [_decryptDMGButton setHidden:TRUE];
                [_decryptDMGButton setEnabled:FALSE];
            }
    }
    
 
}


- (IBAction)contactSupportButton:(id)sender {
    UIAlertController *contactSupport = [UIAlertController alertControllerWithTitle:@"Contact Moski" message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *twitterSupport = [UIAlertAction actionWithTitle:@"On Twitter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //Opens a DM to my twitter
        if (@available(iOS 10.0, *)) {
            NSDictionary *URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/messages/compose?recipient_id=2696641500"] options:URLOptions completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/messages/compose?recipient_id=2696641500"]];
        }
    }];
    UIAlertAction *redditSupport = [UIAlertAction actionWithTitle:@"On Reddit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //Opens a PM to my reddit
        if (@available(iOS 10.0, *)) {
            NSDictionary *URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/message/compose/?to=_Matty"] options:URLOptions completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/message/compose/?to=_Matty"]];
        }
    }];
    [contactSupport addAction:twitterSupport];
    [contactSupport addAction:redditSupport];
    [self presentViewController:contactSupport animated:TRUE completion:nil];
}

- (IBAction)donateButton:(id)sender {
    //Hey, someone actually decided to donate?! <3
    if (@available(iOS 10.0, *)) {
        NSDictionary *URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.me/SamGardner4/"] options:URLOptions completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.me/SamGardner4/"]];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"deviceInfoShare"]) {
        DownloadViewController *destViewController = segue.destinationViewController;
        destViewController.deviceVersion = _deviceVersion;
        destViewController.deviceModel = _deviceModel;
        destViewController.deviceBuild = _deviceBuild;
    }
}

- (IBAction)infoNotAccurateButton:(id)sender {
    //Code that runs the "Information not correct" button
    UIAlertController *infoNotAccurateButtonInfo = [UIAlertController alertControllerWithTitle:@"Please provide your own DMG" message:@"Please extract a clean IPSW for your device/iOS version and place the largest DMG file in /var/mobile/Media/Divise. On iOS 9.3.5 and older, you will need to decrypt the DMG first." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [infoNotAccurateButtonInfo addAction:okAction];
    [self presentViewController:infoNotAccurateButtonInfo animated:YES completion:nil];
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

