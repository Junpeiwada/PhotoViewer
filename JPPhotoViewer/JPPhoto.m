//
//  NYTExamplePhoto.m
//  ios-photo-viewer
//
//  Created by junpeiwada on 2016/05/07.
//  Copyright © 2016年 junpeiwada. All rights reserved.
//

#import "JPPhoto.h"
#import <AVFoundation/AVFoundation.h>
@implementation JPPhoto

// リサイズする関数
- (UIImage *)resizeImage:(UIImage *)image
             withQuality:(CGInterpolationQuality)quality
                    size:(CGSize)size
{
    
    UIImage *resized = nil;
    CGFloat width = size.width;
    CGFloat height = size.height;
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, quality);
    [image drawInRect:CGRectMake(0, 0, width, height)];
    resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
//    NSDate *timer = nil;
//    timer = [NSDate date];
//    NSLog(@"time: %f", [[NSDate date] timeIntervalSinceDate:timer]);
    return resized;
    
}

// イメージをロードする（フルイメージ）
-(void)loadImage{
    if (!self.image){
        self.image = [UIImage imageWithContentsOfFile:self.imagePath];
    }
}

// サムネのパスを作る
-(NSString *)thumbnailPathSize{
    return [NSString stringWithFormat:@"%@-%ld",self.thumbnailPath,(long)self.thumbnailSize];
}

// サムネイルがあるかどうか
-(BOOL)isExistThumbFile{
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:[self thumbnailPathSize]];
//    if (!isExist){
//        NSLog(@"%@",[self thumbnailPathSize]);
//    }
    return isExist;
}

// サムネイルをロードする。サムネがあればそれを、なければ作る
-(UIImage *)thumbnail{
    if ([self isExistThumbFile]){
        // サムネイルが存在するのでロード
        return [UIImage imageWithContentsOfFile:[self thumbnailPathSize]];
    }else{
        // ないので作る
        return [self makeThumbnail];
    }
}

-(UIImage *)makeThumbnail{
    UIImage * full ;
    if (self.image){
        full = self.image;
    }else{
        full = [UIImage imageWithContentsOfFile:self.imagePath];
    }
    if (full){
        CGRect frame;
        
        // アスペクトを求める
        CGFloat ratio =  full.size.width / full.size.height;
        if (full.size.width > full.size.height){
            // 横長の画像
            frame = CGRectMake(0, 0, self.thumbnailSize, (int)(self.thumbnailSize / ratio));
        }else{
            // 縦長の画像
            frame = CGRectMake(0, 0, self.thumbnailSize, (int)(self.thumbnailSize / ratio));
        }
        
        
        frame = CGRectMake(0, 0, (int)frame.size.width, (int)frame.size.height);
        UIImage * thumb = [self resizeImage:full withQuality:kCGInterpolationHigh size:frame.size];
        
        NSData *dataSaveImage = UIImageJPEGRepresentation(thumb, 1.0);
        if (![dataSaveImage writeToFile:[self thumbnailPathSize] atomically:YES]){
            NSLog(@"サムネールの作成に失敗");
        }
        
//        NSLog(@"サムネール作った%@",[self thumbnailPathSize]);
        
        
        return thumb;
    }else{
        NSLog(@"画像が見つかりません。%@",self.imagePath);
        return nil;
    }
}

- (NSArray*)fileNamesAtDirectoryPath:(NSString*)directoryPath
{
    NSFileManager *fileManager=[[NSFileManager alloc] init];
    NSError *error = nil;
    /* 全てのファイル名 */
    NSArray *allFileName = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error) return nil;
    NSMutableArray *hitFileNames = [[NSMutableArray alloc] init];
    for (NSString *fileName in allFileName) {
        [hitFileNames addObject:fileName];
    }
    return hitFileNames;
}
-(void)removeThumb{
    NSArray *imgFileNames = [self fileNamesAtDirectoryPath:NSTemporaryDirectory() ];
    for (NSString *fileName in imgFileNames) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@",NSTemporaryDirectory(),fileName];

        NSError *error=nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (error!=nil) {
            NSLog(@"failed to remove %@",[error localizedDescription]);
        }else{
//            NSLog(@"Successfully removed:%@",filePath);
        }
    }
}

// 本物を削除します
-(void)removeOriginal{
    
    NSError *error=nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.imagePath error:&error];
    if (error!=nil) {
        NSLog(@"failed to remove %@",[error localizedDescription]);
    }else{
        //            NSLog(@"Successfully removed:%@",filePath);
    }
}

+ (NSInteger)tempFilesSize {
    
    NSString *folderPath = NSTemporaryDirectory();
    
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    NSInteger fileSize = 0;
    
    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary *fileDictionary = [[NSFileManager defaultManager]
                                        attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName]
                                        error:nil];
        fileSize += [fileDictionary fileSize];
    }
    
    return fileSize;
}

@end
