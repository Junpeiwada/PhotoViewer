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
    NSString *fullPath = [JPPath tableViewHeaderThumbDirectoryPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *result =[NSString stringWithFormat:@"%@/%@--%ld%@",fullPath,directoryPath.lastPathComponent,(long)index,@".jpg"];
    return result;
}
// テーブルビューのヘッダに表示するためのすごくちっこいサムネの保存ディレクトリパス
+(NSString *)tableViewHeaderThumbDirectoryPath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@",documentsDirectory,@".thumb"];
    return fullPath;
}

// ディレクトリのフルパスからjsonのパスを返す。
+(NSString *)jsonPath:(NSString *)directoryPath{
    NSString *jsonPath = [NSString stringWithFormat:@"%@/%@",directoryPath,@"photos.json"];
    return jsonPath;
}


// イメージのサムネパス
+(NSString *)thumbnailPathWithDirectory:(NSString *)directoryPath filename:(NSString *)filename{
    NSString *path = [NSString stringWithFormat:@"%@%@--%@",NSTemporaryDirectory(),directoryPath.lastPathComponent,filename];
    return path;
}
@end
