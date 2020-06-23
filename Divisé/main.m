//
//  main.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 9/27/17.
//  Copyright © 2017 Sam Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        
        NSString *version = [[UIDevice currentDevice] systemVersion];
        
        if ([version containsString:@"10."]) {
            
            // We only need to run as root on 10.x as succdatroot is broken on 10.x
            
            if (!(setuid(0) == 0 && setgid(0) == 0)) {
                
                NSLog(@"Failed to gain root privileges, aborting...");
                exit(EXIT_FAILURE);
                
            }
        } else {
            if ((getuid() == 0 && getgid() == 0)) {
                
                NSLog(@"We are running as root when we shouldn't be, aborting...");
                exit(EXIT_FAILURE);
                
            }
        }
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
