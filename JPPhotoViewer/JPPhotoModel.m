//
//  JPPhotoModel.m
//  NYTPhotoViewer
//
//  Created by junpeiwada on 2016/05/07.
//  Copyright © 2016年 junpeiwada. All rights reserved.
//

#import "JPPhotoModel.h"
#import <NYTPhotoViewer/NYTPhotosViewController.h>
#import <ImageIO/ImageIO.h>
#import "JPPhoto.h"
#import <SVProgressHUD.h>

@implementation JPPhotoModel

+ (BOOL)isExistIndexWithDirectoryName:(NSString *)directoryPath{
    NSString *pListPath = [self plistPath:directoryPath];
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:pListPath]){
        return YES;
    }
    return NO;
}

+ (NSArray *)photosWithDirectoryName:(NSString *)directoryPath {
    
    NSMutableArray *photos;
    
    // すでにインデックスがあればそれを使う
    photos = [[self loadPhotosFromJsonWithDirectortyPath:directoryPath]mutableCopy];
    if (photos){
        return photos;
    }
    
    // ない場合は作る
    photos = [NSMutableArray array];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
    
    float preProgress = 0;
    
    for (int i = 0; i < files.count; i++) {
        
        float progress = (float)i/(float)files.count;
        if ((progress - preProgress) > 0.2){
            preProgress = progress;
            [SVProgressHUD showProgress:(float)i/(float)files.count status:@"写真の一覧を作っています"];
        }
        NSString *fileName = files[i];

        if (![[fileName uppercaseString] hasSuffix:@"JPG"]){
            if (![[fileName uppercaseString] hasSuffix:@"JPEG"]){
                continue;
            }
        }
        
        JPPhoto *photo = [[JPPhoto alloc] init];
        
        photo.imagePath = [NSString stringWithFormat:@"%@/%@",directoryPath,fileName];
        
        
        photo.thumbnailPath = [NSString stringWithFormat:@"%@%@--%@",NSTemporaryDirectory(),directoryPath.lastPathComponent,fileName];
        
        // メタデータを取り出し
        CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:photo.imagePath]), nil);
        NSDictionary *metadata = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
        
        
        NSMutableString *credit = [NSMutableString string];
        {
            NSDictionary *tiff = [metadata objectForKey:(NSString *)kCGImagePropertyTIFFDictionary];
            
            // 機種名
            NSString *model =[tiff objectForKey:(NSString *)kCGImagePropertyTIFFModel];
            if (model){
                [credit appendString:@"機種名:"];
                [credit appendString:model];
            }
        }
        
        
  
        
        
        NSMutableString *caption = [NSMutableString string];
        {
            NSDictionary *exif = [metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary];
            
            // メタデータから画像幅を出す
            NSNumber *x = [exif objectForKey:(NSString *)kCGImagePropertyExifPixelXDimension];
            NSNumber *y = [exif objectForKey:(NSString *)kCGImagePropertyExifPixelYDimension];
            NSNumber *orientation = [metadata objectForKey:(NSString *)kCGImagePropertyOrientation];
            if (y){
                if (x){
                    switch ([orientation integerValue]) {
                        case 1:
                        case 2:
                        case 3:
                        case 4:
                            photo.width = [x integerValue];
                            photo.height = [y integerValue];
                            break;
                        case 5:
                        case 6:
                        case 7:
                        case 8:
                            photo.width = [y integerValue];
                            photo.height = [x integerValue];
                            break;
                        default:
                            break;
                    }
                }
            }
            
            
            if (photo.width <= 0 && photo.height <= 0){
                UIImage *image = [UIImage imageWithContentsOfFile:photo.imagePath];
                photo.width = image.size.width;
                photo.height = image.size.height;
            }
            
            // サイズ
            [caption appendString:[NSString stringWithFormat:@"サイズ : %ld x %ld",(long)photo.width,(long)photo.height]];
            
            
            
            // 絞り
            NSNumber *FNumber = [exif objectForKey:(NSString *)kCGImagePropertyExifFNumber];
            if (FNumber){
                if (FNumber){
                    [caption appendString:@"\n絞り:F"];
                    [caption appendString:[FNumber description]];
                }
            }
            
            // シャッター速度
            NSNumber *exposureTime = [exif objectForKey:(NSString *)kCGImagePropertyExifExposureTime];
            if (exposureTime){
                if (exposureTime){
                    [caption appendString:@"\nシャッター速度:"];
                    
                    double shutterSpeed = [exposureTime doubleValue];
                    if (shutterSpeed < 1){
                        int speedDenominator = 1 / shutterSpeed;
                        [caption appendString:[NSString stringWithFormat:@"1/%d",speedDenominator]];
                    }else{
                        [caption appendString:[exposureTime description]];
                    }
                }
            }
            
            // ISO感度
            NSArray *ISO = [exif objectForKey:(NSString *)kCGImagePropertyExifISOSpeedRatings];
            if (ISO){
                if ([ISO count] > 0){
                    [caption appendString:@"\nISO感度:"];
                    [caption appendString:(NSString *)[[ISO objectAtIndex:0] description]];
                }
            }
            
            // レンズの焦点距離（ズームの時もズーム位置の焦点距離）
            NSNumber *focallength =[exif objectForKey:(NSString *)kCGImagePropertyExifFocalLength];
            if (focallength){
                [caption appendString:@"\nレンズ焦点距離:"];
                [caption appendString:[focallength description]];
                [caption appendString:@"mm"];
            }
            
            // 35mm換算の焦点距離
            NSNumber *focallength35 =[exif objectForKey:(NSString *)kCGImagePropertyExifFocalLenIn35mmFilm];
            if (focallength35){
                [caption appendString:@"\n35mm換算:"];
                [caption appendString:[focallength35 description]];
                [caption appendString:@"mm"];
            }
            
            // 露出プログラム
            NSNumber *exposureProgram = [exif objectForKey:(NSString *)kCGImagePropertyExifExposureProgram];
            if (exposureProgram){
                [caption appendString:@"\n露出プログラム:"];
                int program = [exposureProgram intValue];
                switch (program) {
                    case 0:
                        [caption appendString:@"未定義"];
                        break;
                    case 1:
                        [caption appendString:@"マニュアル"];
                        break;
                    case 2:
                        [caption appendString:@"ノーマルプログラム"];
                        break;
                    case 3:
                        [caption appendString:@"絞り優先"];
                        break;
                    case 4:
                        [caption appendString:@"シャッター速度優先"];
                        break;
                    case 5:
                        [caption appendString:@"クリエイティブ（DOF優先）"];
                        break;
                    case 6:
                        [caption appendString:@"アクション"];
                        break;
                    case 7:
                        [caption appendString:@"ポートレート"];
                        break;
                    case 8:
                        [caption appendString:@"風景"];
                        break;
                        
                    default:
                        break;
                }
            }
            
            // 日付
            NSString *date =[exif objectForKey:(NSString *)kCGImagePropertyExifDateTimeOriginal];
            if (date){
                [caption appendString:@"\n日時:"];
                [caption appendString:date];
                photo.originalDateString = date;
            }
            
            // レンズ名
            NSString *lens =[exif objectForKey:(NSString *)kCGImagePropertyExifLensModel];
            if (lens){
                [caption appendString:@"\nレンズ:"];
                [caption appendString:lens];
            }
        }
        

        
        NSShadow * shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[UIColor blackColor]];
        [shadow setShadowOffset:CGSizeMake(0.5, -0.5)];
        
        photo.attributedCaptionTitle = [[NSAttributedString alloc] initWithString:caption attributes:
                                        @{
                                          NSForegroundColorAttributeName: [UIColor whiteColor],
                                          NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2],
                                          NSShadowAttributeName: shadow
                                          }];
        photo.attributedCaptionSummary = [[NSAttributedString alloc] initWithString:fileName attributes:
                                          @{
                                            NSForegroundColorAttributeName: [UIColor whiteColor],
                                            NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                            NSShadowAttributeName: shadow
                                            }];
        photo.attributedCaptionCredit = [[NSAttributedString alloc] initWithString:credit attributes:
                                         @{
                                           NSForegroundColorAttributeName:[UIColor grayColor],
                                           NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1],
                                           NSShadowAttributeName: shadow
                                           }];
        
        photo.thumbnailSize = 300;
        
        [photos addObject:photo];
    }
    
    [SVProgressHUD showProgress:1.0 status:@"完了"];
    
    // 日付順に並び替え
    NSArray * result = [photos sortedArrayUsingComparator:^NSComparisonResult(JPPhoto * obj1, JPPhoto *  obj2) {
        NSStringCompareOptions compareOptions = (NSCaseInsensitiveSearch);
        return [obj1.originalDateString compare:obj2.originalDateString options:compareOptions];
    }];
    
    // 保存
    [self saveToJsonWithPhotos:result directortyPath:directoryPath];
    
    return result;
}

+(NSString *)plistPath:(NSString *)directoryPath{
    NSString *pListPath = [NSString stringWithFormat:@"%@/%@",directoryPath,@"photos.plist"];
    return pListPath;
}

+(void)saveToJsonWithPhotos:(NSArray *)photos directortyPath:(NSString *)directoryPath{
    
    NSMutableArray *saveTarget = [NSMutableArray array];
    
    for (JPPhoto *p in photos) {
        NSMutableDictionary *pdic = [NSMutableDictionary dictionary];
        
        [pdic setObject:p.imagePath.lastPathComponent forKey:@"imagePath"];
        [pdic setObject:p.thumbnailPath.lastPathComponent forKey:@"thumbnailPath"];
        
        [pdic setObject:[NSNumber numberWithInteger:p.width] forKey:@"width"];
        [pdic setObject:[NSNumber numberWithInteger:p.height] forKey:@"height"];
        
        if (p.originalDateString){
            [pdic setObject:p.originalDateString forKey:@"originalDateString"];
        }
        
        
        [pdic setObject:p.attributedCaptionTitle.string forKey:@"attributedCaptionTitle"];
        [pdic setObject:p.attributedCaptionSummary.string forKey:@"attributedCaptionSummary"];
        [pdic setObject:p.attributedCaptionCredit.string forKey:@"attributedCaptionCredit"];
        
        [saveTarget addObject:pdic];
    }
    
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:saveTarget options:0 error:nil];
    [data writeToFile:[self plistPath:directoryPath] atomically:YES];
}

+(NSArray *)loadPhotosFromJsonWithDirectortyPath:(NSString *)directoryPath{
    NSString *pListPath = [self plistPath:directoryPath];
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:pListPath]){
        NSData *data = [NSData dataWithContentsOfFile:pListPath];
        NSArray * photos = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        NSMutableArray *result = [NSMutableArray array];
        
        for (NSDictionary *dic in photos) {
            JPPhoto *photo = [[JPPhoto alloc] init];
            
            photo.imagePath = [NSString stringWithFormat:@"%@/%@",directoryPath, [dic objectForKey:@"imagePath"]];
            
            
            NSString *thumbPath = [NSString stringWithFormat:@"%@%@--%@",NSTemporaryDirectory(),directoryPath.lastPathComponent,[dic objectForKey:@"imagePath"]];
            
            photo.thumbnailPath = thumbPath;
            
            photo.width = [[dic objectForKey:@"width"]integerValue];
            photo.height = [[dic objectForKey:@"height"]integerValue];
            
            photo.originalDateString =[dic objectForKey:@"thumbnailPath"];
            
            NSShadow * shadow = [[NSShadow alloc] init];
            [shadow setShadowColor:[UIColor blackColor]];
            [shadow setShadowOffset:CGSizeMake(0.5, -0.5)];
            photo.attributedCaptionTitle = [[NSAttributedString alloc] initWithString:[dic objectForKey:@"attributedCaptionTitle"] attributes:
                                            @{
                                              NSForegroundColorAttributeName: [UIColor whiteColor],
                                              NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2],
                                              NSShadowAttributeName: shadow
                                              }];
            photo.attributedCaptionSummary = [[NSAttributedString alloc] initWithString:[dic objectForKey:@"attributedCaptionSummary"] attributes:
                                              @{
                                                NSForegroundColorAttributeName: [UIColor whiteColor],
                                                NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                                NSShadowAttributeName: shadow
                                                }];
            photo.attributedCaptionCredit = [[NSAttributedString alloc] initWithString:[dic objectForKey:@"attributedCaptionCredit"] attributes:
                                             @{
                                               NSForegroundColorAttributeName:[UIColor grayColor],
                                               NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1],
                                               NSShadowAttributeName: shadow
                                               }];
            
            photo.thumbnailSize = 300;
            [result addObject:photo];

        }
        
        return result;
    }
    return nil;
}

+(void)removeAllIndex{
    // インデックスをすべて削除
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    for (NSString *path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil] )
    {
        BOOL dir;
        
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@",documentsDirectory,path];
        
        if ( [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&dir] ){
            if ( dir ){
                [[NSFileManager defaultManager] removeItemAtPath:[JPPhotoModel plistPath:fullPath] error:nil];
            }
        }
    }
}

+(void)removeIndex:(NSString *)directoryname{
    // 指定されたインデックスを削除
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    BOOL dir;
    
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@",documentsDirectory,directoryname];
    
    if ( [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&dir] ){
        if ( dir ){
            [[NSFileManager defaultManager] removeItemAtPath:[JPPhotoModel plistPath:fullPath] error:nil];
        }
    }
}

// していされたドキュメントディレクトリのフォルダを削除します
+(void)removeDirectory:(NSString *)directoryname{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    BOOL dir;
    
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@",documentsDirectory,directoryname];
    if ( [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&dir] ){
        if ( dir ){
            [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
        }
    }
}





@end
