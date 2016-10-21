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

@end
