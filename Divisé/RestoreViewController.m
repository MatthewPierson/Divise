//
//  RestoreViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 6/30/18.
//  Re-created 11/28/19.
//  Copyright © 2019 Sam Gardner. All rights reserved.
//

#import "RestoreViewController.h"
#include <sys/sysctl.h>
#import "NSTask.h"
#import <spawn.h>

@interface RestoreViewController ()

@end

@implementation RestoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Load Preferences
    _divisePrefs = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist"]];
    _dualbootPrefs = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist"]];
    _secondOS = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"]];
    //Get device machine ID, used several times in the future
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *modelChar = malloc(size);
    sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
    _deviceModel = [NSString stringWithUTF8String:modelChar];
    free(modelChar);
    _installedVersion = [[UIDevice currentDevice] systemVersion];
    if ([_deviceModel containsString:@"iPhone"]) {
        _deviceType = @"iPhone";
    } else if ([_deviceModel containsString:@"iPad"]) {
        _deviceType = @"iPad";
    } else if ([_deviceModel containsString:@"iPod"]) {
        _deviceType = @"iPod";
    } else if ([_deviceModel containsString:@"AppleTV"]) {
        _deviceType = @"Apple TV";
    } else {
        _deviceType = @"unknown iOS device";
    }
    
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
    //Set up UI
    if ([self isMounted]) {
        [[self titleLabel] setText:@"WARNING!!!"];
        [[self subtitleLabel] setText:@"Running this tool will immediately delete all data from your device. Please make a backup of any data that you want to keep. This will also return your device to the setup screen.  A valid SIM card may be needed for activation on iPhones and cellular iPads."];
        [[self eraseButton] setTitle:[NSString stringWithFormat:@"Erase %@", _deviceType] forState:UIControlStateNormal];
        [[self eraseButton] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [[self eraseButton] setEnabled:TRUE];
        [[self outputLabel] setHidden:TRUE];
        [[self progressIndicator] setHidden:TRUE];
        [[self restoreProgressBar] setHidden:TRUE];
    } else {
        [[self titleLabel] setText:@"Attaching..."];
        [[self subtitleLabel] setText:@"This should take less than 10 seconds"];
        [[self eraseButton] setTitle:@"Please Wait..." forState:UIControlStateNormal];
        if (@available(iOS 13.0, *)) {
            [[self eraseButton] setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
        } else {
            [[self eraseButton] setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
        }
        [[self eraseButton] setEnabled:FALSE];
        [[self outputLabel] setHidden:TRUE];
        [[self progressIndicator] setHidden:FALSE];
        [[self restoreProgressBar] setHidden:TRUE];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    // If the disk isn't mounted, attach and mount
    if (![self isMounted]) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            [self checkMountPoint];
        });
    }
}

- (IBAction)backButton:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(BOOL)isMounted{
    // if this file doesnt exist, the disk isnt mounted, and the chances of someone creating it "just for fun" is astronomically low
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/mnt/divise/sbin/launchd"]) {
        return TRUE;
    } else {
        return FALSE;
    }
}

-(void)checkMountPoint{
    BOOL isDirectory;
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/mnt/divise/" isDirectory:&isDirectory]) {
        if (isDirectory) {
            [self logToFile:@"Mountpoint exists, continuing" atLineNumber:__LINE__];
            [self attachDiskImage];
        } else {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:@"/private/var/mnt/divise/" error:&error];
            if (!error) {
                [[NSFileManager defaultManager] createDirectoryAtPath:@"/private/var/mnt/divise/" withIntermediateDirectories:TRUE attributes:nil error:&error];
                if (!error) {
                    [self attachDiskImage];
                } else {
                    [self logToFile:[NSString stringWithFormat:@"Got %@ when trying to create mountpoint, using bypass.", [error localizedDescription]] atLineNumber:__LINE__];
                    [self mountPointCreationBypass];
                }
            } else {
                [self errorAlert:@"Please delete the file located at /private/var/mnt/divise/" atLineNumber:__LINE__];
            }
        }
    } else {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:@"/private/var/mnt/divise/" withIntermediateDirectories:TRUE attributes:nil error:&error];
        if (!error) {
            [self attachDiskImage];
        } else {
            [self logToFile:[NSString stringWithFormat:@"Got %@ when trying to create mountpoint, using bypass.", [error localizedDescription]] atLineNumber:__LINE__];
            [self mountPointCreationBypass];
        }
    }
}

-(void)mountPointCreationBypass{
    NSError *error;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self titleLabel] setText:@"Using bypass technique to create mountpoint..."];
    });
    [[NSFileManager defaultManager] removeItemAtPath:@"/private/var/COPY/" error:nil];
    [self logToFile:@"Using bypass technique to create mountpoint..." atLineNumber:__LINE__];
    [[NSFileManager defaultManager] createDirectoryAtPath:@"/private/var/COPY/mnt1" withIntermediateDirectories:TRUE attributes:nil error:&error];
    if (!error) {
        NSArray *contentsOfMSU = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/private/var/MobileSoftwareUpdate/" error:&error];
        if (!error) {
            for (NSString *file in contentsOfMSU) {
                NSString *filePath = [NSString stringWithFormat:@"/private/var/MobileSoftwareUpdate/%@", file];
                [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:[NSString stringWithFormat:@"/private/var/COPY/%@", file] error:&error];
                if (error) {
                    [self errorAlert:[NSString stringWithFormat:@"Failed to copy file %@ to COPY directory", file] atLineNumber:__LINE__];
                }
                [[NSFileManager defaultManager] createDirectoryAtPath:@"/private/var/COPY/mnt1" withIntermediateDirectories:TRUE attributes:nil error:&error];
                if (!error) {
                    [[NSFileManager defaultManager] removeItemAtPath:@"/private/var/MobileSoftwareUpdate/" error:&error];
                    if (!error) {
                        [[NSFileManager defaultManager] moveItemAtPath:@"/private/var/COPY/" toPath:@"/private/var/MobileSoftwareUpdate/" error:&error];
                        if (!error) {
                            [self logToFile:@"Successfully exploited mountpoint creation, continuing" atLineNumber:__LINE__];
                            [self attachDiskImage];
                        } else {
                            [self errorAlert:@"Failed to rename COPY directory to MSU" atLineNumber:__LINE__];
                        }
                    } else {
                        [self errorAlert:@"Failed to remove old MSU directory" atLineNumber:__LINE__];
                    }
                } else {
                    [self errorAlert:@"Failed to create mnt1 in COPY directory" atLineNumber:__LINE__];
                }
            }
        } else {
            [self errorAlert:[NSString stringWithFormat:@"Failed to list contents of /private/var/MobileSoftwareUpdate"] atLineNumber:__LINE__];
        }
    } else {
        [self errorAlert:[NSString stringWithFormat:@"Failed to create /private/var/COPY/mnt1, %@", [error localizedDescription]] atLineNumber:__LINE__];
    }
    
    
}

-(void)attachDiskImage{
    [self logToFile:@"attachDiskImage called!" atLineNumber:__LINE__];
    NSArray *beforeAttachDevContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/" error:nil];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSString stringWithFormat:@"%@", [[NSBundle mainBundle] bundlePath]] stringByAppendingPathComponent:@"hdik"]]) {
        [self logToFile:@"using hdik to attach disk image" atLineNumber:__LINE__];
        NSTask *hdikTask = [[NSTask alloc] init];
        NSArray *hdikArgs;
        NSString *version = [[UIDevice currentDevice] systemVersion];
        
        if ([version containsString:@"10."]) { // Avoid using succdatroot on iOS 10 as we run Divse as root to avoid succdatroot being broken on 10.x
            [hdikTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hdik"]];
            hdikArgs = [NSArray arrayWithObjects: @"/private/var/mobile/Media/Divise/rfs.dmg", nil];
        } else {
            [hdikTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
            hdikArgs = [NSArray arrayWithObjects:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hdik"], @"/private/var/mobile/Media/Divise/rfs.dmg", nil];
        }
        [hdikTask setArguments:hdikArgs];
        [self logToFile:[NSString stringWithFormat:@"/Applications/Divisé.app/succdatroot %@", [hdikArgs componentsJoinedByString:@" "]] atLineNumber:__LINE__];
        NSPipe *stdOutPipe = [NSPipe pipe];
        NSFileHandle *outPipeRead = [stdOutPipe fileHandleForReading];
        [hdikTask setStandardOutput:stdOutPipe];
        [hdikTask setStandardError:stdOutPipe];
        hdikTask.terminationHandler = ^{
            NSData *outData = [outPipeRead readDataToEndOfFile];
            NSString *outString = [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
            [self logToFile:[NSString stringWithFormat:@"hdik completed with\n%@",outString] atLineNumber:__LINE__];
            if ([outString containsString:@"disk"]) {
                NSArray *outLines = [outString componentsSeparatedByString:[NSString stringWithFormat:@"\n"]];
                [self logToFile:[outLines componentsJoinedByString:@",\n"] atLineNumber:__LINE__];
                [self logToFile:[NSString stringWithFormat:@"outlines count: %lu", (unsigned long)[outLines count]] atLineNumber:__LINE__];
                if ([outLines count] > 1) {
                    for (NSString *line in outLines) {
                        [self logToFile:[NSString stringWithFormat:@"current line is %@", line]  atLineNumber:__LINE__];
                        if ([line containsString:@"s2"]) {
                            [self logToFile:[NSString stringWithFormat:@"found attached diskpath in %@", line] atLineNumber:__LINE__];
                            NSArray *lineWords = [line componentsSeparatedByString:@" "];
                            for (NSString *word in lineWords) {
                                if ([word hasPrefix:@"/dev/disk"]) {
                                    [self logToFile:[NSString stringWithFormat:@"found attached diskpath %@", word] atLineNumber:__LINE__];
                                    [self prepareMountAttachedDisk:word];
                                    break;
                                }
                            }
                        }
                    }
                } else {
                    NSString *diskPath = [outLines firstObject];
                    [self logToFile:[NSString stringWithFormat:@"found attached diskpath %@", diskPath] atLineNumber:__LINE__];
                    [self prepareMountAttachedDisk:diskPath];
                }
            } else if ([outString containsString:@"must be run by root"]) {
                [self logToFile:[NSString stringWithFormat:@"I am: %d", getuid()] atLineNumber:__LINE__];
                pid_t pid;
                int i;
                const char* args[] = {"hdik", "/var/mobile/Media/Divise/rfs.dmg", NULL};
                posix_spawn(&pid, "/Applications/Divisé.app/hdik", NULL, NULL, (char* const*)args, NULL);
                waitpid(pid, &i, 0);
                NSMutableArray *changedDevContents = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/" error:nil]];
                [changedDevContents removeObjectsInArray:beforeAttachDevContents];
                [self logToFile:[NSString stringWithFormat:@"changedDevContents: %@", [changedDevContents componentsJoinedByString:@" "]] atLineNumber:__LINE__];
                if ([[changedDevContents componentsJoinedByString:@" "] containsString:@"s2"]) {
                    for (NSString *attachedDisk in changedDevContents) {
                        if (![attachedDisk containsString:@"r"]) {
                            if ([attachedDisk containsString:@"s2"]) {
                                NSString *diskPath = [NSString stringWithFormat:@"/dev/%@", attachedDisk];
                                [self logToFile:[NSString stringWithFormat:@"found attached diskpath %@", diskPath] atLineNumber:__LINE__];
                                [self prepareMountAttachedDisk:diskPath];
                            }
                        }
                    }
                } else {
                    for (NSString *attachedDisk in changedDevContents) {
                        if ([attachedDisk hasPrefix:@"disk"]) {
                            NSString *diskPath = [NSString stringWithFormat:@"/dev/%@", attachedDisk];
                            [self logToFile:[NSString stringWithFormat:@"found attached diskpath %@", diskPath] atLineNumber:__LINE__];
                            [self prepareMountAttachedDisk:diskPath];
                        }
                    }
                }
            } else {
                NSMutableArray *changedDevContents = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/" error:nil]];
                [changedDevContents removeObjectsInArray:beforeAttachDevContents];
                [self logToFile:[NSString stringWithFormat:@"changedDevContents: %@", [changedDevContents componentsJoinedByString:@" "]] atLineNumber:__LINE__];
                if ([[changedDevContents componentsJoinedByString:@" "] containsString:@"s2"]) {
                    for (NSString *attachedDisk in changedDevContents) {
                        if (![attachedDisk containsString:@"r"]) {
                            if ([attachedDisk containsString:@"s2"]) {
                                NSString *diskPath = [NSString stringWithFormat:@"/dev/%@", attachedDisk];
                                [self logToFile:[NSString stringWithFormat:@"found attached diskpath %@", diskPath] atLineNumber:__LINE__];
                                [self prepareMountAttachedDisk:diskPath];
                            }
                        }
                    }
                } else {
                    for (NSString *attachedDisk in changedDevContents) {
                        if ([attachedDisk hasPrefix:@"disk"]) {
                            NSString *diskPath = [NSString stringWithFormat:@"/dev/%@", attachedDisk];
                            [self logToFile:[NSString stringWithFormat:@"found attached diskpath %@", diskPath] atLineNumber:__LINE__];
                            [self prepareMountAttachedDisk:diskPath];
                        }
                    }
                }
            }
        };
        [hdikTask launch];
        [hdikTask waitUntilExit];
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"attach"]]) {
        [self logToFile:@"Using comex attach for attach" atLineNumber:__LINE__];
        NSTask *attachTask = [[NSTask alloc] init];
        [attachTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
        NSArray *attachArgs = [NSArray arrayWithObjects:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"attach"], @"/private/var/mobile/Media/Divise/rfs.dmg", nil];
        [attachTask setArguments:attachArgs];
        NSPipe *stdOutPipe = [NSPipe pipe];
        NSFileHandle *outPipeRead = [stdOutPipe fileHandleForReading];
        [attachTask setStandardOutput:stdOutPipe];
        [attachTask setStandardError:stdOutPipe];
        [attachTask launch];
        [attachTask waitUntilExit];
        NSData *outData = [outPipeRead readDataToEndOfFile];
        NSString *outString = [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
        [self logToFile:[NSString stringWithFormat:@"attach output is: %@", outString] atLineNumber:__LINE__];
        if ([outString containsString:@"disk"]) {
            NSArray *outLines = [outString componentsSeparatedByString:[NSString stringWithFormat:@"\n"]];
            [self logToFile:[NSString stringWithFormat:@"%@\n\n%lu", [outLines componentsJoinedByString:@", "], (unsigned long)[outLines count]] atLineNumber:__LINE__];
            if ([outLines count] != 2) {
                for (NSString *line in outLines) {
                    [self logToFile:[NSString stringWithFormat:@"current line is %@", line]  atLineNumber:__LINE__];
                    if ([line containsString:@"s3"]) {
                        NSString *theDiskString;
                        [self logToFile:[NSString stringWithFormat:@"found attached diskname %@", line] atLineNumber:__LINE__];
                        if (![line hasPrefix:@"/dev/"]) {
                            theDiskString = [NSMutableString stringWithString:[NSString stringWithFormat:@"/dev/%@", line]];
                        } else {
                            theDiskString = line;
                        }
                        [self logToFile:[NSString stringWithFormat:@"sending %@ to mountRestoreDisk", theDiskString] atLineNumber:__LINE__];
                        [self prepareMountAttachedDisk:line];
                    }
                }
            } else {
                NSString *diskName = [outLines firstObject];
                [self logToFile:[NSString stringWithFormat:@"found attached diskname %@", diskName] atLineNumber:__LINE__];
                NSString *theDiskString;
                if (![diskName hasPrefix:@"/dev/"]) {
                    theDiskString = [NSMutableString stringWithString:[NSString stringWithFormat:@"/dev/%@", diskName]];
                } else {
                    theDiskString = diskName;
                }
                [self logToFile:[NSString stringWithFormat:@"sending %@ to mountRestoreDisk", theDiskString] atLineNumber:__LINE__];
                [self prepareMountAttachedDisk:theDiskString];
            }
        } else {
            NSMutableArray *changedDevContents = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/" error:nil]];
            [changedDevContents removeObjectsInArray:beforeAttachDevContents];
            [self logToFile:[NSString stringWithFormat:@"changedDevContents: %@", [changedDevContents componentsJoinedByString:@" "]] atLineNumber:__LINE__];
            if ([[changedDevContents componentsJoinedByString:@" "] containsString:@"s2"]) {
                for (NSString *attachedDisk in changedDevContents) {
                    if (![attachedDisk containsString:@"r"]) {
                        if ([attachedDisk containsString:@"s2"]) {
                            NSString *diskPath = [NSString stringWithFormat:@"/dev/%@", attachedDisk];
                            [self logToFile:[NSString stringWithFormat:@"found attached diskpath %@", diskPath] atLineNumber:__LINE__];
                            [self prepareMountAttachedDisk:diskPath];
                        }
                    }
                }
            } else {
                for (NSString *attachedDisk in changedDevContents) {
                    if ([attachedDisk hasPrefix:@"disk"]) {
                        NSString *diskPath = [NSString stringWithFormat:@"/dev/%@", attachedDisk];
                        [self logToFile:[NSString stringWithFormat:@"found attached diskpath %@", diskPath] atLineNumber:__LINE__];
                        [self prepareMountAttachedDisk:diskPath];
                    }
                }
            }
        }
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hdik-arm64"]] || [[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hdik-arm64e"]] || [[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hdik-armv7"]]) {
        [self errorAlert:@"Succession has not been configured. Please reinstall Succession using Cydia or Zebra. If you installed Succession manually, please extract Succession's postinst script and run it" atLineNumber:__LINE__];
    } else {
        [self errorAlert:@"Succession is missing hdik and attach and cannot continue. Please reinstall Succession using Cydia or Zebra." atLineNumber:__LINE__];
    }
}

-(void)prepareMountAttachedDisk:(NSString *)diskPath{
    [self logToFile:@"prepareMountAttachedDisk called!" atLineNumber:__LINE__];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self titleLabel] setText:@"Identifying filesystem type..."];
    });
    NSError *error;
    NSString *fstabString = [NSString stringWithContentsOfFile:@"/private/etc/fstab" encoding:NSUTF8StringEncoding error:&error];
    if (!error) {
        if ([fstabString containsString:@"apfs"]) {
            [self logToFile:@"Identified filesystem as APFS!" atLineNumber:__LINE__];
            _filesystemType = @"apfs";
            [self mountAttachedDisk:diskPath ofType:@"apfs"];
        } else if ([fstabString containsString:@"hfs"]){
            [self logToFile:@"Identified filesystem as HFS!" atLineNumber:__LINE__];
            _filesystemType = @"hfs";
            [self mountAttachedDisk:diskPath ofType:@"hfs"];
        } else {
            [self errorAlert:[NSString stringWithFormat:@"Failed to identify filesystem, read fstab successfully, but fstab did not contain filesystem type: %@", fstabString] atLineNumber:__LINE__];
        }
    } else {
        [self errorAlert:[NSString stringWithFormat:@"Failed to read fstab: %@", [error localizedDescription]] atLineNumber:__LINE__];
    }
}

-(void)mountAttachedDisk:(NSString *)diskPath ofType:(NSString *)filesystemType{
    if ([[self->_divisePrefs objectForKey:@"dualboot"] isEqual:@(1)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self titleLabel] setText:@"Creating New System Partition..."];
            [[self subtitleLabel] setText:@"This won't take long."];
        });
        [self devdiskStuff];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self titleLabel] setText:@"Mounting Filesystem..."];
        [[self subtitleLabel] setText:@"This should take less than 10 seconds."];
    });
    NSTask *mountTask = [[NSTask alloc] init];
    NSArray *mountArgs;
    NSString *version = [[UIDevice currentDevice] systemVersion];
    
    if ([version containsString:@"10."]) { // Avoid using succdatroot on iOS 10 as we run Divse as root to avoid succdatroot being broken on 10.x
        [mountTask setLaunchPath:@"/sbin/mount"];
        mountArgs = [NSArray arrayWithObjects: @"-t", filesystemType, @"-o", @"ro", diskPath, @"/private/var/mnt/divise", nil];
    } else {
        [mountTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
        mountArgs = [NSArray arrayWithObjects:@"mount", @"-t", filesystemType, @"-o", @"ro", diskPath, @"/private/var/mnt/divise", nil];
    }
    [mountTask setArguments:mountArgs];
    NSPipe *stdOutPipe = [NSPipe pipe];
    NSFileHandle *stdOutFileRead = [stdOutPipe fileHandleForReading];
    mountTask.terminationHandler = ^{
        NSData *outData = [stdOutFileRead readDataToEndOfFile];
        NSString *outString = [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
        [self logToFile:[NSString stringWithFormat:@"mounting complete! %@", outString] atLineNumber:__LINE__];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self titleLabel] setText:@"WARNING!!!"];
            [[self subtitleLabel] setText:@"Running this tool will immediately delete all data from your device. Please make a backup of any data that you want to keep. This will also return your device to the setup screen.  A valid SIM card may be needed for activation on iPhones and cellular iPads."];
            if ([[self->_divisePrefs objectForKey:@"dualboot"] isEqual:@(1)]) {
                [[self eraseButton] setTitle:[NSString stringWithFormat:@"Dualboot %@", self->_deviceType] forState:UIControlStateNormal];
            } else {
                [[self eraseButton] setTitle:[NSString stringWithFormat:@"Downgrade %@", self->_deviceType] forState:UIControlStateNormal];
            }
            [[self eraseButton] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [[self eraseButton] setEnabled:TRUE];
            [[self outputLabel] setHidden:TRUE];
            [[self progressIndicator] setHidden:TRUE];
            [[self restoreProgressBar] setHidden:TRUE];
        });
    };
    [mountTask launch];
    [mountTask waitUntilExit];
}

-(void)devdiskStuff {
    
    BOOL isDir;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:@"/mnt1" isDirectory:&isDir])
        if(![fileManager createDirectoryAtPath:@"/mnt1" withIntermediateDirectories:YES attributes:nil error:NULL])
            [self logToFile:@"Failed to create /mnt1" atLineNumber:__LINE__];
    
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/"
                                                                        error:NULL];
    NSArray *firstCheck = [files filteredArrayUsingPredicate:
                                        [NSPredicate predicateWithFormat:@"self BEGINSWITH[cd] 'disk0s1s'"]]; // Creates an NSArray with all the disk0s1sX's to be compared against later
    [self logToFile:[NSString stringWithFormat:@"%@", firstCheck] atLineNumber:__LINE__];
    // Now need to create new APFS Volume
    NSArray *sortedArray1 = [firstCheck sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSTask *createAPFSVolume = [[NSTask alloc] init];
    NSString *iOSversion = [[UIDevice currentDevice] systemVersion];
    iOSversion = [NSString stringWithFormat:@"%@", iOSversion];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/testMount.txt"] ) {
        // Test if something is already mounted to /mnt1, sometimes iOS 11/12 double creates SystemB
        [self logToFile:@"Avoided iOS 11/12 double creation issue thing :)" atLineNumber:__LINE__];
        [[NSFileManager defaultManager] removeItemAtPath:@"/testMount.txt" error:nil];
    } else {
        
        [self logToFile:@"Looks like this is the first run! :)" atLineNumber:__LINE__];
        
        if ([iOSversion rangeOfString:@"13."].location == NSNotFound) {
            NSArray *createAPFSVolumeARGS;
            NSString *version = [[UIDevice currentDevice] systemVersion];
            
            if ([version containsString:@"10."]) { // Avoid using succdatroot on iOS 10 as we run Divse as root to avoid succdatroot being broken on 10.x
                [createAPFSVolume setLaunchPath:@"/System/Library/Filesystems/apfs.fs/newfs_apfs"];
                createAPFSVolumeARGS = [NSArray arrayWithObjects: @"-A", @"-v", @"SystemB", @"/dev/disk0s1", nil];
            } else {
                [createAPFSVolume setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
                createAPFSVolumeARGS = [NSArray arrayWithObjects:@"newfs_apfs", @"-A", @"-v", @"SystemB", @"/dev/disk0s1", nil];
            }
            [createAPFSVolume setArguments:createAPFSVolumeARGS];
        } else {
            // Only 13.x needs the role= flag set, no need to do so on lower versions
            [createAPFSVolume setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
            NSArray *createAPFSVolumeARGS = [NSArray arrayWithObjects:@"newfs_apfs", @"-o", @"role=r", @"-A", @"-v", @"SystemB", @"/dev/disk0s1", nil];
            [createAPFSVolume setArguments:createAPFSVolumeARGS];
        }
        createAPFSVolume.terminationHandler = ^{
            sleep(2);
                
        };
        [createAPFSVolume launch];
        [createAPFSVolume waitUntilExit];
        
        NSString *content = @"ios 12 is doodoo";
        NSData *fileContents = [content dataUsingEncoding:NSUTF8StringEncoding];
        [[NSFileManager defaultManager] createFileAtPath:@"/testMount.txt"
                                        contents:fileContents
                                        attributes:nil];
        
        NSArray *files2 = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/"
                                                                              error:NULL];
        NSArray *secondCheck = [files2 filteredArrayUsingPredicate:
                                [NSPredicate predicateWithFormat:@"self BEGINSWITH[cd] 'disk0s1s'"]]; // Creates another NSArray with the newly added volume so we can get what the filename is by comparing to the first array
        NSArray *sortedArray2 = [secondCheck sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        NSString *diskpath;
        [self logToFile:[NSString stringWithFormat:@"%@", secondCheck] atLineNumber:__LINE__];
        if ([sortedArray1 lastObject] != [sortedArray2 lastObject])
        {
            diskpath = [sortedArray2 lastObject]; // Save said filename to diskpath string to be used in mounting to /mnt1
            [@"/dev/" stringByAppendingString:diskpath];
            [self logToFile:[NSString stringWithFormat:@"New APFS is located at %@!", diskpath] atLineNumber:__LINE__];
            NSTask *mountPart2Task = [[NSTask alloc] init];
            NSArray *mountPart2Args;
            NSString *version = [[UIDevice currentDevice] systemVersion];
            
            if ([version containsString:@"10."]) { // Avoid using succdatroot on iOS 10 as we run Divse as root to avoid succdatroot being broken on 10.x
                [mountPart2Task setLaunchPath:@"/System/Library/Filesystems/apfs.fs/mount_apfs"];
                mountPart2Args = [NSArray arrayWithObjects: diskpath, @"/mnt1", nil];
            } else {
                [mountPart2Task setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
                mountPart2Args = [NSArray arrayWithObjects:@"mount_apfs", diskpath, @"/mnt1", nil];
            }
            
            [mountPart2Task setArguments:mountPart2Args];
            mountPart2Task.terminationHandler = ^{
               [self logToFile:@"Mount task finished" atLineNumber:__LINE__];
               [self logToFile:@"post popup" atLineNumber:__LINE__];
            };
            [mountPart2Task launch];
            [mountPart2Task waitUntilExit];
        } else {
             [self logToFile:@"Something went wrong!" atLineNumber:__LINE__];
        }
        
    }
    
}

- (IBAction)tappedRestoreButton:(id)sender {
    [self logToFile:@"tappedRestoreButton called" atLineNumber:__LINE__];
    
    if ([[_divisePrefs objectForKey:@"create_APFS_succession-prerestore"] isEqual:@(1)] || [[_divisePrefs objectForKey:@"create_APFS_orig-fs"] isEqual:@(1)]) {
        [self logToFile:@"snappy operations enabled" atLineNumber:__LINE__];
        if (kCFCoreFoundationVersionNumber >= 1349.56) {
            [self logToFile:@"ios version compatible with snappy" atLineNumber:__LINE__];
            if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/snappy"]) {
                [self logToFile:@"snappy not installed, asking to install it" atLineNumber:__LINE__];
                UIAlertController *needSnappy = [UIAlertController alertControllerWithTitle:@"Snappy required" message:@"Your current preferences indicate you would like to perform operations with APFS snapshots, but you do not have snappy installed. Please install snappy from https://repo.bingner.com" preferredStyle:UIAlertControllerStyleAlert];
                NSString *sources = [NSString stringWithContentsOfFile:@"/etc/apt/sources.list.d/cydia.list" encoding:NSUTF8StringEncoding error:nil];
                if (![sources containsString:@"bingner.com"]) {
                    UIAlertAction *addRepo = [UIAlertAction actionWithTitle:@"Add repository to cydia" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        if (@available(iOS 10.0, *)) {
                            NSDictionary *URLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly : @FALSE};
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://cydia.saurik.com/api/share#?source=https://repo.bingner.com/"] options:URLOptions completionHandler:nil];
                        } else {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://cydia.saurik.com/api/share#?source=https://repo.bingner.com/"]];
                        }
                        [self logToFile:@"user adding source for snappy" atLineNumber:__LINE__];
                    }];
                    [needSnappy addAction:addRepo];
                }
                UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
                [needSnappy addAction:dismissAction];
                [self presentViewController:needSnappy animated:TRUE completion:nil];
            } else {
                [self logToFile:@"snappy requested and already installed" atLineNumber:__LINE__];
                [self showRestoreAlert];
            }
        } else {
            [self logToFile:@"apfs snapshot operations enabled, but iOS version not compatible with snappy" atLineNumber:__LINE__];
            UIAlertController *snapshotsNotSupported = [UIAlertController alertControllerWithTitle:@"APFS operations not supported" message:@"You must be running iOS 10.3 or higher to use APFS features." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismis" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self logToFile:@"user disabled snappy options" atLineNumber:__LINE__];
                [self->_divisePrefs setObject:@(0) forKey:@"create_APFS_orig-fs"];
                [self->_divisePrefs setObject:@(0) forKey:@"create_APFS_succession-prerestore"];
                [[NSFileManager defaultManager] removeItemAtPath:@"/private/var/mobile/Library/Preferences/com.moski.Divise.plist" error:nil];
                [self->_divisePrefs writeToFile:@"/private/var/mobile/Library/Preferences/com.moski.Divise.plist" atomically:TRUE];
                [[self navigationController] popToRootViewControllerAnimated:TRUE];
            }];
            [snapshotsNotSupported addAction:dismissAction];
            [self presentViewController:snapshotsNotSupported animated:TRUE completion:nil];
        }
    } else {
        [self logToFile:@"no apfs snapshot operations requested" atLineNumber:__LINE__];
        if ([[self->_divisePrefs objectForKey:@"dualboot"] isEqual:@(1)]) {
            [self logToFile:@"Making sure user is aware they are dualbooting" atLineNumber:__LINE__];
            NSString *title = [NSString stringWithFormat:@"You are about to dualboot your device"];
            UIAlertController *alertController2 = [UIAlertController alertControllerWithTitle:title message:@"Please verify that you want to dualboot your device" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self showRestoreAlert];
                }];
            [alertController2 addAction:confirmAction];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                exit(0);
            }];
            [alertController2 addAction:cancel];
            [self presentViewController:alertController2 animated:YES completion:nil];
        } else {
         [self showRestoreAlert];
        }
    }
}

- (void)showRestoreAlert{
    [self logToFile:@"showRestoreAlert called!" atLineNumber:__LINE__];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/private/var/mnt/divise/sbin/launchd"]]) {
        [self logToFile:@"filesystem is mounted, asking user to confirm they are ready to restore" atLineNumber:__LINE__];
        if ([_deviceModel containsString:@"iPad"]) {
            _areYouSureAlert = [UIAlertController alertControllerWithTitle:@"Are you sure you would like to begin restoring" message:@"You will not be able to leave the app during the process" preferredStyle:UIAlertControllerStyleAlert];
        } else {
            _areYouSureAlert = [UIAlertController alertControllerWithTitle:@"Are you sure you would like to begin restoring" message:@"You will not be able to leave the app during the process" preferredStyle:UIAlertControllerStyleActionSheet];
        }
        NSString *title;
        if ([[self->_divisePrefs objectForKey:@"dualboot"] isEqual:@(1)]) {
            title = @"Begin Dualboot";
            
        }
        else {
            title = @"Begin Restore";
        }
        
        UIAlertAction *beginRestore = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self logToFile:@"user wants to begin restore now, checking battery level" atLineNumber:__LINE__];
            [[UIDevice currentDevice] setBatteryMonitoringEnabled:TRUE];
            if ([[UIDevice currentDevice] batteryLevel] > 0.5) {
                if (@available(iOS 9.0, *)) {
                    if ([[NSProcessInfo processInfo] isLowPowerModeEnabled]) {
                        UIAlertController *disableLowPowerMode = [UIAlertController alertControllerWithTitle:@"Low Power Mode enabled" message:@"Low Power Mode causes your device to auto-lock after 30 seconds, please go to settings and turn that off." preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"I've turned it off, start restoring" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        
                            [self beginRestore];
                        }];
                        [disableLowPowerMode addAction:okAction];
                        [self presentViewController:disableLowPowerMode animated:TRUE completion:nil];
                    } else {
                        [self logToFile:[NSString stringWithFormat:@"battery level is %f which is greater than 50%%, ready to go", [[UIDevice currentDevice] batteryLevel]] atLineNumber:__LINE__];
                        [self beginRestore];
                    }
                } else {
                    [self logToFile:[NSString stringWithFormat:@"battery level is %f which is greater than 50%%, ready to go", [[UIDevice currentDevice] batteryLevel]] atLineNumber:__LINE__];
                    [self beginRestore];
                }
            } else {
                [self logToFile:[NSString stringWithFormat:@"battery is %f which is less than 50%%, warning user", [[UIDevice currentDevice] batteryLevel]] atLineNumber:__LINE__];
                UIAlertController *lowBatteryWarning = [UIAlertController alertControllerWithTitle:@"Low Battery" message:@"It is recommended you have at least 50% battery charge before beginning restore" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelRestoreAction = [UIAlertAction actionWithTitle:@"Abort restore" style:UIAlertActionStyleDefault handler:nil];
                UIAlertAction *startRestoreAction = [UIAlertAction actionWithTitle:@"Restore anyways" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    if (@available(iOS 9.0, *)) {
                        if ([[NSProcessInfo processInfo] isLowPowerModeEnabled]) {
                            UIAlertController *disableLowPowerMode = [UIAlertController alertControllerWithTitle:@"Low Power Mode enabled" message:@"Low Power Mode causes your device to auto-lock after 30 seconds, please go to settings and turn that off." preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"I've turned it off, start restoring" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                [self beginRestore];
                            }];
                            [disableLowPowerMode addAction:okAction];
                            [self presentViewController:disableLowPowerMode animated:TRUE completion:nil];
                        } else {
                            [self logToFile:@"user chose to override battery warning, restoring now" atLineNumber:__LINE__];
                            [self beginRestore];
                        }
                    } else {
                        [self logToFile:@"user chose to override battery warning, restoring now" atLineNumber:__LINE__];
                        [self beginRestore];
                    }
                }];
                [lowBatteryWarning addAction:cancelRestoreAction];
                [lowBatteryWarning addAction:startRestoreAction];
                [self presentViewController:lowBatteryWarning animated:TRUE completion:nil];
            }
            [[UIDevice currentDevice] setBatteryMonitoringEnabled:FALSE];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [_areYouSureAlert addAction:beginRestore];
        [_areYouSureAlert addAction:cancelAction];
        [self presentViewController:_areYouSureAlert animated:TRUE completion:nil];
    } else {
        [self errorAlert:@"Can't restore, filesystem isn't mounted." atLineNumber:__LINE__];
    }
}

- (void)beginRestore{
    [self logToFile:@"beginRestore called!" atLineNumber:__LINE__];
    
    [self->_backButtonH setEnabled:FALSE];
    [self->_backButtonH setBackgroundColor:[UIColor darkGrayColor]];
    [self->_backButtonH setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        [self.navigationController.view removeGestureRecognizer:self.navigationController.interactivePopGestureRecognizer];
    }
    if ([[self->_divisePrefs objectForKey:@"create_APFS_succession-prerestore"] isEqual:@(1)]) {
        NSTask *deletePreviousBackupSnapTask = [[NSTask alloc] init];
        [deletePreviousBackupSnapTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
        NSArray *deletePreviousBackupSnapTaskArgs = [[NSArray alloc] initWithObjects:@"snappy", @"-f", @"/", @"-d", @"succession-prerestore", nil];
        [deletePreviousBackupSnapTask setArguments:deletePreviousBackupSnapTaskArgs];
        [self logToFile:@"user elected to create succession-prerestore snapshot, deleting already present succession-prerestore" atLineNumber:__LINE__];
        [deletePreviousBackupSnapTask launch];
        [deletePreviousBackupSnapTask waitUntilExit];
        NSTask *createBackupSnapTask = [[NSTask alloc] init];
        [createBackupSnapTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
        NSArray *createBackupSnapTaskArgs = [[NSArray alloc] initWithObjects:@"snappy", @"-f", @"/", @"-c", @"succession-prerestore", nil];
        [createBackupSnapTask setArguments:createBackupSnapTaskArgs];
        [self logToFile:@"creating new succession-prerestore" atLineNumber:__LINE__];
        [createBackupSnapTask launch];
        [createBackupSnapTask waitUntilExit];
    }
    [self DiviseRestore];
}

-(void)postRestore{
    // Change labels and stuff for post restore tasks
    [self->_during1 setHidden:TRUE];
    [self->_during2 setHidden:TRUE];
    [self->_during3 setHidden:TRUE];
    [self->_done1 setHidden:FALSE];
    [self->_done2 setHidden:FALSE];
    [self->_done3 setHidden:FALSE];
    [self->_subtitleLabel setHidden:TRUE];
    [self->_restoreProgressBar setHidden:TRUE];
    [self->_titleLabel setHidden:TRUE];
    [self->_spinningThing setHidden:FALSE];
    
    [self logToFile:@"Starting post restore things" atLineNumber:__LINE__];
    
    BOOL isDir;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:@"/mnt2" isDirectory:&isDir])
        if(![fileManager createDirectoryAtPath:@"/mnt2" withIntermediateDirectories:YES attributes:nil error:NULL])
            [self logToFile:@"Failed to create /mnt2" atLineNumber:__LINE__];
    
    NSTask *createAPFSDataVolume = [[NSTask alloc] init];
    NSString *iOSversion = [[UIDevice currentDevice] systemVersion];
    iOSversion = [NSString stringWithFormat:@"%@", iOSversion];
    [createAPFSDataVolume setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
    if ([iOSversion rangeOfString:@"13."].location == NSNotFound) {
        
        NSArray *createAPFSVolumeARGS;
        NSString *version = [[UIDevice currentDevice] systemVersion];
        
        if ([version containsString:@"10."]) { // Avoid using succdatroot on iOS 10 as we run Divse as root to avoid succdatroot being broken on 10.x
            [createAPFSDataVolume setLaunchPath:@"/System/Library/Filesystems/apfs.fs/newfs_apfs"];
            createAPFSVolumeARGS = [NSArray arrayWithObjects: @"-A", @"-v", @"DataB", @"/dev/disk0s1", nil];
        } else {
            [createAPFSDataVolume setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
            createAPFSVolumeARGS = [NSArray arrayWithObjects:@"newfs_apfs", @"-A", @"-v", @"DataB", @"/dev/disk0s1", nil];
        }
        [createAPFSDataVolume setArguments:createAPFSVolumeARGS];
        
    } else {
        // Only 13.x needs the role= flag set, no need to do so on lower versions
        NSArray *createAPFSVolumeARGS = [NSArray arrayWithObjects:@"newfs_apfs", @"-o", @"role=0", @"-A", @"-v", @"DataB", @"/dev/disk0s1", nil];
        [createAPFSDataVolume setArguments:createAPFSVolumeARGS];
    }
    
    
    [self logToFile:@"Created new data partition" atLineNumber:__LINE__];
    sleep(10);
    [createAPFSDataVolume launch];
    [createAPFSDataVolume waitUntilExit];
    // Now need to create new APFS Volume
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/"
                                                                        error:NULL];
    NSArray *firstCheck = [files filteredArrayUsingPredicate:
    [NSPredicate predicateWithFormat:@"self BEGINSWITH[cd] 'disk0s1s'"]]; // Creates an NSArray with all the disk0s1sX's to be compared against later
    NSArray *sortedArray1 = [firstCheck sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    NSArray *devdisklist = [files filteredArrayUsingPredicate:
                                        [NSPredicate predicateWithFormat:@"self BEGINSWITH[cd] 'disk0s1s'"]];
    int devdisknum = [devdisklist count];
    NSString *datapartName = [NSString stringWithFormat:@"/dev/disk0s1s%d", devdisknum];
    [self logToFile:@"Got data part thing" atLineNumber:__LINE__];
    // Copy things over from main part to new partition
    NSArray *files2 = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/"
                                                                          error:NULL];
    NSArray *secondCheck = [files2 filteredArrayUsingPredicate:
                            [NSPredicate predicateWithFormat:@"self BEGINSWITH[cd] 'disk0s1s'"]]; // Creates another NSArray with the newly added volume so we can get what the filename is by comparing to the first array
    NSArray *sortedArray2 = [secondCheck sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSString *diskpath;
    [self logToFile:[NSString stringWithFormat:@"%@", secondCheck] atLineNumber:__LINE__];
    diskpath = [sortedArray2 lastObject]; // Save said filename to diskpath string to be used in mounting to /mnt2
    [@"/dev/" stringByAppendingString:diskpath];
    [self logToFile:[NSString stringWithFormat:@"New APFS is located at %@!", diskpath] atLineNumber:__LINE__];
    NSTask *mountPart2Task = [[NSTask alloc] init];
    
    NSArray *mountPart2Args;
    NSString *version = [[UIDevice currentDevice] systemVersion];
    
    if ([version containsString:@"10."]) { // Avoid using succdatroot on iOS 10 as we run Divse as root to avoid succdatroot being broken on 10.x
        [mountPart2Task setLaunchPath:@"/System/Library/Filesystems/apfs.fs/mount_apfs"];
        mountPart2Args = [NSArray arrayWithObjects: diskpath, @"/mnt2", nil];
    } else {
        [mountPart2Task setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
        mountPart2Args = [NSArray arrayWithObjects:@"mount_apfs", diskpath, @"/mnt2", nil];
    }
    [mountPart2Task setArguments:mountPart2Args];
    mountPart2Task.terminationHandler = ^{
       [self logToFile:@"Mount task finished" atLineNumber:__LINE__];
       [self logToFile:@"post popup" atLineNumber:__LINE__];
    };
    [mountPart2Task launch];
    [mountPart2Task waitUntilExit];

    [self logToFile:@"Mounted new data partition" atLineNumber:__LINE__];
    // Write info to disk for later use :)
    // Writing SystemB disk identifier
    [self->_dualbootPrefs setObject:[NSString stringWithFormat:@"disk0s1s%d", devdisknum - 1] forKey:@"SystemB"];
    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" error:nil];
    [self->_dualbootPrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" atomically:TRUE];
    // Writing DataB disk identifier
    [self->_dualbootPrefs setObject:[NSString stringWithFormat:@"disk0s1s%d", devdisknum] forKey:@"DataB"];
    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" error:nil];
    [self->_dualbootPrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" atomically:TRUE];
    // Writng 1 to dualbooted so info will show on main page later :)
    [self->_dualbootPrefs setObject:@(1) forKey:@"dualbooted"];
    [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" error:nil];
    [self->_dualbootPrefs writeToFile:@"/var/mobile/Library/Preferences/com.moski.dualboot.plist" atomically:TRUE];
    
    // Time to move all the required files and to make the partitions bootable!
    
    NSString *dualbootedSystemB = [_dualbootPrefs objectForKey:@"SystemB"];
    NSString *dualbootedDataB = [_dualbootPrefs objectForKey:@"DataB"];
    
    [[self titleLabel] setText:@"Moving Files, please wait..."];
    [[self subtitleLabel] setText:@"Currently moving SEP..."];
    
    [[NSFileManager defaultManager] copyItemAtPath:@"/usr/standalone/firmware/sep-firmware.img4" toPath:@"/mnt1/usr/standalone/firmware/sep-firmware.img4" error:nil];
    [[self subtitleLabel] setText:@"Currently copying '/usr/local'..."];
    [[NSFileManager defaultManager] copyItemAtPath:@"/usr/local" toPath:@"/mnt1/usr/local" error:nil];
    [[NSFileManager defaultManager] copyItemAtPath:@"/System/Library/Caches/apticket.der" toPath:@"/mnt1/System/Library/Caches/apticket.der" error:nil];
    NSArray *varFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/mnt1/private/var" error:NULL];
    
    // Copy over /var/mobile/Library/Carrier Bundles/* and OperatorBundles
    
    [[self subtitleLabel] setText:@"Currently moving '/mnt1/private/var'..."];
    int amount = [varFiles count];
    for (int i = 0; i < amount; i++)
    {
        [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"/mnt1/private/var/%@", varFiles[i]] toPath:[NSString stringWithFormat:@"/mnt2/%@", varFiles[i]] error:nil];

    }

    [[NSFileManager defaultManager] removeItemAtPath:@"/mnt1/private/var" error:nil];
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/mnt1/private/var"]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:@"/mnt1/private/var" withIntermediateDirectories:TRUE attributes:nil error:nil];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/mnt1/private/xarts"]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:@"/mnt1/private/xarts" withIntermediateDirectories:TRUE attributes:nil error:nil];
    }
    [[self subtitleLabel] setText:@"Currently copying '/var/keybags'..."];

    [[NSFileManager defaultManager] copyItemAtPath:@"/var/keybags" toPath:@"/mnt2/keybags" error:nil];
    
    // Need to find and copy activation records so second OS will boot (13.x only)
    if ([_installedVersion containsString:@"13."] || [_installedVersion containsString:@"12."]){
        
        NSArray *activationFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/containers/Data/System" error:NULL];
        int amount2 = [activationFiles count];
        // Need to put this for loop in an if statement for 13.x only
        for (int i = 0; i < amount2; i++)
        {
            _activationPlist = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/var/containers/Data/System/%@/.com.apple.mobile_container_manager.metadata.plist", activationFiles[i]]]];
            if ([[_activationPlist objectForKey:@"MCMMetadataIdentifier"] isEqual:@"com.apple.mobileactivationd"]) {
                
                if (![[NSFileManager defaultManager] fileExistsAtPath:@"/mnt2/mobile/Library/mad/activation_records"]) { 
                    [[NSFileManager defaultManager] createDirectoryAtPath:@"/mnt2/mobile/Library/mad/activation_records" withIntermediateDirectories:TRUE attributes:nil error:nil];
                }
                if (![[NSFileManager defaultManager] fileExistsAtPath:@"/mnt2/root/Library/Lockdown/activation_records"]) {
                    [[NSFileManager defaultManager] createDirectoryAtPath:@"/mnt2/root/Library/Lockdown/activation_records" withIntermediateDirectories:TRUE attributes:nil error:nil];
                }
                
                [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"/var/containers/Data/System/%@/Library/activation_records/activation_record.plist", activationFiles[i]] toPath:@"/mnt2/root/Library/Lockdown/activation_records/activation_record.plist" error:nil];
                [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"/var/containers/Data/System/%@/Library/activation_records/activation_record.plist", activationFiles[i]] toPath:@"/mnt2/mobile/Library/mad/activation_records/activation_record.plist" error:nil];
            }
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Carrier Bundles/"]) {
            
            [[NSFileManager defaultManager] copyItemAtPath:@"/var/mobile/Library/Carrier Bundles/" toPath:@"/mnt2/mobile/Library/Carrier Bundles/" error:nil];
            [[NSFileManager defaultManager] copyItemAtPath:@"/var/mobile/Library/CarrierDefault.bundle/" toPath:@"mnt2/mobile/Library/CarrierDefault.bundle/" error:nil];
            
        }
        
        NSArray *varLibrary = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Library/" error:NULL];
        int amount3 = [varLibrary count];
        // Need to put this for loop in an if statement for 13.x only
        for (int i = 0; i < amount3; i++)
        {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/mnt2/mobile/Library/%@", varLibrary[i]]]) {
                // Skip this as it already exist
            } else {
                [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"/var/mobile/Library/%@", varLibrary[i]] toPath:[NSString stringWithFormat:@"/mnt2/mobile/Library/%@", varLibrary[i]] error:nil];
            }
        }
        
        NSTask *apfsutilTask = [[NSTask alloc] init];
        NSArray *apfsutilArgs;
        NSString *version = [[UIDevice currentDevice] systemVersion];
        // apfs.util is what allows rsync dualboots to work, thanks Apple! I found it while digging around trying to find something to do exactly this!
        if ([version containsString:@"10."]) { // Avoid using succdatroot on iOS 10 as we run Divse as root to avoid succdatroot being broken on 10.x
            [apfsutilTask setLaunchPath:@"/System/Library/Filesystems/apfs.fs/apfs.util"];
            apfsutilArgs = [NSArray arrayWithObjects:[NSString stringWithFormat:@"-s /dev/%@", dualbootedSystemB], nil];
        } else {
            [apfsutilTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
            apfsutilArgs = [NSArray arrayWithObjects:@"/System/Library/Filesystems/apfs.fs/apfs.util", [NSString stringWithFormat:@"-s /dev/%@", dualbootedSystemB], nil];
        }
        
        [apfsutilTask setArguments:apfsutilArgs];
        [apfsutilTask launch];
        [apfsutilTask waitUntilExit];
        
        
        NSTask *apfsutil2Task = [[NSTask alloc] init];
        NSArray *apfsutil2Args;
        // apfs.util is what allows rsync dualboots to work, thanks Apple! I found it while digging around trying to find something to do exactly this!
        if ([version containsString:@"10."]) { // Avoid using succdatroot on iOS 10 as we run Divse as root to avoid succdatroot being broken on 10.x
            [apfsutil2Task setLaunchPath:@"/System/Library/Filesystems/apfs.fs/apfs.util"];
            apfsutil2Args = [NSArray arrayWithObjects:[NSString stringWithFormat:@"-s /dev/%@", dualbootedSystemB], nil];
        } else {
            [apfsutil2Task setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
            apfsutil2Args = [NSArray arrayWithObjects:@"/System/Library/Filesystems/apfs.fs/apfs.util", [NSString stringWithFormat:@"-s /dev/%@", dualbootedDataB], nil];
        }
        
        [apfsutil2Task setArguments:apfsutil2Args];
        [apfsutil2Task launch];
        [apfsutil2Task waitUntilExit];
        
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:@"/mnt1/Applications/Setup.app" error:nil];
    }
    
    // Create new fstab with our new partitions
    NSString *etcDirectory = @"/mnt1/etc";
    NSString *fileName = [NSString stringWithFormat:@"%@/fstab", etcDirectory];
    NSString *content = [NSString stringWithFormat:@"/dev/%@ / apfs ro 0 1\n/dev/%@ /private/var apfs rw,nosuid,nodev 0 2\n", dualbootedSystemB, dualbootedDataB];
    [content writeToFile:fileName atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
    
    [self->_spinningThing setHidden:TRUE];

}

-(void)DiviseRestore{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [self logToFile:@"DiviseRestore called!" atLineNumber:__LINE__];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[[NSString stringWithFormat:@"/private/var/mnt/divise/"] stringByAppendingPathComponent:@"sbin"] stringByAppendingPathComponent:@"launchd"]]) {
        [self logToFile:@"verified filesystem is mounted" atLineNumber:__LINE__];
        NSMutableArray *rsyncMutableArgs = [NSMutableArray arrayWithObjects:
                                            @"-vaxcH",
                                            @"--delete",
                                            @"--progress",
                                            @"--ignore-errors",
                                            @"--force",
                                            @"--exclude=/Developer",
                                            @"--exclude=/System/Library/Caches/com.apple.kernelcaches/kernelcache",
                                            @"--exclude=/System/Library/Caches/apticket.der",
                                            @"--exclude=/System/Library/Caches/com.apple.factorydata/",
                                            @"--exclude=/usr/standalone/firmware/sep-firmware.img4",
                                            @"--exclude=/usr/local/standalone/firmware/Baseband",
                                            @"--exclude=/private/var/mnt/divise/",
                                            @"--exclude=/private/etc/fstab",
                                            @"--exclude=/etc/fstab",
                                            @"--exclude=/usr/standalone/firmware/FUD/",
                                            @"--exclude=/usr/standalone/firmware/Savage/",
                                            @"--exclude=/System/Library/Pearl",
                                            @"--exclude=/usr/standalone/firmware/Yonkers/",
                                            @"--exclude=/private/var/containers/",
                                            @"--exclude=/var/containers/",
                                            @"--exclude=/private/var/keybags/",
                                            @"--exclude=/var/keybags/",
                                            @"--exclude=/applelogo",
                                            @"--exclude=/devicetree",
                                            @"--exclude=/kernelcache",
                                            @"--exclude=/ramdisk",
                                            @"/private/var/mnt/divise/.", nil];
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Caches/xpcproxy"] || [[NSFileManager defaultManager] fileExistsAtPath:@"/var/tmp/xpcproxy"]) {
            [rsyncMutableArgs addObject:@"--exclude=/Library/Caches/"];
            [rsyncMutableArgs addObject:@"--exclude=/usr/libexec/xpcproxy"];
            [rsyncMutableArgs addObject:@"--exclude=/tmp/xpcproxy"];
            [rsyncMutableArgs addObject:@"--exclude=/var/tmp/xpcproxy"];
            [rsyncMutableArgs addObject:@"--exclude=/usr/lib/substitute-inserter.dylib"];
        }
        if ([[self->_divisePrefs objectForKey:@"dualboot"] isEqual:@(1)]) {
            [self logToFile:@"We are dualbooting, seeting '/mnt1' as target" atLineNumber:__LINE__];
            [rsyncMutableArgs addObject:@"/mnt1"];
        } else {
            [self logToFile:@"We are tether downgrading, setting '/' as target" atLineNumber:__LINE__];
            [rsyncMutableArgs addObject:@"--exclude=/var"];
            [rsyncMutableArgs addObject:@"--exclude=/private/var/"];
            [rsyncMutableArgs addObject:@"/"];
        }
        if (![_filesystemType isEqualToString:@"apfs"]) {
            [self logToFile:@"non-APFS detected, excluding dyld-shared-cache to prevent running out of storage" atLineNumber:__LINE__];
            [rsyncMutableArgs addObject:@"--exclude=/System/Library/Caches/com.apple.dyld/"];
        }
        NSTask *rsyncTask = [[NSTask alloc] init];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[_divisePrefs objectForKey:@"custom_rsync_path"]]) {
            [self logToFile:[NSString stringWithFormat:@"found rsync at path: %@", [_divisePrefs objectForKey:@"custom_rsync_path"]] atLineNumber:__LINE__];
            if ([(NSString *)[_divisePrefs objectForKey:@"custom_rsync_path"] isEqualToString:@"/usr/bin/rsync"]) {
                NSString *version = [[UIDevice currentDevice] systemVersion];
                
                if ([version containsString:@"10."]) { // Avoid using succdatroot on iOS 10 as we run Divse as root to avoid succdatroot being broken on 10.x
                    [rsyncTask setLaunchPath:@"/usr/bin/rsync"];
                } else {
                    [rsyncTask setLaunchPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"succdatroot"]];
                    [rsyncMutableArgs insertObject:@"rsync" atIndex:0];
                }
            } else {
                NSString *version = [[UIDevice currentDevice] systemVersion];
                if ([version containsString:@"10."]) { // Avoid using succdatroot on iOS 10 as we run Divse as root to avoid succdatroot being broken on 10.x
                    [rsyncTask setLaunchPath:[_divisePrefs objectForKey:@"custom_rsync_path"]];
                } else {
                    [rsyncMutableArgs insertObject:[_divisePrefs objectForKey:@"custom_rsync_path"] atIndex:0];
                }
                [rsyncMutableArgs insertObject:[_divisePrefs objectForKey:@"custom_rsync_path"] atIndex:0];
            }
        } else {
            [self logToFile:[NSString stringWithFormat:@"couldnt find rsync at path %@, checking /usr/bin/rsync to see if user accidentally changed preferences", [_divisePrefs objectForKey:@"custom_rsync_path"]] atLineNumber:__LINE__];
            if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/rsync"]) {
                UIAlertController *rsyncNotFound = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Unable to find rsync at custom path %@", [_divisePrefs objectForKey:@"custom_rsync_path"]] message:@"/usr/bin/rsync will be used" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
                [rsyncNotFound addAction:useDefualtPathAction];
                [self presentViewController:rsyncNotFound animated:TRUE completion:nil];
                [self logToFile:@"found rsync at default path, using /usr/bin/rsync" atLineNumber:__LINE__];
                [rsyncMutableArgs insertObject:@"rsync" atIndex:0];
            } else {
                [self logToFile:@"unable to find rysnc at user-specified path or custom path, asking to reinstall rsync" atLineNumber:__LINE__];
                [self errorAlert:[NSString stringWithFormat:@"Unable to find rsync at custom path %@\nPlease check your custom path in Divisé's settings or install rsync from Cydia", [_divisePrefs objectForKey:@"custom_rsync_path"]] atLineNumber:__LINE__];
            }
        }
        [self logToFile:[NSString stringWithFormat:@"/Applications/Divisé.app/succdatroot %@", [rsyncMutableArgs componentsJoinedByString:@" "]] atLineNumber:__LINE__];
        NSArray *rsyncArgs = [NSArray arrayWithArray:rsyncMutableArgs];
        [rsyncTask setArguments:rsyncArgs];
        NSPipe *outputPipe = [NSPipe pipe];
        [rsyncTask setStandardOutput:outputPipe];
        [rsyncTask setStandardError:outputPipe];
        NSFileHandle *stdoutHandle = [outputPipe fileHandleForReading];
        [stdoutHandle waitForDataInBackgroundAndNotify];
        id observer;
        observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification
                                                                     object:stdoutHandle queue:nil
                                                                 usingBlock:^(NSNotification *note)
                    {
            
            NSData *dataRead = [stdoutHandle availableData];
            NSString *stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
            //[self logToFile:stringRead atLineNumber:__LINE__];
            [[self titleLabel] setText:@"Restoring, please wait..."];
            [[self subtitleLabel] setText:@"Progress bar may freeze for long periods of time, it's still working, leave it alone until your device reboots."];
            [[self titleLabel] setHidden:FALSE];
            if ([stringRead containsString:@"cannot delete non-empty directory"] && [stringRead containsString:@"Applications/"]) {
                [self errorAlert:@"Divisé has failed due to an issue with rsync. I don't know what caused this, sorry. You can follow the discussion of this issue at https://github.com/SuccessionRestore/issues/44" atLineNumber:__LINE__];
                [rsyncTask terminate];
            }
            NSArray *stringWords = [stringRead componentsSeparatedByString:@" "];
            for (NSString *word in stringWords) {
                if ([word hasPrefix:@"Applications/"] || [word hasPrefix:@"bin/"] || [word containsString:@"dev/"] || [word hasPrefix:@"Library/"] || [word containsString:@"private/"]|| [word containsString:@"sbin/"] || [word hasPrefix:@"System/"] || [word hasPrefix:@"usr/"]) {
                    [[self progressIndicator] setHidden:TRUE];
                    [[self restoreProgressBar] setHidden:FALSE];
                    [[self outputLabel] setHidden:FALSE];
                    if ([stringRead containsString:@"deleting"]) {
                        [[self outputLabel] setText:[NSString stringWithFormat:@"Deleting from %@", word]];
                    } else {
                        [[self outputLabel] setText:[NSString stringWithFormat:@"Restoring %@", word]];
                    }
                }
            }
            if ([stringRead hasPrefix:@"Applications/"]) {
                [[self restoreProgressBar] setProgress:0];
            }
            if ([stringRead hasPrefix:@"Library/"]) {
                [[self restoreProgressBar] setProgress:0.33];
            }
            if ([stringRead hasPrefix:@"System/"]) {
                [[self restoreProgressBar] setProgress:0.67];
            }
            if ([stringRead hasPrefix:@"private/"]) {
                [[self restoreProgressBar] setProgress:0.75];
            }
            if ([stringRead hasPrefix:@"usr/"]) {
                [[self restoreProgressBar] setProgress:0.9];
            }
            if ([stringRead containsString:@"speedup is"] && [stringRead containsString:@"bytes"] && [stringRead containsString:@"sent"] && [stringRead containsString:@"received"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self logToFile:@"restore has completed!" atLineNumber:__LINE__];
                    [[self outputLabel] setHidden:TRUE];
                    [[self titleLabel] setText:@"Restore complete"];
                    [[self progressIndicator] setHidden:TRUE];
                    [[self restoreProgressBar] setHidden:FALSE];
                    [[self restoreProgressBar] setProgress:1.0];
                    [[NSNotificationCenter defaultCenter] removeObserver:observer];
                    if ([[self->_divisePrefs objectForKey:@"dry-run"] isEqual:@(1)]) {
                        [self logToFile:@"Test mode used, exiting..." atLineNumber:__LINE__];
                        UIAlertController *restoreCompleteController = [UIAlertController alertControllerWithTitle:@"Dry run complete!" message:@"YAY!" preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                            exit(0);
                        }];
                        [restoreCompleteController addAction:exitAction];
                        [self presentViewController:restoreCompleteController animated:TRUE completion:nil];
                    } else {
                        if ([[self->_divisePrefs objectForKey:@"dualboot"] isEqual:@(1)]) {
                            [self postRestore];
                            
                            [[self eraseButton] setTitle:@"Done!" forState:UIControlStateNormal];
                            
                            if ([[self->_dualbootPrefs objectForKey:@"Version"] isEqual:@"1.1.1"]) {
                                
                                // User must have used a local IPSW, getting version now and saving it to disk
                                
                                [self->_dualbootPrefs setObject:[self->_secondOS objectForKey:@"ProductVersion"] forKey:@"Version"];
                                
                            }
                            
                            [UIApplication sharedApplication].idleTimerDisabled = NO;
                            NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/"
                                                                                                 error:NULL];
                            NSArray *devdisklist = [files filteredArrayUsingPredicate:
                                                                [NSPredicate predicateWithFormat:@"self BEGINSWITH[cd] 'disk0s1s'"]];
                            int devdisknum = [devdisklist count];
                    
                            NSString *title = [NSString stringWithFormat:@"Dualbooting Complete!"];
                            UIAlertController *alertController2 = [UIAlertController alertControllerWithTitle:title message:[NSString stringWithFormat:@"Use pyboot with \n'-i %@ %@ -d disk0s1s%d'\n to boot iOS %@! :)", self->_deviceModel, [self->_dualbootPrefs objectForKey:@"Version"], devdisknum - 1, [self->_dualbootPrefs objectForKey:@"Version"]] preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Reboot" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                reboot(0x400);
                            }];
                            [alertController2 addAction:confirmAction];
                            [self presentViewController:alertController2 animated:YES completion:nil];
                            
                        }
                        [self logToFile:@"showing restore complete alert" atLineNumber:__LINE__];
                        UIAlertController *restoreCompleteController = [UIAlertController alertControllerWithTitle:@"Restore Succeeded!" message:@"Rebuilding icon cache, please wait..." preferredStyle:UIAlertControllerStyleAlert];
                        [self presentViewController:restoreCompleteController animated:TRUE completion:^{
                            if ([[self->_divisePrefs objectForKey:@"update-install"] isEqual:@(1)]) {
                                [self logToFile:@"Update install was used, rebuilding uicache" atLineNumber:__LINE__];
                                if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/uicache"]) {
                                    NSTask *uicacheTask = [[NSTask alloc] init];
                                    NSArray *uicacheElectraArgs = [NSArray arrayWithObjects:@"--all", nil];
                                    [uicacheTask setLaunchPath:@"/usr/bin/uicache"];
                                    [uicacheTask setArguments:uicacheElectraArgs];
                                    [uicacheTask launch];
                                    [uicacheTask waitUntilExit];
                                    [self logToFile:@"uicache complete, deleting it..." atLineNumber:__LINE__];
                                    NSError *err;
                                    [[NSFileManager defaultManager] removeItemAtPath:@"/usr/bin/uicache" error:&err];
                                    if (err) {
                                        [self logToFile:[NSString stringWithFormat:@"non-fatal error, not showing alert. unable to delete uicache: %@", [err localizedDescription]] atLineNumber:__LINE__];
                                    }
                                    reboot(0x400);
                                } else {
                                    [self logToFile:@"/usr/bin/uicache doesnt exist, oops. rebooting..." atLineNumber:__LINE__];
                                reboot(0x400);
                                }
                            } else if ([[self->_divisePrefs objectForKey:@"dry-run"] isEqual:@(1)]){
                                [self logToFile:@"That was a test mode restore, but somehow the first check for this didnt get detected... anways, the app will just hang now..." atLineNumber:__LINE__];
                            } else {
                                //extern int SBDataReset(mach_port_t, int);
                                //extern mach_port_t SBSSpringBoardServerPort(void);
                              //  [self logToFile:[NSString stringWithFormat:@"That was a normal restore. go, mobile_obliteration! %u", //SBSSpringBoardServerPort()] atLineNumber:__LINE__];
                                //SBDataReset(SBSSpringBoardServerPort(), 5);
                                reboot(0x400);
                            }
                        }];
                    }
                });
            }
            [stdoutHandle waitForDataInBackgroundAndNotify];
        }];
        [self logToFile:@"Updating UI to prepare for restore" atLineNumber:__LINE__];
        [[self titleLabel] setText:@"Working, do not leave the app..."];
        [[self subtitleLabel] setText:@"This should take less than 10 seconds."];
        [[self eraseButton] setTitle:@"Working" forState:UIControlStateNormal];
        [[self eraseButton] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [[self eraseButton] setEnabled:FALSE];
        [[self progressIndicator] setHidden:FALSE];
        if ([rsyncTask launchPath]) {
            [self logToFile:@"rsyncTask has a valid launchPath" atLineNumber:__LINE__];
            if ([[_divisePrefs objectForKey:@"create_APFS_orig-fs"] isEqual:@(1)] && [[_divisePrefs objectForKey:@"create_APFS_succession-prerestore"] isEqual:@(1)]) {
                [self logToFile:@"Both orig-fs and succession-prerestore are selected, these options confilct, aborting restore..." atLineNumber:__LINE__];
                UIAlertController *tooMuchAPFSAlert = [UIAlertController alertControllerWithTitle:@"Conflicting options enabled" message:@"You cannot have 'create backup snapshot' and 'create new orig-fs' enabled simultaneously, please go to Succession's settings page and disable one of the two." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self logToFile:@"restore aborted" atLineNumber:__LINE__];
                    [[self navigationController] popToRootViewControllerAnimated:TRUE];
                }];
                [tooMuchAPFSAlert addAction:dismissAction];
                [self presentViewController:tooMuchAPFSAlert animated:TRUE completion:nil];
            } else {
                [rsyncTask launch];
            }
        } else {
            [self errorAlert:@"Unable to apply launchPath to rsyncTask. Please (re)install rsync from Cydia." atLineNumber:__LINE__];
        }
    } else {
        [self errorAlert:@"Mountpoint does not contain rootfilesystem, please restart the app and try again." atLineNumber:__LINE__];
    }
}

-(void)errorAlert:(NSString *)message atLineNumber:(int)lineNum{
    [self logToFile:[NSString stringWithFormat:@"ERROR! %@", message] atLineNumber:lineNum];
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
