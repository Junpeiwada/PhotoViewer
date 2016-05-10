//
//  NYTExamplePhoto.h
//  ios-photo-viewer
//
//  Created by Brian Capps on 2/11/15.
//  Copyright (c) 2015 NYTimes. All rights reserved.
//

@import Foundation;

#import <NYTPhotoViewer/NYTPhoto.h>

@interface NYTExamplePhoto : NSObject <NYTPhoto>


@property (nonatomic) NSString *imagePath;
@property (nonatomic) NSString *thumbnailPath;

// Redeclare all the properties as readwrite for sample/testing purposes.
@property (nonatomic) UIImage *image;

@property (nonatomic) NSInteger width;
@property (nonatomic) NSInteger height;

@property (nonatomic) NSData *imageData;
@property (nonatomic) UIImage *placeholderImage;
@property (nonatomic) NSAttributedString *attributedCaptionTitle;
@property (nonatomic) NSAttributedString *attributedCaptionSummary;
@property (nonatomic) NSAttributedString *attributedCaptionCredit;

-(void)loadImage;
-(BOOL)isExistThumbFile;

-(UIImage *)thumbnail;

-(void)remove;
@end
