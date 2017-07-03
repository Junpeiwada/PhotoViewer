//
//  ViewController.h
//  JPPhotoViewer
//
//  Created by junpeiwada on 2016/05/10.
//  Copyright © 2016年 soneru. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JPPhoto.h"
@interface ViewController : UIViewController

@property BOOL isMoveMode;
@property BOOL isCopyMode;
@property JPPhoto * moveTarget;

@end

