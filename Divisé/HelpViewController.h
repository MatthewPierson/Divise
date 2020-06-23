//
//  HelpViewController.h
//  Divisé
//
//  Created by matty on 30/05/20.
//  Copyright © 2020 Sam Gardner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelpViewController : UIViewController

@property (nonatomic, strong) NSMutableDictionary *divisePrefs;
@property (weak, nonatomic) IBOutlet UILabel *headerText;
@property (weak, nonatomic) IBOutlet UILabel *infoText;

@end
