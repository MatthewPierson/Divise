//
//  SettingsViewController.m
//  Divisé
//
//  Created by matty on 27/05/20.
//  Copyright © 2020 Sam Gardner. All rights reserved.
//

#import "SettingsViewController.h"
#import "NSTask.h"
#include <sys/sysctl.h>

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UISwipeGestureRecognizer *devOptions = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(upSwipe:)];
    [devOptions setNumberOfTouchesRequired:3];
    [devOptions setDirection:UISwipeGestureRecognizerDirectionUp];
    [self.view addGestureRecognizer:devOptions];
    
    _divisePrefs = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary  dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist"]];
    [[[self navigationController] navigationBar] setHidden:FALSE];
    self.navigationItem.title = @"Settings";
    
    _versionLabel.text = [NSString stringWithFormat:@"Divisé version %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    _versionLabel.backgroundColor = [UIColor grayColor];
    
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    //Gets iOS device model (ex iPhone9,1 == iPhone 7 GSM) and changes label.
    char *modelChar = malloc(size);
    sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
    
    [_deleteDuringSwitch setOn:[[_divisePrefs objectForKey:@"dualboot"] boolValue] animated:NO];
    [_deleteDuringSwitch addTarget:self action:@selector(dualbootSwitchChanged) forControlEvents:UIControlEventValueChanged];
    
    [_logOutputSwitch setOn:[[_divisePrefs objectForKey:@"log-file"] boolValue] animated:NO];
    [_logOutputSwitch addTarget:self action:@selector(logFileSwitchChanged) forControlEvents:UIControlEventValueChanged];
    
    [_hacktivateSwitch setOn:[[_divisePrefs objectForKey:@"hacktivate"] boolValue] animated:NO];
    [_hacktivateSwitch addTarget:self action:@selector(hacktivateSwitchChanged) forControlEvents:UIControlEventValueChanged];
    
    [_forceapfsSwitch setOn:[[_divisePrefs objectForKey:@"forceapfs.fs"] boolValue] animated:NO];
    [_forceapfsSwitch addTarget:self action:@selector(forceapfsSwitchChanged) forControlEvents:UIControlEventValueChanged];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Divise/rfs.dmg"]) {
        
        [self->_deleterfs setEnabled:FALSE];
        [self->_deleterfs setBackgroundColor:[UIColor darkGrayColor]];
        [self->_deleterfs setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        
    }
    if ([[self->_divisePrefs objectForKey:@"devMode"] isEqual:@(1)]) {
        [self->_forceapfsLabel setHidden:FALSE];
        [self->_hacktivateLabel setHidden:FALSE];
        [self->_forceapfsSwitch setHidden:FALSE];
        [self->_hacktivateSwitch setHidden:FALSE];
        [self->_forceapfsSwitch setEnabled:TRUE];
        [self->_hacktivateSwitch setEnabled:TRUE];
    }
    
}

-(void)viewDidAppear:(BOOL)animated{
    [[[self navigationController] navigationBar] setHidden:FALSE];
    self.navigationItem.title = @"Settings";
}

-(void)upSwipe:(UISwipeGestureRecognizer *)gesture
{
    if ([[self->_divisePrefs objectForKey:@"devMode"] isEqual:@(0)]) {
        UIAlertController *devEnable = [UIAlertController alertControllerWithTitle:@"Enabling developer mode..." message:@"" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:devEnable animated:TRUE completion:nil];
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            sleep(2);
            dispatch_async(dispatch_get_main_queue(), ^{
                [devEnable dismissViewControllerAnimated:YES completion:nil];
                [self->_forceapfsLabel setHidden:FALSE];
                [self->_hacktivateLabel setHidden:FALSE];
                [self->_forceapfsSwitch setHidden:FALSE];
                [self->_hacktivateSwitch setHidden:FALSE];
                [self->_forceapfsSwitch setEnabled:TRUE];
                [self->_hacktivateSwitch setEnabled:TRUE];
                [self->_divisePrefs setObject:@(1) forKey:@"devMode"];
                [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
                [self->_divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
            });
        });
    }
}

- (IBAction)backButton:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)resetSettings:(UIButton *)sender {
    // Delete .plist's and restart app, give prompt to ensure user wants to first though
    
    UIAlertController *warningCheck = [UIAlertController alertControllerWithTitle:@"Warning: This will reset all of Divisé's settings/preferences and exit the app" message:@"Press OK to continue" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        
        UIAlertController *exitThing = [UIAlertController alertControllerWithTitle:@"Successfully reset settings/preferences" message:@"Press OK to exit the app" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                exit(0);
            
        }];
        [exitThing addAction:useDefualtPathAction];
        [self presentViewController:exitThing animated:TRUE completion:nil];
        
    }];
    [warningCheck addAction:useDefualtPathAction];
    
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
    [warningCheck addAction:cancelButton];
    [self presentViewController:warningCheck animated:TRUE completion:nil];
    
    
    
}

-(void)dualbootSwitchChanged{
    if ([[_divisePrefs objectForKey:@"dualboot"] isEqual:@(0)]) {
        [_divisePrefs setObject:@(1) forKey:@"dualboot"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [_divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
    } else {
        [_divisePrefs setObject:@(0) forKey:@"dualboot"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [_divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
    }
}

-(void)logFileSwitchChanged{
    if ([[_divisePrefs objectForKey:@"log-file"] isEqual:@(0)]) {
        [_divisePrefs setObject:@(1) forKey:@"log-file"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [_divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
    } else {
        [_divisePrefs setObject:@(0) forKey:@"log-file"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [_divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
    }
}
-(void)forceapfsSwitchChanged{
    if ([[_divisePrefs objectForKey:@"forceapfs.fs"] isEqual:@(0)]) {
        [_divisePrefs setObject:@(1) forKey:@"forceapfs.fs"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [_divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
    } else {
        [_divisePrefs setObject:@(0) forKey:@"forceapfs.fs"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [_divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
    }
}

-(void)hacktivateSwitchChanged{
    if ([[_divisePrefs objectForKey:@"hacktivate"] isEqual:@(0)]) {
        [_divisePrefs setObject:@(1) forKey:@"hacktivate"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [_divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
    } else {
        [_divisePrefs setObject:@(0) forKey:@"hacktivate"];
        [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
        [_divisePrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
    }
}

- (IBAction)deleteRootfs:(UIButton *)sender {
    [self->_spinningThing.backgroundColor = [UIColor darkGrayColor] colorWithAlphaComponent:0.75f];
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
    [self->_deleterfs setEnabled:FALSE];
    [self->_deleterfs setBackgroundColor:[UIColor darkGrayColor]];
    [self->_deleterfs setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [self->_spinningThing setHidden:TRUE]; 
    
}


@end
