//
//  NYTExamplePhoto.m
//  ios-photo-viewer
//
//  Created by junpeiwada on 2016/05/07.
//  Copyright © 2016年 junpeiwada. All rights reserved.
//

#import "JPPhoto.h"
#import "JPPath.h"
#import <AVFoundation/AVFoundation.h>
@implementation JPPhoto
static NSObject *syncRoot;
+ (void)initialize{
    syncRoot = [NSObject new];
}
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
    return isExist;
}

// サムネイルをロードする。サムネがあればそれを、なければ作る
-(UIImage *)thumbnail{
    if ([self isExistThumbFile]){
        // ちっこいサムネイルが存在するのでロード
        for (NSInteger i = 10; i<14; i++) {
            NSString *imagePath =[JPPath tableViewHeaderThumbPath:self.directryName index:i];
            if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath isDirectory:nil] ){
                [self makeThumbnail];
            }
        }
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
        CGRect listFrame;
        
        // アスペクトを求める
        CGFloat ratio =  full.size.width / full.size.height;
        frame = CGRectMake(0, 0, self.thumbnailSize, (int)(self.thumbnailSize / ratio));
        listFrame = CGRectMake(0, 0, 50, (int)(50 / ratio));

        
        
        frame = CGRectMake(0, 0, (int)frame.size.width, (int)frame.size.height);
        UIImage * thumb = [self resizeImage:full withQuality:kCGInterpolationHigh size:frame.size];
        
        NSData *dataSaveImage = UIImageJPEGRepresentation(thumb, 1.0);
        if (![dataSaveImage writeToFile:[self thumbnailPathSize] atomically:YES]){
            NSLog(@"サムネールの作成に失敗");
        }
        
        // リスト用のちっこいサムネを生成
        @synchronized (syncRoot){
            for (NSInteger i = 10; i<14; i++) {
                NSString *imagePath =[JPPath tableViewHeaderThumbPath:self.directryName index:i];;
                if ( ![[NSFileManager defaultManager] fileExistsAtPath:imagePath isDirectory:nil] ){
                    UIImage * thumbForList = [self resizeImage:thumb withQuality:kCGInterpolationHigh size:listFrame.size];
                    NSData *dataSaveImagethumbForList = UIImageJPEGRepresentation(thumbForList, 1.0);
                    if (![dataSaveImagethumbForList writeToFile:imagePath atomically:YES]){
                        NSLog(@"サムネールの作成に失敗");
                    }
                    break;
                }
            }
        }
        
        
        return thumb;
    }else{
        NSLog(@"画像が見つかりません。%@",self.imagePath);
        return nil;
    }
}

// 本物を削除します
-(void)removeOriginal{
    
    NSError *error=nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.imagePath error:&error];
    if (error!=nil) {
        NSLog(@"削除に失敗 %@",[error localizedDescription]);
    }else{
        //            NSLog(@"Successfully removed:%@",filePath);
    }
}

// 一時ファイルのサイズを調べます
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

- (id <NYTPhoto>)objectAtIndexedSubscript:(NSUInteger)photoIndex {
    return nil;
}

- (NSObject *)objectAtIndex:(NSUInteger)index{
    return nil;
}

@end
