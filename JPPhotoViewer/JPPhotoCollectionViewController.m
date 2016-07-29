//
//  JPPhotoCollectionViewController.m
//  NYTPhotoViewer
//
//  Created by junpeiwada on 2016/05/07.
//  Copyright © 2016年 junpeiwada. All rights reserved.
//

#import "AppDelegate.h"
#import "JPPhotoCollectionViewController.h"
#import "JPPhotoModel.h"
#import "JPPhoto.h"
#import <NYTPhotoViewer/NYTPhotosViewController.h>
#import <AVFoundation/AVFoundation.h>
#import "CHTCollectionViewWaterfallLayout.h"
#import "JPPhotoCollectionViewCell.h"
@interface JPPhotoCollectionViewController () <NYTPhotosViewControllerDelegate,CHTCollectionViewDelegateWaterfallLayout>
@property (weak, nonatomic) IBOutlet UISlider *gridSizeSlider;
@property (nonatomic) NSInteger columnCount;
@end


@implementation JPPhotoCollectionViewController {
    NSInteger preColumnCount;
}
static NSString * const reuseIdentifier = @"PhotoCell";

-(void)awakeFromNib{
    
}

-(void)initInstance{
    NSInteger savedColumnCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"columnCount"];
    if  (savedColumnCount == 0){
        savedColumnCount = 2;
    }
    self.columnCount = savedColumnCount;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        for (JPPhoto *p in self.photos) {
            p.image = nil;
        }
    }];
}
-(id)initWithCoder:(NSCoder *)aDecoder{
    id instance = [super initWithCoder:aDecoder];
    [self initInstance];
    return instance;
}


-(void)viewDidLoad{
    // ナビゲーションバーを出さない
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
     
    // ピンチジェスチャーの実装
    UIPinchGestureRecognizer* pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:pinchGesture];
    
    // 右スワイプで戻る
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
    swipe.direction = UISwipeGestureRecognizerDirectionRight;
    swipe.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:swipe];

    // レイアウトのパラメータ設定
    CHTCollectionViewWaterfallLayout *t = (CHTCollectionViewWaterfallLayout * )self.collectionViewLayout;
    
    t.columnCount = self.columnCount;
    t.minimumColumnSpacing = self.columnCount;
    
    UILongPressGestureRecognizer * longPressRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressAction:)];
    longPressRecognizer.allowableMovement = 10;
    longPressRecognizer.minimumPressDuration = 0.5;
    [self.collectionView addGestureRecognizer:longPressRecognizer];
    [super viewDidLoad];
}

-(void)longPressAction:(UILongPressGestureRecognizer *)sender{
    
    CGPoint location = [sender locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    if (indexPath){
        if (sender.state == UIGestureRecognizerStateBegan){
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"削除"
                                                                                     message:@"削除しますよろしいですか？"
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            
            // addActionした順に左から右にボタンが配置されます
            [alertController addAction:[UIAlertAction actionWithTitle:@"はい" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                JPPhoto *p = self.photos[indexPath.row];
                [p removeOriginal];
                [p removeThumb];
                [self.photos removeObject:p];
                [self.collectionView performBatchUpdates:^ {
                    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]]; // no assertion now
                } completion:nil];
                
                // JSONを上書き
                [JPPhotoModel saveToJsonWithPhotos:self.photos directortyPath:self.photoDirectory];
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:@"いいえ" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                // cancelボタンが押された時の処理
                return;
            }]];
            
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
}


#pragma mark - SettingStatusBar
-(BOOL)prefersStatusBarHidden {
    return YES;
}
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - View

-(void)viewWillAppear:(BOOL)animated{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    if (!app.isPassCodeViewShown){
        if (!self.photos){
            self.photos = [JPPhotoModel photosWithDirectoryName:self.photoDirectory];
            [self updateThumbnailSize];
        }
        
//        [self.collectionView reloadData];
        // ナビゲーションバーを出さない
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        self.collectionView.hidden = NO;
    }
    [super viewWillAppear:animated];
}
-(void)viewWillDisappear:(BOOL)animated{
    self.photos = nil;
    self.collectionView.hidden = YES;
    [super viewWillDisappear:animated];
}

- (IBAction)didCloseView:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    
    for (JPPhoto *p in self.photos) {
        p.image = nil;
    }
    self.photos = nil;
    self.collectionView = nil;
}

// ピンチで画像サイズを変更
- (void) handlePinchGesture:(UIPinchGestureRecognizer*) sender {
    UIPinchGestureRecognizer* pinch = (UIPinchGestureRecognizer*)sender;
    
    if (pinch.state == UIGestureRecognizerStateBegan){
        preColumnCount = self.columnCount;
    }
    
    NSInteger preChangeColumnCount = self.columnCount;
    
    if (pinch.scale > 0.5 && pinch.scale < 0.7){
        self.columnCount =  preColumnCount + 2;
    }
    if (pinch.scale > 0.7 && pinch.scale < 0.9){
        self.columnCount =  preColumnCount + 1;
    }
    if (pinch.scale > 0.9 && pinch.scale < 1.1){
        self.columnCount =  preColumnCount;
    }
    if (pinch.scale > 1.1 && pinch.scale < 1.4){
        self.columnCount =  preColumnCount - 1;
    }
    if (pinch.scale > 1.4 && pinch.scale < 1.6){
        self.columnCount =  preColumnCount - 2 ;
    }
    
    if (self.columnCount <= 0){
        self.columnCount = 1;
    }else if (self.columnCount >= 10){
        self.columnCount = 10;
    }
    
    [self updateThumbnailSize];
    
    if (preChangeColumnCount != self.columnCount){
        CHTCollectionViewWaterfallLayout *t = (CHTCollectionViewWaterfallLayout * )self.collectionViewLayout;
        t.columnCount = self.columnCount;
        [self.collectionView reloadData];
        
        [[NSUserDefaults standardUserDefaults] setInteger:self.columnCount forKey:@"columnCount"];
    }
}


-(void)updateThumbnailSize{
    CGSize s = UIScreen.mainScreen.bounds.size;
    NSInteger size = (s.width / self.columnCount) * 2.1; // Retinaだからx2かな？
    
    for (JPPhoto *p in self.photos) {
        if (MAX(p.width, p.height) < size){
            p.thumbnailSize = MAX(p.width, p.height);
        }else{
            p.thumbnailSize = size;
        }
//        NSLog(@"thumb:%ld orix:%ld y:%ld",p.thumbnailSize,p.width,p.height);
    }
}

// スワイプで閉じる
- (void) swipe:(UISwipeGestureRecognizer*) sender {
    [self didCloseView:nil];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    // アイテムの個数を返す
    return self.photos.count;
}



- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JPPhoto *photo = [self.photos objectAtIndex:indexPath.row];
    CGSize size = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(photo.width, photo.height),CGRectMake(0, 0, 300, 300)).size;
    
    // Nanの時は0にする
    if (isnan(size.height)){
        return CGSizeMake(0, 0);
    }
    return size;
}
#pragma mark collection view cell paddings
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 2.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 2.0f;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    JPPhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    JPPhoto *photo = [self.photos objectAtIndex:indexPath.row];
    cell.thumbnailPath = [photo thumbnailPathSize];
    
    // サムネをロードする
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        // サムネを作るorロードする
        [photo thumbnail];
        
        // UIThreadで表示
        dispatch_async(dispatch_get_main_queue(), ^{
            
            for (JPPhotoCollectionViewCell * jpCell in [self.collectionView visibleCells]) {
                NSIndexPath* visiblePath = [self.collectionView indexPathForCell:jpCell];
                if (visiblePath.row == indexPath.row){
                    
                    [jpCell loadImage];
                    
                    // パッと出るよりモヤッとでたほうがいいらしい。
                    [jpCell imageView].alpha = 0;
                    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^ {
                        [jpCell imageView].alpha = 1;
                    } completion:nil];
                    break;
                }
            }
        });
    });

    return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // サムネイルをタップした時に拡大するビューを表示する
    NYTPhotosViewController *photosViewController = [[NYTPhotosViewController alloc] initWithPhotos:self.photos initialPhoto:self.photos[indexPath.row]];
    photosViewController.delegate = self;
    [self presentViewController:photosViewController animated:YES completion:nil];
    
    
    JPPhoto *target =[self.photos objectAtIndex:indexPath.row];
    [self loadPhotoOnPhotosViewController:photosViewController photo:target];
    if (indexPath.row > 0 && indexPath.row < self.photos.count - 1){
        [self loadPhotoOnPhotosViewController:photosViewController photo:[self.photos objectAtIndex:indexPath.row -1]];
        [self loadPhotoOnPhotosViewController:photosViewController photo:[self.photos objectAtIndex:indexPath.row +1]];
    }
    
    return YES;
}
// 画像をロードする
-(void)loadPhotoOnPhotosViewController:(NYTPhotosViewController *)photosViewController photo:(JPPhoto *)target{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!target.image && !target.imageData) {
            target.image = [UIImage imageWithContentsOfFile:target.imagePath];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [photosViewController updateImageForPhoto:target];
            });
        }
    });
}


#pragma mark - NYTPhotosViewControllerDelegate

- (UIView *)photosViewController:(NYTPhotosViewController *)photosViewController referenceViewForPhoto:(id <NYTPhoto>)photo {
    
    JPPhoto *current = photosViewController.currentlyDisplayedPhoto;
    NSUInteger index = [self.photos indexOfObject:current];
    
    UICollectionViewCell *tempCell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    return tempCell;
}

- (UIView *)photosViewController:(NYTPhotosViewController *)photosViewController loadingViewForPhoto:(id <NYTPhoto>)photo {
    return nil;
}

- (UIView *)photosViewController:(NYTPhotosViewController *)photosViewController captionViewForPhoto:(id <NYTPhoto>)photo {
    return nil;
}

- (CGFloat)photosViewController:(NYTPhotosViewController *)photosViewController maximumZoomScaleForPhoto:(id <NYTPhoto>)photo {
    return 30.0f;
}

- (NSDictionary *)photosViewController:(NYTPhotosViewController *)photosViewController overlayTitleTextAttributesForPhoto:(id <NYTPhoto>)photo {
    return nil;
}

- (NSString *)photosViewController:(NYTPhotosViewController *)photosViewController titleForPhoto:(id<NYTPhoto>)photo atIndex:(NSUInteger)photoIndex totalPhotoCount:(NSUInteger)totalPhotoCount {
    return nil;
}

- (void)photosViewController:(NYTPhotosViewController *)photosViewController didNavigateToPhoto:(id <NYTPhoto>)photo atIndex:(NSUInteger)photoIndex {
    
    [self loadPhotoOnPhotosViewController:photosViewController photo:photo];
    if (photoIndex > 0 && photoIndex < self.photos.count - 1){
        // 前後の画像をロードしておく。スワイプ時にロード画面が表示されなくていい感じになる。
        [self loadPhotoOnPhotosViewController:photosViewController photo:[self.photos objectAtIndex:photoIndex -1]];
        [self loadPhotoOnPhotosViewController:photosViewController photo:[self.photos objectAtIndex:photoIndex +1]];
    }
}

- (void)photosViewController:(NYTPhotosViewController *)photosViewController actionCompletedWithActivityType:(NSString *)activityType {
    NSLog(@"Action Completed With Activity Type: %@", activityType);
}

- (void)photosViewControllerDidDismiss:(NYTPhotosViewController *)photosViewController {
    for (JPPhoto *p in self.photos) {
        p.image = nil;
    }
}

@end
