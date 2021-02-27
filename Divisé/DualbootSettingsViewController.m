//
//  DualbootSettingsViewController.m
//  Divisé
//
//  Created by matty on 10/05/20.
//  Copyright © 2020 Sam Gardner. All rights reserved.
//


#import "DualbootSettingsViewController.h"
#import "NSTask.h"
#import "HomePageViewController.h"
#include <sys/sysctl.h>
#include <CommonCrypto/CommonDigest.h>

@interface DualbootSettingsViewController ()

@end

@implementation DualbootSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup background image
    
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0); 
    
    //Gets iOS device model (ex iPhone9,1 == iPhone 7 GSM) and changes label.
    char *modelChar = malloc(size);
    sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Divise/rfs.dmg"]) {
        
        [self->_deleteRfs setEnabled:FALSE];
        [self->_deleteRfs setBackgroundColor:[UIColor darkGrayColor]];
        [self->_deleteRfs setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        
    }
    
    [[[self navigationController] navigationBar] setHidden:FALSE];
    self.navigationItem.title = @"Dualboot Settings";
    _divisePrefs = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist"]]; 
    _dualbootPrefs = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist"]];
    
    // Check if second OS is already mounted and show the corresponding buttons
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/mnt1/bin/df"]) {
        
        [self->_mountButton setEnabled:FALSE];
        [self->_unmountButton setEnabled:TRUE];
        [self->_mountButton setHidden:TRUE];
        [self->_unmountButton setHidden:FALSE];
        [self->_spinningThing setHidden:TRUE];
        
    } else {
        
        [self->_mountButton setEnabled:TRUE];
        [self->_unmountButton setEnabled:FALSE];
        [self->_mountButton setHidden:FALSE];
        [self->_unmountButton setHidden:TRUE];
        [self->_spinningThing setHidden:TRUE];
        
    }
}


- (IBAction)deleteRootfs:(UIButton *)sender {
    
    [self->_deleteButton setEnabled:FALSE];
    [self->_wipeButton setEnabled:FALSE];
    [self->_deleteRfs setEnabled:FALSE];
    [self->_spinningThing setHidden:FALSE];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mnt/divise/mnt1/bin/df"]) {
        UIAlertController *unmountCheck = [UIAlertController alertControllerWithTitle:@"Error: RootFS is still mounted" message:@"Press OK to unmount the RootFS and continue" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            NSTask *unmountRootfs = [[NSTask alloc] init];
            [unmountRootfs setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
            NSArray *unmountRootfsArgs = [NSArray arrayWithObjects:@"umount", @"-f", @"/var/mnt/divise/", nil];
            [unmountRootfs setArguments:unmountRootfsArgs];
            [unmountRootfs launch];
            [unmountRootfs waitUntilExit];
            
        }];
        [unmountCheck addAction:useDefualtPathAction];
        [self presentViewController:unmountCheck animated:TRUE completion:nil];
    }
    
    // Delete the rootfs.dmg :)
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Divise/rfs.dmg"]) {
        
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Media/Divise/rfs.dmg" error:nil];
        
    }
    else {
        UIAlertController *alreadyDone = [UIAlertController alertControllerWithTitle:@"Rootfs.dmg has already been deleted!" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alreadyDone addAction:useDefualtPathAction];
        [self presentViewController:alreadyDone animated:TRUE completion:nil];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Divise/rfs.dmg"]) {
        
        UIAlertController *deleteComp = [UIAlertController alertControllerWithTitle:@"Rootfs.dmg has been deleted!" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [deleteComp addAction:useDefualtPathAction];
        [self presentViewController:deleteComp animated:TRUE completion:nil];
        
    }
    [self->_deleteButton setEnabled:TRUE];
    [self->_wipeButton setEnabled:TRUE];
    [self->_deleteRfs setEnabled:FALSE];
    [self->_deleteRfs setBackgroundColor:[UIColor darkGrayColor]];
    [self->_deleteRfs setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [self->_spinningThing setHidden:TRUE];
}


- (IBAction)unmountSecondOS:(UIButton *)sender {
    [self logToFile:@"Unmounting second OS" atLineNumber:__LINE__];
    
    // Need to fix the wrong alert showing when unmounting
    
    NSString *dualbootedVersion = [_dualbootPrefs objectForKey:@"Version"];
    NSString *dualbootedSystemB = [_dualbootPrefs objectForKey:@"SystemB"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/mnt1/bin/df"]) {
        UIAlertController *unmountCheck = [UIAlertController alertControllerWithTitle:@"Error Unmounting SystemB Partition" message:@"SystemB partition has already been unmounted!" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [unmountCheck addAction:useDefualtPathAction];
        [self presentViewController:unmountCheck animated:TRUE completion:nil];
    }
    else {
        if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/dev/%@", dualbootedSystemB]]) {
            UIAlertController *unmountCheck2 = [UIAlertController alertControllerWithTitle:@"Error Unmounting DataB Partition" message:@"DataB partition has already been unmounted!" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [unmountCheck2 addAction:useDefualtPathAction];
            [self presentViewController:unmountCheck2 animated:TRUE completion:nil];
        }
        else {
            // Main unmount code
            // unmount SystemB
            [self->_spinningThing setHidden:FALSE];
            [self->_deleteButton setEnabled:FALSE];
            [self->_wipeButton setEnabled:FALSE];
            [self->_mountButton setEnabled:FALSE];
            [self->_unmountButton setEnabled:FALSE];
            [self->_deleteRfs setEnabled:FALSE];
            
            NSTask *unmountDataBTask = [[NSTask alloc] init];
            [unmountDataBTask setLaunchPath:[[[NSBundle mainBundle] bundlePath]  stringByAppendingPathComponent:@"succdatroot"]];
            NSArray *mountDataBArgs = [NSArray arrayWithObjects:@"umount", @"-f", @"/mnt1/private/var/", nil];
            [unmountDataBTask setArguments:mountDataBArgs];
            [unmountDataBTask launch];
            [unmountDataBTask waitUntilExit];
            // umount DataB
            NSTask *unmountSysBTask = [[NSTask alloc] init];
            [unmountSysBTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
            NSArray *mountSysBArgs = [NSArray arrayWithObjects:@"umount", @"-f", @"/mnt1/", nil];
            [unmountSysBTask setArguments:mountSysBArgs];
            [unmountSysBTask launch];
            [unmountSysBTask waitUntilExit];
            
            // Check if still mounted
            if (![[NSFileManager defaultManager] fileExistsAtPath:@"/mnt1/bin/df"]) {
                UIAlertController *unmountCheck = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"iOS %@ has been unmounted!", dualbootedVersion] message:@"" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [unmountCheck addAction:useDefualtPathAction];
                [self presentViewController:unmountCheck animated:TRUE completion:nil];
            }
            else {
                UIAlertController *unmountCheck2 = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Error: iOS %@ failed to unmount!", dualbootedVersion] message:@"Please close anything using the second systems files and try again!" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [unmountCheck2 addAction:useDefualtPathAction];
                [self presentViewController:unmountCheck2 animated:TRUE completion:nil];
            }
            
            [self->_deleteButton setEnabled:TRUE];
            [self->_wipeButton setEnabled:TRUE];
            [self->_mountButton setEnabled:TRUE];
            [self->_mountButton setHidden:FALSE];
            [self->_unmountButton setEnabled:FALSE];
            [self->_unmountButton setHidden:TRUE];
            [self->_deleteRfs setEnabled:TRUE];
            [self->_spinningThing setHidden:TRUE];
            
        }
    }
}

- (IBAction)mountSecondOS:(UIButton *)sender {
    
    [self logToFile:@"Mounting second OS" atLineNumber:__LINE__];
    
    NSString *dualbootedVersion = [_dualbootPrefs objectForKey:@"Version"];
    NSString *dualbootedSystemB = [_dualbootPrefs objectForKey:@"SystemB"];
    NSString *dualbootedDataB = [_dualbootPrefs objectForKey:@"DataB"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/dev/%@", dualbootedSystemB]]) {
        UIAlertController *apfs_deletefsCheckSys = [UIAlertController alertControllerWithTitle:@"Error Mounting SystemB Partition" message:@"SystemB partition has already been deleted!" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [apfs_deletefsCheckSys addAction:useDefualtPathAction];
        [self presentViewController:apfs_deletefsCheckSys animated:TRUE completion:nil];
    }
    else {
        if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/dev/%@", dualbootedSystemB]]) {
            UIAlertController *apfs_deletefsCheckData = [UIAlertController alertControllerWithTitle:@"Error Mounting DataB Partition" message:@"DataB partition has already been deleted!" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [apfs_deletefsCheckData addAction:useDefualtPathAction];
            [self presentViewController:apfs_deletefsCheckData animated:TRUE completion:nil];
        }
        else {
            // Main mount code
            // Mount SystemB
            
            [self->_spinningThing setHidden:FALSE];
            [self->_deleteButton setEnabled:FALSE];
            [self->_wipeButton setEnabled:FALSE];
            [self->_mountButton setEnabled:FALSE];
            [self->_unmountButton setEnabled:FALSE];
            [self->_deleteRfs setEnabled:FALSE];
            
            NSTask *mountSysBTask = [[NSTask alloc] init];
            [mountSysBTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
            NSArray *mountSysBArgs = [NSArray arrayWithObjects:@"mount_apfs", [NSString stringWithFormat:@"/dev/%@", dualbootedSystemB], @"/mnt1", nil];
            [mountSysBTask setArguments:mountSysBArgs];
            [mountSysBTask launch];
            [mountSysBTask waitUntilExit];
            // Mount DataB to /mnt1/private/var
            NSTask *mountDataBTask = [[NSTask alloc] init];
            [mountDataBTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
            NSArray *mountDataBArgs = [NSArray arrayWithObjects:@"mount_apfs", [NSString stringWithFormat:@"/dev/%@", dualbootedDataB], @"/mnt1/private/var", nil];
            [mountDataBTask setArguments:mountDataBArgs];
            [mountDataBTask launch];
            [mountDataBTask waitUntilExit];
            
            // Check if mounted
            if ([[NSFileManager defaultManager] fileExistsAtPath:@"/mnt1/bin/df"]) {
                UIAlertController *mountCheck = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"iOS %@ is now mounted to '/mnt1/'", dualbootedVersion] message:@"DataB partition has been mounted to\n'/mnt1/private/var/'" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [mountCheck addAction:useDefualtPathAction];
                [self presentViewController:mountCheck animated:TRUE completion:nil];
            }
            else {
                UIAlertController *mountCheck = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Error: iOS %@ failed to mount!", dualbootedVersion] message:@"Please reboot/rejailbreak and try again!" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [mountCheck addAction:useDefualtPathAction];
                [self presentViewController:mountCheck animated:TRUE completion:nil];
            }
            
            [self->_deleteButton setEnabled:TRUE];
            [self->_wipeButton setEnabled:TRUE];
            [self->_mountButton setEnabled:FALSE];
            [self->_mountButton setHidden:TRUE];
            [self->_unmountButton setEnabled:TRUE];
            [self->_unmountButton setHidden:FALSE];
            [self->_deleteRfs setEnabled:TRUE];
            [self->_spinningThing setHidden:TRUE];
        }
    }
}

- (IBAction)deleteSecondOS:(UIButton *)sender {
    
    NSString *dualbootedVersion = [_dualbootPrefs objectForKey:@"Version"];
    NSString *dualbootedSystemB = [_dualbootPrefs objectForKey:@"SystemB"];
    NSString *dualbootedDataB = [_dualbootPrefs objectForKey:@"DataB"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/dev/%@", dualbootedSystemB]]) {
        UIAlertController *apfs_deletefsCheckSys = [UIAlertController alertControllerWithTitle:@"Error Deleting SystemB Partition" message:@"SystemB partition has already been deleted!" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [apfs_deletefsCheckSys addAction:useDefualtPathAction];
        [self presentViewController:apfs_deletefsCheckSys animated:TRUE completion:nil];
    }
    else {
        if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/dev/%@", dualbootedSystemB]]) {
            UIAlertController *apfs_deletefsCheckData = [UIAlertController alertControllerWithTitle:@"Error Deleting DataB Partition" message:@"DataB partition has already been deleted!" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [apfs_deletefsCheckData addAction:useDefualtPathAction];
            [self presentViewController:apfs_deletefsCheckData animated:TRUE completion:nil];
        }
        else {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hdik"]]) {
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Warning: You are about to uninstall iOS %@", dualbootedVersion] message:@"Are you sure you want to do this?" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    
                    [self->_spinningThing setHidden:FALSE];
                    [self->_deleteButton setEnabled:FALSE];
                    [self->_wipeButton setEnabled:FALSE];
                    [self->_mountButton setEnabled:FALSE];
                    [self->_deleteRfs setEnabled:FALSE];
                    
                    // Remove SystemB partition
                    NSTask *apfsdeleteTask = [[NSTask alloc] init];
                    NSArray *apfsdeleteArgs;
                    NSString *version = [[UIDevice currentDevice] systemVersion];
                    
                    if ([version containsString:@"10."]) { // Avoid using succdatroot on iOS 10 as we run Divse as root to avoid succdatroot being broken on 10.x
                        [apfsdeleteTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"apfs_deletefs"]];
                        apfsdeleteArgs = [NSArray arrayWithObjects: [NSString stringWithFormat:@"%@", dualbootedSystemB], nil];
                    } else {
                        [apfsdeleteTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
                        apfsdeleteArgs = [NSArray arrayWithObjects:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"apfs_deletefs"], [NSString stringWithFormat:@"%@", dualbootedSystemB], nil];
                    }
                    
                    [apfsdeleteTask setArguments:apfsdeleteArgs];
                    [apfsdeleteTask launch];
                    [apfsdeleteTask waitUntilExit];
                    
                    // Remove DataB partition
                    NSTask *apfsdeleteTask2 = [[NSTask alloc] init];
                    NSArray *apfsdeleteArgs2;
                    
                    if ([version containsString:@"10."]) { // Avoid using succdatroot on iOS 10 as we run Divse as root to avoid succdatroot being broken on 10.x
                        [apfsdeleteTask2 setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
                        apfsdeleteArgs2 = [NSArray arrayWithObjects:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"apfs_deletefs"], [NSString stringWithFormat:@"%@", dualbootedDataB], nil];
                    } else {
                        [apfsdeleteTask2 setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
                        apfsdeleteArgs2 = [NSArray arrayWithObjects:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"apfs_deletefs"], [NSString stringWithFormat:@"%@", dualbootedDataB], nil];
                    }
                    [apfsdeleteTask2 setArguments:apfsdeleteArgs2];
                    [apfsdeleteTask2 launch];
                    [apfsdeleteTask2 waitUntilExit];
                    
                    if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/dev/%@", dualbootedSystemB]] || !([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/dev/%@", dualbootedSystemB]])) {
                        
                        [self->_dualbootPrefs setObject:@"uninstalled" forKey:@"SystemB"];
                        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" error:nil];
                        [self->_dualbootPrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" atomically:TRUE];

                        [self->_dualbootPrefs setObject:@"uninstalled" forKey:@"DataB"];
                        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" error:nil];
                        [self->_dualbootPrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" atomically:TRUE];

                        [self->_dualbootPrefs setObject:@(0) forKey:@"dualbooted"];
                        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" error:nil];
                        [self->_dualbootPrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" atomically:TRUE];
                        
                        UIAlertController *apfs_deletefsSuccess = [UIAlertController alertControllerWithTitle:@"Uninstall Successful!" message:@"You can now re-dualboot your device if you wish to" preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                        [apfs_deletefsSuccess addAction:useDefualtPathAction];
                        [self presentViewController:apfs_deletefsSuccess animated:TRUE completion:nil];
                        
                        [self->_deleteRfs setEnabled:TRUE];
                        [self->_deleteButton setEnabled:FALSE];
                        [self->_wipeButton setEnabled:FALSE];
                        [self->_mountButton setEnabled:FALSE];
                        [self->_unmountButton setEnabled:FALSE];
                        [self->_spinningThing setHidden:TRUE];
                        [self->_deleteButton setBackgroundColor:[UIColor darkGrayColor]];
                        [self->_deleteButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
                        [self->_wipeButton setBackgroundColor:[UIColor darkGrayColor]];
                        [self->_wipeButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
                        if ([self->_mountButton isHidden]) {
                            [self->_unmountButton setBackgroundColor:[UIColor darkGrayColor]];
                            [self->_unmountButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
                        } else {
                            [self->_mountButton setBackgroundColor:[UIColor darkGrayColor]];
                            [self->_mountButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
                        }
                    }
                    else {
                        UIAlertController *apfs_deletefsSysFail = [UIAlertController alertControllerWithTitle:@"Failed to uninstall the second OS!" message:@"Please try again" preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                        [apfs_deletefsSysFail addAction:useDefualtPathAction];
                        [self presentViewController:apfs_deletefsSysFail animated:TRUE completion:nil];
                        
                        [self->_deleteButton setEnabled:TRUE];
                        [self->_wipeButton setEnabled:TRUE];
                        [self->_mountButton setEnabled:TRUE];
                        [self->_deleteRfs setEnabled:TRUE];
                        [self->_spinningThing setHidden:TRUE];
                    }
                }];
                
                [alertController addAction:confirmAction];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    NSLog(@"Canelled");
                }];
                [alertController addAction:cancelAction];
                [self presentViewController:alertController animated:YES completion:nil];
            }
            else {
                UIAlertController *apfs_deletefsNotFound = [UIAlertController alertControllerWithTitle:@"Unable to find apfs_deletefs" message:@"Please install it trhough Cydia, restart Divisé and try again." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
                [apfs_deletefsNotFound addAction:useDefualtPathAction];
                [self presentViewController:apfs_deletefsNotFound animated:TRUE completion:nil];
            }
        }
    }
}

- (IBAction)wipeDataB:(UIButton *)sender {
    
    NSLog(@"Coming soon!");
    UIAlertController *wipeDataB = [UIAlertController alertControllerWithTitle:@"Coming Soon!" message:@":)" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [wipeDataB addAction:useDefualtPathAction];
    [self presentViewController:wipeDataB animated:TRUE completion:nil];
    
}


- (IBAction)backButton:(UIButton *)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
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
