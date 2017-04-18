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
@property (nonatomic) NSMutableArray * allPhotos; //すべての写真
@property (nonatomic) NSMutableArray * photoSections; // わけられた写真


-(void)loadSectionFromPhotos:(NSMutableArray *)photos;
@end
