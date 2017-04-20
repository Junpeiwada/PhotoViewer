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
#import "JPPath.h"
#import <SVProgressHUD.h>

@implementation JPPhotoModel

+ (BOOL)isExistIndexWithDirectoryName:(NSString *)directoryPath{
    NSString *pListPath = [JPPath jsonPath:directoryPath];
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:pListPath]){
        return YES;
    }
    return NO;
}

+ (NSMutableArray *)exifFilter:(NSArray *)photos{
    // EXIFフィルター
    NSMutableArray *filteredPhoto = [NSMutableArray array];
    for (JPPhoto *p in photos) {
        if (p.existEXIF){
            [filteredPhoto addObject:p];
        }
    }
    return filteredPhoto;
}

+ (NSMutableArray *)photosWithDirectoryName:(NSString *)directoryPath showProgress:(BOOL)showProgress{
    
    NSMutableArray *photos;
    
    // すでにインデックスがあればそれを使う
    photos = [[self loadPhotosFromJsonWithDirectortyPath:directoryPath]mutableCopy];
    if (photos){
        for (JPPhoto *p in photos) {
            p.directryName = directoryPath.lastPathComponent;
        }
        
        // EXIFフィルター
        if ([[NSUserDefaults standardUserDefaults]boolForKey:@"exifFilter"]){
            photos = [self exifFilter:photos];
        }
       
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
            if (showProgress){
                [SVProgressHUD showProgress:(float)i/(float)files.count status:@"写真の一覧を作っています"];
            }
            
        }
        NSString *fileName = files[i];

        if (![[fileName uppercaseString] hasSuffix:@"JPG"]){
            if (![[fileName uppercaseString] hasSuffix:@"JPEG"]){
                continue;
            }
        }
        
        JPPhoto *photo = [[JPPhoto alloc] init];
        
        photo.imagePath = [NSString stringWithFormat:@"%@/%@",directoryPath,fileName];
        photo.thumbnailPath = [JPPath thumbnailPathWithDirectory:directoryPath filename:fileName];
        photo.directryName = directoryPath.lastPathComponent;
        
        // メタデータを取り出し
        NSURL *filePath = [NSURL fileURLWithPath:photo.imagePath];
        
        CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)(filePath), nil);
        NSDictionary *metadata = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
        CFRelease(source);
        
        
        NSMutableString *credit = [NSMutableString string];
        {
            NSDictionary *tiff = [metadata objectForKey:(NSString *)kCGImagePropertyTIFFDictionary];
            
            // 機種名
            NSString *model =[tiff objectForKey:(NSString *)kCGImagePropertyTIFFModel];
            if (model){
                [credit appendString:@"📷:"];
                [credit appendString:model];
            }else{
                //                continue;
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
                    photo.existEXIF = YES;
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
                    photo.existEXIF = YES;
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
                photo.existEXIF = YES;
            }
            
            // 35mm換算の焦点距離
            NSNumber *focallength35 =[exif objectForKey:(NSString *)kCGImagePropertyExifFocalLenIn35mmFilm];
            if (focallength35){
                [caption appendString:@"\n35mm換算:"];
                [caption appendString:[focallength35 description]];
                [caption appendString:@"mm"];
                photo.existEXIF = YES;
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
                photo.existEXIF = YES;
            }else{
                // Exif AUX
                // Exif 2.3以前にはレンズモデルがないので、拡張領域を読み取る
                NSDictionary *exifaux = [metadata objectForKey:(NSString *)kCGImagePropertyExifAuxDictionary];
                NSString *lensModel =[exifaux objectForKey:(NSString *)kCGImagePropertyExifAuxLensModel];
                if (lensModel){
                    [caption appendString:@"\nレンズモデル:"];
                    [caption appendString:lensModel];
                    photo.existEXIF = YES;
                }
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
    if (showProgress){
        [SVProgressHUD showProgress:1.0 status:@"完了"];
    }
    
    // 日付順に並び替え
    NSArray * result = [photos sortedArrayUsingComparator:^NSComparisonResult(JPPhoto * obj1, JPPhoto *  obj2) {
        NSStringCompareOptions compareOptions = (NSCaseInsensitiveSearch);
        
        if (obj1.originalDateString == nil & obj2.originalDateString == nil){
            return NSOrderedSame;
        }
        if (obj1.originalDateString == nil & obj2.originalDateString != nil){
            return NSOrderedDescending;
        }
        if (obj1.originalDateString != nil & obj2.originalDateString == nil){
            return NSOrderedAscending;
        }
        
        return [obj1.originalDateString compare:obj2.originalDateString options:compareOptions];
    }];
    
    
    for (JPPhoto * p in result) {
        NSLog(@"%@", p.originalDateString);
    }
    
    // 保存
    [self saveToJsonWithPhotos:result directortyPath:directoryPath];
    
    // EXIFフィルター
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"exifFilter"]){
        result = [self exifFilter:result];
    }
    
    return [result mutableCopy];
}

// JPPhotoのArrayを、撮影日付ごとに分けます。
+(NSMutableArray *)splitPhotosByOriginalDate:(NSMutableArray *)photos{
    NSMutableArray *photoSections = [NSMutableArray array];
    NSString * current;
    
    NSMutableArray *section = [NSMutableArray array];
    for (JPPhoto * p in photos) {
        // キーを読み取る
        if (current == nil){
            if (p.originalDateString.length > 10){
                current = [p.originalDateString substringToIndex:10];
            }else{
                current = @"NULL";
            }
        }
        
        NSLog(@"%@", current);
        
        if (p.originalDateString.length > 10){
            if ([p.originalDateString hasPrefix:current]){
                [section addObject:p];
            }else{
                [photoSections addObject:section];
                section = [NSMutableArray array];
                [section addObject:p];
                current = nil;
            }
        }else{
            [section addObject:p];
        }
    }
    
    [photoSections addObject:section];
    
    return photoSections;
}

// JPPhotoからJsonを作成し、指定されたディレクトリに保存します。
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
        
        [pdic setObject:[NSNumber numberWithBool:p.existEXIF] forKey:@"existEXIF"];
        
        [saveTarget addObject:pdic];
    }
    
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:saveTarget options:0 error:nil];
    [data writeToFile:[JPPath jsonPath:directoryPath] atomically:YES];
}

// 指定されたディレクトリのJSONを読み込んで、JPPhotoのArrayを返します。
+(NSArray *)loadPhotosFromJsonWithDirectortyPath:(NSString *)directoryPath{
    NSString *pListPath = [JPPath jsonPath:directoryPath];
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:pListPath]){
        NSData *data = [NSData dataWithContentsOfFile:pListPath];
        NSArray * photos = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        NSMutableArray *result = [NSMutableArray array];
        
        for (NSDictionary *dic in photos) {
            JPPhoto *photo = [[JPPhoto alloc] init];
            
            photo.imagePath = [NSString stringWithFormat:@"%@/%@",directoryPath, [dic objectForKey:@"imagePath"]];
            photo.thumbnailPath = [JPPath thumbnailPathWithDirectory:directoryPath filename:[dic objectForKey:@"imagePath"]];
            photo.thumbnailSize = 300;
            
            photo.width = [[dic objectForKey:@"width"]integerValue];
            photo.height = [[dic objectForKey:@"height"]integerValue];
            
            photo.originalDateString =[dic objectForKey:@"originalDateString"];
            
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
            
            photo.existEXIF = [[dic objectForKey:@"existEXIF"]boolValue];
            
            
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
                // JSONの削除
                [[NSFileManager defaultManager] removeItemAtPath:[JPPath jsonPath:fullPath] error:nil];
            }
        }
    }
}
+ (NSArray*)fileNamesAtDirectoryPath:(NSString*)directoryPath
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
+(void)removeAllThumb{
    // すべてのサムネを削除
    NSArray *imgFileNames = [self fileNamesAtDirectoryPath:NSTemporaryDirectory() ];
    for (NSString *fileName in imgFileNames) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@",NSTemporaryDirectory(),fileName];
        
        NSError *error=nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (error!=nil) {
            NSLog(@"削除に失敗 %@",[error localizedDescription]);
        }else{
            //            NSLog(@"Successfully removed:%@",filePath);
        }
    }
    
    // ちっこいサムネも削除
    NSString *thumbDirectoryPath = [JPPath tableViewHeaderThumbDirectoryPath];
    NSArray *thumbNames = [self fileNamesAtDirectoryPath:thumbDirectoryPath];
    for (NSString *fileName in thumbNames) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@",thumbDirectoryPath,fileName];
        
        NSError *error=nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (error!=nil) {
            NSLog(@"削除に失敗 %@",[error localizedDescription]);
        }else{
            //            NSLog(@"Successfully removed:%@",filePath);
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
            // JOSONの削除
            [[NSFileManager defaultManager] removeItemAtPath:[JPPath jsonPath:fullPath] error:nil];
        }
    }
}

// 指定されたドキュメントディレクトリのフォルダを削除します
+(void)removeDirectory:(NSString *)directoryname{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    BOOL dir;
    
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@",documentsDirectory,directoryname];
    if ( [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&dir] ){
        if ( dir ){
            NSError *error = nil;
            if (![[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error]){
                NSLog(@"%@", [error description]);
            }
        }
    }
}





@end
