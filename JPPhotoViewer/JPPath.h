//
//  JPPath.h
//  JPPhotoViewer
//
//  Created by junpeiwada on 2016/10/21.
//  Copyright © 2016年 soneru. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JPPath : NSObject
// テーブルビューのヘッダに表示するためのすごくちっこいサムネのパスを返す
+(NSString *)tableViewHeaderThumbPath:(NSString *)directoryPath index:(NSInteger)index;

// テーブルビューのヘッダに表示するためのすごくちっこいサムネの保存ディレクトリパス
+(NSString *)tableViewHeaderThumbDirectoryPath;

// ディレクトリの中のファイル一覧（Exifも）がアーカイブされたJsonのパスを返す
+(NSString *)jsonPath:(NSString *)directoryPath;
@end
