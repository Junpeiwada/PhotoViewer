//
//  NYTExamplePhoto.h
//  ios-photo-viewer
//
//  Created by junpeiwada on 2016/05/07.
//  Copyright © 2016年 junpeiwada. All rights reserved.
//

@import Foundation;

#import <NYTPhotoViewer/NYTPhoto.h>

@interface JPPhoto : NSObject <NYTPhoto>


@property (nonatomic) NSString *imagePath; // イメージのパス（フルパス）
@property (nonatomic) NSString *thumbnailPath; // サムネのパス
@property (nonatomic) NSString *directryName; // ディレクトリ名

// Redeclare all the properties as readwrite for sample/testing purposes.
@property (nonatomic) UIImage *image;

@property (nonatomic) NSInteger width;
@property (nonatomic) NSInteger height;
@property (nonatomic) NSInteger thumbnailSize;

@property (nonatomic) NSData *imageData;
@property (nonatomic) UIImage *placeholderImage;
@property (nonatomic) NSAttributedString *attributedCaptionTitle;
@property (nonatomic) NSAttributedString *attributedCaptionSummary;
@property (nonatomic) NSAttributedString *attributedCaptionCredit;
@property (nonatomic) NSString *originalDateString;

-(void)loadImage;
-(BOOL)isExistThumbFile;

-(UIImage *)thumbnail;
-(NSString *)thumbnailPathSize; // サイズ指定のサムネイルのパスを返す
// 元ファイルの削除
-(void)removeOriginal;




+ (NSInteger)tempFilesSize ; //テンポラリディレクトリのサイズを返す。
@end
