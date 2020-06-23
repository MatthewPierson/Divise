//
//  ViewController.h
//  SuccessionRestore
//
//  Created by Sam Gardner on 9/27/17.
//  Copyright © 2017 Sam Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HomePageViewController : UIViewController<NSURLSessionDelegate>

@property (strong, nonatomic) NSMutableDictionary *divisePrefs;
@property (strong, nonatomic) NSMutableArray *diskDeletion;
@property (weak, nonatomic) IBOutlet UILabel *deviceModelLabel;
@property (weak, nonatomic) IBOutlet UILabel *iOSVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *iOSBuildLabel;
@property (weak, nonatomic) IBOutlet UIButton *downloadDMGButton;
@property (weak, nonatomic) IBOutlet UIButton *prepareToRestoreButton;
@property (weak, nonatomic) IBOutlet UIButton *decryptDMGButton;
@property (strong, nonatomic) NSString *deviceModel;
@property (strong, nonatomic) NSString *deviceBuild;
@property (strong, nonatomic) NSString *deviceVersion;
@property (weak, nonatomic) IBOutlet UILabel *mainInstalledVersion;
@property (weak, nonatomic) IBOutlet UILabel *dataLabel;
@property (weak, nonatomic) IBOutlet UILabel *maininstallLabel;
@property (weak, nonatomic) IBOutlet UILabel *dualbootedVersion;
@property (weak, nonatomic) IBOutlet UILabel *dualbootedDiskID;
@property (weak, nonatomic) IBOutlet UILabel *databLabel;
@property (weak, nonatomic) IBOutlet UIButton *dualbootSettings;
@property (weak, nonatomic) IBOutlet UILabel *betaLabel;
@property (weak, nonatomic) IBOutlet UILabel *installedCurrent;
@property (weak, nonatomic) IBOutlet UILabel *modelLabel;
@property (weak, nonatomic) IBOutlet UILabel *mainversionLabel;
@property (weak, nonatomic) IBOutlet UILabel *mainbuildLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *donateButton;
@property (weak, nonatomic) IBOutlet UIButton *ContactButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@end
