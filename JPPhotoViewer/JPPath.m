//
//  JPPath.m
//  JPPhotoViewer
//
//  Created by junpeiwada on 2016/10/21.
//  Copyright © 2016年 soneru. All rights reserved.
//

#import "JPPath.h"

@implementation JPPath

// テーブルビューのヘッダに表示するためのすごくちっこいサムネのパスを返す
+(NSString *)tableViewHeaderThumbPath:(NSString *)directoryPath index:(NSInteger)index{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@",documentsDirectory,@".thumb"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *result =[NSString stringWithFormat:@"%@/%@--%ld%@",fullPath,directoryPath.lastPathComponent,index,@".jpg"];
    return result;
}
@end
