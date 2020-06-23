//
//  SettingsViewController.h
//  Divisé
//
//  Created by matty on 27/05/20.
//  Copyright © 2020 Sam Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController

@property (nonatomic, strong) NSMutableDictionary *divisePrefs;
@property (nonatomic, strong) UISwitch *createAPFSsuccessionprerestoreSwitch;
@property (nonatomic, strong) UISwitch *createAPFSorigfsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *deleteDuringSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *logOutputSwitch;
@property (weak, nonatomic) IBOutlet UIButton *deleterfs;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinningThing;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end
