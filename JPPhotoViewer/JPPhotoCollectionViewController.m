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
#import <Photos/Photos.h>
#import <NYTPhotoViewer/NYTPhotosViewController.h>
#import <AVFoundation/AVFoundation.h>
#import "CHTCollectionViewWaterfallLayout.h"
#import "JPPhotoCollectionViewCell.h"
#import "NJKScrollFullScreen.h"
#import "UIViewController+NJKFullScreenSupport.h"
@interface JPPhotoCollectionViewController () <NYTPhotosViewControllerDelegate,CHTCollectionViewDelegateWaterfallLayout,NJKScrollFullscreenDelegate>
@property (weak, nonatomic) IBOutlet UISlider *gridSizeSlider;
@property (nonatomic) NSInteger columnCount;
@property (weak, nonatomic) IBOutlet UIStepper *columnCountStepper;
@property (nonatomic) NJKScrollFullScreen *scrollProxy;
@end


@implementation JPPhotoCollectionViewController {
    NSInteger preColumnCount;
}
static NSString * const reuseIdentifier = @"PhotoCell";

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

    // レイアウトのパラメータ設定
    CHTCollectionViewWaterfallLayout *t = (CHTCollectionViewWaterfallLayout * )self.collectionViewLayout;
    
    t.columnCount = self.columnCount;
    t.minimumColumnSpacing = self.columnCount;
    
    UILongPressGestureRecognizer * longPressRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressAction:)];
    longPressRecognizer.allowableMovement = 10;
    longPressRecognizer.minimumPressDuration = 0.5;
    [self.collectionView addGestureRecognizer:longPressRecognizer];
    
    // NJKScrollFullScreenの生成
    self.scrollProxy = [[NJKScrollFullScreen alloc] initWithForwardTarget:self];
    self.collectionView.delegate = (id)self.scrollProxy;
    self.scrollProxy.delegate = self;
    
    
    self.columnCountStepper.value = self.columnCount;
    
    // スワイプで戻る
    UIPanGestureRecognizer *swipe = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
    [self.view addGestureRecognizer:swipe];

    
    [super viewDidLoad];
}

// コレクションビューの長押しで操作アクションシートを出す
-(void)longPressAction:(UILongPressGestureRecognizer *)sender{
    
    CGPoint location = [sender locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    if (indexPath){
        if (sender.state == UIGestureRecognizerStateBegan){
            JPPhoto *p = self.photos[indexPath.row];
            [self showOperationSheet:p parentVC:self location:location];
        }
    }
}
// スワイプで閉じる
- (void) swipe:(UIPanGestureRecognizer*) sender {
    CGPoint p = [sender translationInView:self.view];

    if (p.x > 10){
        [self didCloseView:nil];
    }
}

// 写真のファイルを削除します。
-(void)removePhotoFile:(NSIndexPath*)indexPath{
    JPPhoto *p = self.photos[indexPath.row];
    [p removeOriginal];

    [self.photos removeObject:p];
    [self.collectionView performBatchUpdates:^ {
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]]; // no assertion now
    } completion:nil];
    
    // JSONを上書き
    [JPPhotoModel saveToJsonWithPhotos:self.photos directortyPath:self.photoDirectory];
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
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if (!app.isPassCodeViewShown){
        if (!self.photos){
            self.photos = [JPPhotoModel photosWithDirectoryName:self.photoDirectory showProgress:YES];
            [self updateThumbnailSize];
        }
        self.collectionView.hidden = NO;
    }
    
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    
    [self hideNavigationBar:YES];
    [super viewWillAppear:animated];
}
-(void)viewWillDisappear:(BOOL)animated{
    self.photos = nil;
    [super viewWillDisappear:animated];
}
-(void)viewDidDisappear:(BOOL)animated{
    self.collectionView.hidden = YES;
    [super viewDidDisappear:animated];
}

-(void)hideNavigationBarAfterDuration{
    // NavigationBarを非表示にする
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self hideNavigationBar:YES];
    });
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.collectionView contentOffset].y == 0){
        [self hideNavigationBarAfterDuration];
    }
}

- (IBAction)didCloseView:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    
    for (JPPhoto *p in self.photos) {
        p.image = nil;
    }
    self.photos = nil;
    self.collectionView = nil;
}

- (IBAction)thumbnailSizeChange:(id)sender {
    UIStepper * s = (UIStepper *)sender;
    [self changeThumbnailSize:s.value];
}

-(void)changeThumbnailSize:(NSInteger)size{
    NSInteger preChangeColumnCount = self.columnCount;
    if (size <= 0){
        size = 1;
    }else if (size >= 10){
        size = 10;
    }
    self.columnCount = size;
    
    [self updateThumbnailSize];
    
    if (preChangeColumnCount != self.columnCount){
        CHTCollectionViewWaterfallLayout *t = (CHTCollectionViewWaterfallLayout * )self.collectionViewLayout;
        t.columnCount = self.columnCount;
        [self.collectionView reloadData];
        
        [[NSUserDefaults standardUserDefaults] setInteger:self.columnCount forKey:@"columnCount"];
    }
}

// JPPhotoのサムネサイズの指定を変更
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
            [cell loadImage];
            
            // パッと出るよりモヤッとでたほうがいいらしい。
            [cell imageView].alpha = 0;
            [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^ {
                [cell imageView].alpha = 1;
            } completion:nil];
        });
    });

    return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // サムネイルをタップした時に拡大するビューを表示する
    NYTPhotosViewController * photosViewController = [[NYTPhotosViewController alloc] initWithPhotos:self.photos initialPhoto:self.photos[indexPath.row]];
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


- (BOOL)photosViewController:(NYTPhotosViewController *)photosViewController handleLongPressForPhoto:(id <NYTPhoto>)photo withGestureRecognizer:(UILongPressGestureRecognizer *)longPressGestureRecognizer{
    
    
    CGPoint location = [longPressGestureRecognizer locationInView:[photosViewController view]];
    // 写真のインデックス
    JPPhoto *current = photosViewController.currentlyDisplayedPhoto;
    [self showOperationSheet:current parentVC:photosViewController location:location];
    
    return YES;
}

// 操作のアクションシートを表示する
-(void)showOperationSheet:(JPPhoto *)current parentVC:(UIViewController *)vc location:(CGPoint)loc{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"操作"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"カメラロールに保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self savePhotoToCameraroll:current.imagePath parentVC:vc];
    }]];
    
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"削除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        // 削除する
        UIAlertController *al = [UIAlertController alertControllerWithTitle:@"削除"
                                                                    message:@"削除します。よろしいですか？"
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
        
        [al addAction:[UIAlertAction actionWithTitle:@"はい" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            NSUInteger index = [self.photos indexOfObject:current];
            [self removePhotoFile:[NSIndexPath indexPathForRow:index inSection:0]];
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        [al addAction:[UIAlertAction actionWithTitle:@"いいえ" style:UIAlertActionStyleDefault handler:nil]];
        
        al.popoverPresentationController.sourceView = vc.view;
        al.popoverPresentationController.sourceRect = CGRectMake(loc.x, loc.y , 20 , 20);
        
        [vc presentViewController:al animated:YES completion:nil];
        return;
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"キャンセル" style:UIAlertActionStyleCancel handler:nil]];
    alertController.popoverPresentationController.sourceView = vc.view;
    alertController.popoverPresentationController.sourceRect = CGRectMake(loc.x, loc.y , 20 , 20);
    
    [vc presentViewController:alertController animated:YES completion:nil];
}

// カメラロールに写真を保存する
-(void)savePhotoToCameraroll:(NSString *)photoUrl parentVC:(UIViewController *)vc{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        NSString *urlEncode =[photoUrl stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
        NSURL *fileUrl = [NSURL URLWithString:urlEncode];
        [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:fileUrl];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (!success){
            NSLog(@"error:%@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"失敗"
                                                                                         message:@"写真の保存でエラーが発生しました。"
                                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
                [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [vc presentViewController:alertController animated:YES completion:nil];
            });
        }
    }];
}

#pragma mark NJKScrollFullScreen のデリゲート
- (void)scrollFullScreen:(NJKScrollFullScreen *)proxy scrollViewDidScrollUp:(CGFloat)deltaY
{
    [self moveNavigationBar:deltaY animated:YES];
    [self moveToolbar:-deltaY animated:YES];
}

- (void)scrollFullScreen:(NJKScrollFullScreen *)proxy scrollViewDidScrollDown:(CGFloat)deltaY
{
    [self moveNavigationBar:deltaY animated:YES];
    [self moveToolbar:-deltaY animated:YES];
}

- (void)scrollFullScreenScrollViewDidEndDraggingScrollUp:(NJKScrollFullScreen *)proxy
{
    [self hideNavigationBar:YES];
    [self hideToolbar:YES];
}

- (void)scrollFullScreenScrollViewDidEndDraggingScrollDown:(NJKScrollFullScreen *)proxy
{
    [self showNavigationBar:YES];
    [self showToolbar:YES];
}

@end
