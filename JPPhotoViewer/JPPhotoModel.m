//
//  JPPhotoModel.m
//  NYTPhotoViewer
//
//  Created by junpeiwada on 2016/05/07.
//  Copyright © 2016年 NYTimes. All rights reserved.
//

#import "JPPhotoModel.h"
#import <NYTPhotoViewer/NYTPhotosViewController.h>
#import <ImageIO/ImageIO.h>
#import "NYTExamplePhoto.h"

@implementation JPPhotoModel
+ (NSArray *)newTestPhotosWithDirectoryName:(NSString *)directoryPath {
    NSMutableArray *photos = [NSMutableArray array];
    
    NSString* fileName;
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];
    while(fileName = [dirEnum nextObject]) {
        // 拡張子がJPG以外は無視。MOVも無視かな・・・
        if (![[fileName uppercaseString] hasSuffix:@"JPG"]){
            continue;
        }
        
        NYTExamplePhoto *photo = [[NYTExamplePhoto alloc] init];
        
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
            
            
            
            
            // 絞り
            NSNumber *FNumber = [exif objectForKey:(NSString *)kCGImagePropertyExifFNumber];
            if (FNumber){
                if (FNumber){
                    [caption appendString:@"絞り:F"];
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
        
        [photos addObject:photo];
    }
    
    return photos;
}
@end
