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
    NSDate *timer = nil;
    UIImage *resized = nil;
    CGFloat width = size.width;
    CGFloat height = size.height;
    
    timer = [NSDate date];
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, quality);
    [image drawInRect:CGRectMake(0, 0, width, height)];
    resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //    NSLog(@"time: %f", [[NSDate date] timeIntervalSinceDate:timer]);
    return resized;
    
}

// イメージをロードする（フルイメージ）
-(void)loadImage{
    if (!self.image){
        self.image = [UIImage imageWithContentsOfFile:self.imagePath];
    }
}

// サムネイルがあるかどうか
-(BOOL)isExistThumbFile{
    return [[NSFileManager defaultManager] fileExistsAtPath:self.thumbnailPath];
}

// サムネイルをロードする。サムネがあればそれを、なければ作る
-(UIImage *)thumbnail{
    if ([self isExistThumbFile]){
        // サムネイルが存在するのでロード
        return [UIImage imageWithContentsOfFile:self.thumbnailPath];
    }else{
        // ないので作る
        NSLog(@"makeThumbnail");
        return [self makeThumbnail:300];
    }
}

-(UIImage *)makeThumbnail:(NSInteger)size{
    UIImage * full ;
    if (self.image){
        full = self.image;
    }else{
        full = [UIImage imageWithContentsOfFile:self.imagePath];
    }
    if (full){
        CGRect frame = AVMakeRectWithAspectRatioInsideRect(full.size,CGRectMake(0, 0, size, size));
        frame = CGRectMake(0, 0, (int)frame.size.width, (int)frame.size.height);
        UIImage * thumb = [self resizeImage:full withQuality:kCGInterpolationMedium size:frame.size];
        
        NSData *dataSaveImage = UIImageJPEGRepresentation(thumb, 1.0);
        [dataSaveImage writeToFile:self.thumbnailPath atomically:YES];
        return thumb;
    }else{
        NSLog(@"画像が見つかりません。%@",self.imagePath);
        return nil;
    }
}

- (NSArray*)fileNamesAtDirectoryPath:(NSString*)directoryPath extension:(NSString*)extension
{
    NSFileManager *fileManager=[[NSFileManager alloc] init];
    NSError *error = nil;
    /* 全てのファイル名 */
    NSArray *allFileName = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error) return nil;
    NSMutableArray *hitFileNames = [[NSMutableArray alloc] init];
    for (NSString *fileName in allFileName) {
        /* 拡張子が一致するか */
        if ([[fileName pathExtension] isEqualToString:extension]) {
            [hitFileNames addObject:fileName];
        }
    }
    return hitFileNames;
}
-(void)remove{
    NSString *path;
    
    NSArray *imgFileNames = [self fileNamesAtDirectoryPath:NSTemporaryDirectory() extension:@"JPG"];
    for (NSString *fileName in imgFileNames) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@",NSTemporaryDirectory(),fileName];

        NSError *error=nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (error!=nil) {
            NSLog(@"failed to remove %@",[error localizedDescription]);
        }else{
            NSLog(@"Successfully removed:%@",path);
        }
    }
}

@end
