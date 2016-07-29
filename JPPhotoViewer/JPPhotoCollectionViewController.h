//
//  JPPhotoCollectionViewController.h
//  NYTPhotoViewer
//
//  Created by junpeiwada on 2016/05/07.
//  Copyright © 2016年 junpeiwada. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JPPhotoCollectionViewController : UICollectionViewController
@property (nonatomic) NSString * photoDirectory;
@property (nonatomic) NSMutableArray * photos;

@end
