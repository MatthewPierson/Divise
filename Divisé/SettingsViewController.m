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
    
    NSString *modelThing = [NSString stringWithUTF8String:modelChar];
    
    if ([modelThing containsString:@"iPad"]) {
        
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
    
    [_deleteDuringSwitch setOn:[[_divisePrefs objectForKey:@"dualboot"] boolValue] animated:NO];
    [_deleteDuringSwitch addTarget:self action:@selector(dualbootSwitchChanged) forControlEvents:UIControlEventValueChanged];
    
    [_logOutputSwitch setOn:[[_divisePrefs objectForKey:@"log-file"] boolValue] animated:NO];
    [_logOutputSwitch addTarget:self action:@selector(logFileSwitchChanged) forControlEvents:UIControlEventValueChanged];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Divise/rfs.dmg"]) {
        
        [self->_deleterfs setEnabled:FALSE];
        [self->_deleterfs setBackgroundColor:[UIColor darkGrayColor]];
        [self->_deleterfs setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        
    }
    
}

-(void)viewDidAppear:(BOOL)animated{
    [[[self navigationController] navigationBar] setHidden:FALSE];
    self.navigationItem.title = @"Settings";
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

- (IBAction)funButton:(UIButton *)sender {
    
    if (@available(iOS 10.0, *)) {
        NSDictionary *URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/tpwkhollands/status/1265757092473954306"] options:URLOptions completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/tpwkhollands/status/1265757092473954306"]];
    }
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

- (IBAction)deleteRootfs:(UIButton *)sender {
    [self->_spinningThing.backgroundColor = [UIColor darkGrayColor] colorWithAlphaComponent:0.75f];
    [self->_spinningThing setHidden:FALSE];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mnt/divise/etc/fstab"]) {
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
