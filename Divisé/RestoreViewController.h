//
//  RestoreViewController.h
//  SuccessionRestore
//
//  Created by Sam Gardner on 11/28/19.
//  Copyright © 2019 Sam Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RestoreViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *restoreProgressBar;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressIndicator;
@property (weak, nonatomic) IBOutlet UILabel *outputLabel;
@property (weak, nonatomic) IBOutlet UIButton *eraseButton;
@property (strong, nonatomic) NSMutableDictionary *divisePrefs;
@property (strong, nonatomic) NSMutableDictionary *secondOS;
@property (strong, nonatomic) NSMutableDictionary *dualbootPrefs;
@property (strong, nonatomic) NSMutableDictionary *activationPlist;
@property (strong, nonatomic) NSString *deviceModel;
@property (strong, nonatomic) NSString *deviceType;
@property (strong, nonatomic) UIAlertController *areYouSureAlert;
@property (strong, nonatomic) NSString *filesystemType;
@property (strong, nonatomic) NSString *installedVersion;
@property (weak, nonatomic) IBOutlet UILabel *done1;
@property (weak, nonatomic) IBOutlet UILabel *done2;
@property (weak, nonatomic) IBOutlet UILabel *done3;
@property (weak, nonatomic) IBOutlet UILabel *during1;
@property (weak, nonatomic) IBOutlet UILabel *during2;
@property (weak, nonatomic) IBOutlet UILabel *during3;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinningThing;
@property (weak, nonatomic) IBOutlet UIButton *backButtonH;
@end

