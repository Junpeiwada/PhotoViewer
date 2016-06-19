//
//  JPPhotoCollectionViewCell.h
//  JPPhotoViewer
//
//  Created by junpeiwada on 2016/06/19.
//  Copyright © 2016年 soneru. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JPPhotoCollectionViewCell : UICollectionViewCell
@property NSString* thumbnailPath;
-(UIImageView *)imageView;
-(void)loadImage;
@end
