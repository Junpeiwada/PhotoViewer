//
//  JPPhotoCollectionViewController.m
//  NYTPhotoViewer
//
//  Created by junpeiwada on 2016/05/07.
//  Copyright © 2016年 NYTimes. All rights reserved.
//

#import "JPPhotoCollectionViewController.h"
#import "JPPhotoModel.h"
#import "NYTExamplePhoto.h"
#import <NYTPhotoViewer/NYTPhotosViewController.h>
#import <AVFoundation/AVFoundation.h>
#import "CHTCollectionViewWaterfallLayout.h"
@interface JPPhotoCollectionViewController () <NYTPhotosViewControllerDelegate,CHTCollectionViewDelegateWaterfallLayout>
@property (weak, nonatomic) IBOutlet UISlider *gridSizeSlider;
@property (nonatomic) NSInteger columnCount;
@property double gridSize;
@end


@implementation JPPhotoCollectionViewController {
    dispatch_semaphore_t semaphore_;
    BOOL pinchBegan_;
}
static NSString * const reuseIdentifier = @"PhotoCell";

-(void)awakeFromNib{
    
    double savedSize = [[NSUserDefaults standardUserDefaults] doubleForKey:@"gridSize"];
    if (savedSize == 0){
        savedSize =(self.view.frame.size.width - 2 )/ 2 ;
    }
    self.gridSize = savedSize;
    self.gridSizeSlider.value = self.gridSize;


}

-(void)initInstance{
    semaphore_ = dispatch_semaphore_create(3);
    
    NSInteger savedCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"columnCount"];
    if  (savedCount == 0){
        savedCount = 2;
    }
    self.columnCount = savedCount;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        for (NYTExamplePhoto *p in self.photos) {
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
    // ナビゲーションバーの見た目を調整
    self.navigationController.navigationBar.alpha = 0.1;
    self.navigationController.navigationBar.translucent  = YES;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    self.navigationController.navigationBar.hidden = YES;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    
    // レイアウトのパラメータ設定
    CHTCollectionViewWaterfallLayout *t = (CHTCollectionViewWaterfallLayout * )self.collectionViewLayout;
    
    t.columnCount = self.columnCount;
    t.minimumColumnSpacing = self.columnCount;
    
    // ピンチジェスチャーの実装
    UIPinchGestureRecognizer* pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:pinchGesture];
    
    // 右スワイプの実装
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
    swipe.direction = UISwipeGestureRecognizerDirectionRight;
    swipe.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:swipe];
    
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(void)viewWillAppear:(BOOL)animated{
    // データを初期化する
    self.photos = [JPPhotoModel newTestPhotosWithDirectoryName:self.photoDirectory];
    [self.collectionView reloadData];
}
-(void)viewWillDisappear:(BOOL)animated{
    self.photos = nil;
}

- (IBAction)didCloseView:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    
    for (NYTExamplePhoto *p in self.photos) {
        p.image = nil;
    }
    self.photos = nil;
}

// ピンチで閉じる
- (void) handlePinchGesture:(UIPinchGestureRecognizer*) sender {
    UIPinchGestureRecognizer* pinch = (UIPinchGestureRecognizer*)sender;
    
    if (pinch.state == UIGestureRecognizerStateBegan){
        pinchBegan_ = YES;
    }
    
    if (!pinchBegan_){
        return;
    }
    
    
    if (pinch.scale < 0.9){
        self.columnCount =  self.columnCount + 1;
        pinchBegan_ = NO;
    }
    if (pinch.scale > 1.1){
        self.columnCount =  self.columnCount - 1;
        pinchBegan_ = NO;
        
    }
    
    if (self.columnCount <= 0){
        self.columnCount = 1;
    }
    
    CHTCollectionViewWaterfallLayout *t = (CHTCollectionViewWaterfallLayout * )self.collectionViewLayout;
    t.columnCount = self.columnCount;
    [self.collectionView reloadData];
    
    [[NSUserDefaults standardUserDefaults] setInteger:self.columnCount forKey:@"columnCount"];
    
}
// スワイプで閉じる
- (void) swipe:(UISwipeGestureRecognizer*) sender {
    [self didCloseView:nil];
}

- (IBAction)gridSizeChanged:(id)sender {
    UISlider *slider = sender;
    self.gridSize = slider.value;
    if (self.gridSize > self.view.frame.size.width){
        self.gridSize = self.view.frame.size.width;
    }
    [self.collectionView reloadData];
    
    [[NSUserDefaults standardUserDefaults] setDouble:self.gridSize forKey:@"gridSize"];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    // アイテムの個数を返す
    return self.photos.count;
}



- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NYTExamplePhoto *photo = [self.photos objectAtIndex:indexPath.row];
    CGSize size = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(photo.width, photo.height),CGRectMake(0, 0, self.gridSize, self.gridSize)).size;
    
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
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    UIImageView *image = (UIImageView *)[cell viewWithTag:1];
    image.image = nil;
    
    NYTExamplePhoto *photo = [self.photos objectAtIndex:indexPath.row];
    
    // サムネをロードする
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        BOOL alreadyExistThumb;
        UIImage *thumb;
        if ([photo isExistThumbFile]){
            thumb = [photo thumbnail];
            alreadyExistThumb = YES;
        }else{
            // ロードするときにサムネを作るので、あんまりたくさんのThreadで実行してはだめ。
            dispatch_semaphore_wait(semaphore_, DISPATCH_TIME_FOREVER);
            thumb = [photo thumbnail];
            dispatch_semaphore_signal(semaphore_);
            alreadyExistThumb = NO;
        }
        
        // UIThreadで表示
        dispatch_async(dispatch_get_main_queue(), ^{
            image.image =thumb;
            
                // パッと出るよりモヤッとでたほうがいいらしい。
                image.alpha = 0;
            if (alreadyExistThumb){
                [UIView animateWithDuration:0.1f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^ {
                    image.alpha = 1;
                } completion:nil];
            }else{
                [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^ {
                    image.alpha = 1;
                } completion:nil];
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
    
    
    NYTExamplePhoto *target =[self.photos objectAtIndex:indexPath.row];
    [self loadPhotoOnPhotosViewController:photosViewController photo:target];
    if (indexPath.row > 0 && indexPath.row < self.photos.count - 1){
        [self loadPhotoOnPhotosViewController:photosViewController photo:[self.photos objectAtIndex:indexPath.row -1]];
        [self loadPhotoOnPhotosViewController:photosViewController photo:[self.photos objectAtIndex:indexPath.row +1]];
    }
    
    return YES;
}
// 画像をロードする
-(void)loadPhotoOnPhotosViewController:(NYTPhotosViewController *)photosViewController photo:(NYTExamplePhoto *)target{
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
    
    NYTExamplePhoto *current = photosViewController.currentlyDisplayedPhoto;
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
        [self loadPhotoOnPhotosViewController:photosViewController photo:[self.photos objectAtIndex:photoIndex -1]];
        [self loadPhotoOnPhotosViewController:photosViewController photo:[self.photos objectAtIndex:photoIndex +1]];
    }
}

- (void)photosViewController:(NYTPhotosViewController *)photosViewController actionCompletedWithActivityType:(NSString *)activityType {
    NSLog(@"Action Completed With Activity Type: %@", activityType);
}

- (void)photosViewControllerDidDismiss:(NYTPhotosViewController *)photosViewController {
//    NSLog(@"Did Dismiss Photo Viewer: %@", photosViewController);
    for (NYTExamplePhoto *p in self.photos) {
        p.image = nil;
    }
}

@end
