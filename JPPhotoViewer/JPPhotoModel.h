//
//  JPPhotoModel.h
//  NYTPhotoViewer
//
//  Created by junpeiwada on 2016/05/07.
//  Copyright © 2016年 junpeiwada. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JPPhotoModel : NSObject
+(NSMutableArray *)photosWithDirectoryName:(NSString *)directoryPath showProgress:(BOOL)showProgress;
+(void)removeIndex:(NSString *)directoryname;
+(void)removeAllIndex; // すべてのインデックスの削除
+(void)removeAllThumb; // すべてのサムネの削除
+(void)removeDirectory:(NSString *)directoryname;
+(BOOL)isExistIndexWithDirectoryName:(NSString *)directoryPath;
+(void)saveToJsonWithPhotos:(NSArray *)photos directortyPath:(NSString *)directoryPath;

// JPPhotoのArrayを日付で分割する
+(NSMutableArray *)splitPhotosByOriginalDate:(NSMutableArray *)photos;
@end
