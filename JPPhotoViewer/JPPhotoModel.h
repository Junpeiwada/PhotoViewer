//
//  JPPhotoModel.h
//  NYTPhotoViewer
//
//  Created by junpeiwada on 2016/05/07.
//  Copyright © 2016年 junpeiwada. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JPPhotoModel : NSObject
+ (NSArray *)newTestPhotosWithDirectoryName:(NSString *)directoryPath;
+ (NSString *)plistPath:(NSString *)directoryPath;
+(void)removeIndex:(NSString *)directoryname;
+(void)removeAllIndex;
+(void)removeDirectory:(NSString *)directoryname;
@end
