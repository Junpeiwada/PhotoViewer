//
//  JPPhotoCollectionViewCell.m
//  JPPhotoViewer
//
//  Created by junpeiwada on 2016/06/19.
//  Copyright © 2016年 soneru. All rights reserved.
//

#import "JPPhotoCollectionViewCell.h"

@implementation JPPhotoCollectionViewCell

-(void)prepareForReuse{
    self.thumbnailPath = nil;
    [self imageView].image = nil;
}

-(UIImageView *)imageView{
    return (UIImageView *)[self viewWithTag:1];
}
-(void)loadImage{
    [self imageView].image = [UIImage imageWithContentsOfFile:self.thumbnailPath];
}
@end
