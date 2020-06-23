//
//  DualbootSettingsViewController.h
//  Divisé
//
//  Created by matty on 10/05/20.
//  Copyright © 2020 Sam Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DualbootSettingsViewController : UIViewController
@property (strong, nonatomic) NSMutableDictionary *dualbootPrefs;
@property (strong, nonatomic) NSMutableDictionary *divisePrefs;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *wipeButton;
@property (weak, nonatomic) IBOutlet UIButton *mountButton;
@property (weak, nonatomic) IBOutlet UIButton *unmountButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteRfs;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinningThing;

@end

