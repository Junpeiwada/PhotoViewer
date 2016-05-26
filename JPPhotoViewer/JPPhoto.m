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

// サムネのパスを作る
-(NSString *)thumbnailPathSize{
    return [NSString stringWithFormat:@"%@-%ld",self.thumbnailPath,(long)self.thumbnailSize];
}

// サムネイルがあるかどうか
-(BOOL)isExistThumbFile{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self thumbnailPathSize]];
}

// サムネイルをロードする。サムネがあればそれを、なければ作る
-(UIImage *)thumbnail{
    if ([self isExistThumbFile]){
        // サムネイルが存在するのでロード
        return [UIImage imageWithContentsOfFile:[self thumbnailPathSize]];
    }else{
        // ないので作る
        NSLog(@"makeThumbnail");
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
        CGRect frame = AVMakeRectWithAspectRatioInsideRect(full.size,CGRectMake(0, 0, self.thumbnailSize, self.thumbnailSize));
        frame = CGRectMake(0, 0, (int)frame.size.width, (int)frame.size.height);
        UIImage * thumb = [self resizeImage:full withQuality:kCGInterpolationMedium size:frame.size];
        
        NSData *dataSaveImage = UIImageJPEGRepresentation(thumb, 1.0);
        [dataSaveImage writeToFile:[self thumbnailPathSize] atomically:YES];
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
-(void)remove{
    NSArray *imgFileNames = [self fileNamesAtDirectoryPath:NSTemporaryDirectory() ];
    for (NSString *fileName in imgFileNames) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@",NSTemporaryDirectory(),fileName];

        NSError *error=nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (error!=nil) {
            NSLog(@"failed to remove %@",[error localizedDescription]);
        }else{
            NSLog(@"Successfully removed:%@",filePath);
        }
    }
}

@end
