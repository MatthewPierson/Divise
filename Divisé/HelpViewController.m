//
//  HelpViewController.m
//  Divisé
//
//  Created by matty on 30/05/20.
//  Copyright © 2020 Sam Gardner. All rights reserved.
//

#import "HelpViewController.h"
#import "NSTask.h"
#include <sys/sysctl.h>

@interface HelpViewController ()

@end

@implementation HelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _divisePrefs = [NSMutableDictionary dictionaryWithDictionary:[NSDictionary  dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.moski.Divise.plist"]]; 
    [[[self navigationController] navigationBar] setHidden:FALSE];
    self.navigationItem.title = @"Settings";
    
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
    
    _headerText.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.75f];
}

-(void)viewDidAppear:(BOOL)animated{
    [[[self navigationController] navigationBar] setHidden:FALSE];
    self.navigationItem.title = @"Settings";
}


- (IBAction)startButton:(UIButton *)sender {
    
    UIAlertController *startHelp = [UIAlertController alertControllerWithTitle:@"How to use Divise" message:@"To start Divse, simply press the\n'Download IPSW'\nbutton on the homepage, then press the\n'Enter iOS Version'\nbutton to pick an iOS version to download! From there a red button will appear on the homescreen which you press to begin the dualboot/tethered downgrade process!" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [startHelp addAction:useDefualtPathAction];
    [self presentViewController:startHelp animated:TRUE completion:nil];
    
}


- (IBAction)modeButton:(UIButton *)sender {
    
    UIAlertController *modeHelp = [UIAlertController alertControllerWithTitle:@"How to change restore modes" message:@"To change between dualbooting and tethered downgrading, simply go into the Settings page using the button on the homescreen, and toggle the\n'Dualboot Device'\noption, with off being Tethered Downgrading and on being Dualbooting.\nDO NOT do this if you have already dualbooted your device! It WILL cause issues!" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [modeHelp addAction:useDefualtPathAction];
    [self presentViewController:modeHelp animated:TRUE completion:nil];
    
}

- (IBAction)uninstallHelp:(UIButton *)sender {
    
    UIAlertController *uninstallHelp = [UIAlertController alertControllerWithTitle:@"How to uninstall the second OS" message:@"To uninstall the second OS, simply press the\n'Manage Installed Versions'\non the homepage, then press the red\n'Uninstall Second OS'\nbutton. This will uninstall the second OS, allowing you to re-dualboot the device if you want to! This will delete the newly created partitions as well, so any space taken up by then will be free to use for other things." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [uninstallHelp addAction:useDefualtPathAction];
    [self presentViewController:uninstallHelp animated:TRUE completion:nil];
    
}

- (IBAction)bootHelp:(UIButton *)sender {
    
    UIAlertController *bootHelp = [UIAlertController alertControllerWithTitle:@"How to boot the second OS" message:@"To boot the second OS, the simplest way is to use PyBoot (macOS only) with the '-d disk0s1sX' flag. This is what is shown at the end of a successfull dualboot.\n\nIf you only have access to a linux machine (Windows is not supported AT ALL) you can manually tether boot the device. You will need to find a guide online somewhere for this, I will not be offering support or help to Linux users trying to manually tether boot." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [bootHelp addAction:useDefualtPathAction];
    [self presentViewController:bootHelp animated:TRUE completion:nil];
    
}

- (IBAction)reportHelp:(UIButton *)sender {
    
    UIAlertController *reportHelp = [UIAlertController alertControllerWithTitle:@"How to report issues/bugs" message:@"Either DM me on twitter (@mosk_i), email me at 'moski@moski.fun' or open an issue on Github.\n\nPLEASE CHECK IF SOMEONE ELSE HAS ALREADY OPENED AN ISSUE BEFORE OPENING A NEW ONE." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *useDefualtPathAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [reportHelp addAction:useDefualtPathAction];
    [self presentViewController:reportHelp animated:TRUE completion:nil];
    
}


- (IBAction)backButton:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
