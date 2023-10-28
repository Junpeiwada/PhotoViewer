//
//  JPNYTPhotosViewController.m
//  JPPhotoViewer
//
//  Created by JunpeiWada on 2017/04/22.
//  Copyright © 2017年 soneru. All rights reserved.
//

#import "JPNYTPhotosViewController.h"
#import "NYTPhotoViewController.h"
#import "NYTScalingImageView.h"

@interface JPNYTPhotosViewController ()

@end

@implementation JPNYTPhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewDidAppear:(BOOL)animated {

}
- (NYTPhotoViewController *)currentPhotoViewController {
    NYTPhotoViewController *one = self.pageViewController.viewControllers.firstObject;
    UIImageView *iv = (UIImageView *)one.scalingImageView.imageView;
    if (@available(iOS 17.0, *)) {
        iv.preferredImageDynamicRange = UIImageDynamicRangeHigh;
    } else {
        // Fallback on earlier versions
    }
    return one;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
