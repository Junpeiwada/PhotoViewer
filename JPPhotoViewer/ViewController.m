//
//  ViewController.m
//  JPPhotoViewer
//
//  Created by junpeiwada on 2016/05/10.
//  Copyright © 2016年 soneru. All rights reserved.
//
#import "AppDelegate.h"
#import <ImageIO/ImageIO.h>
#import "ViewController.h"
#import "JPPhoto.h"
#import "JPPhotoModel.h"
#import "JPPhotoCollectionViewController.h"
#import <SVProgressHUD.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *debugLabel;

@property (nonnull) NSMutableArray *directorys;
@property (nonnull) NSMutableArray *directoryNames;
@property (nonatomic) NSArray *photos;
@property (weak, nonatomic) IBOutlet UISlider *columnCountSlider;

@property (nonatomic) JPPhotoCollectionViewController * collectionView;
@end

@implementation ViewController


-(void)viewDidLoad{
    self.debugLabel.text = [NSString stringWithFormat:@"%d",(int)self.columnCountSlider.value];
    [super viewDidLoad];
}
- (IBAction)sliderChanged:(id)sender {
    self.columnCountSlider.value = (int)self.columnCountSlider.value;
    self.debugLabel.text = [NSString stringWithFormat:@"%d",(int)self.columnCountSlider.value];
}
- (IBAction)sliderValueChanged:(id)sender {
    self.debugLabel.text = [NSString stringWithFormat:@"%d",(int)self.columnCountSlider.value];
}

-(void)viewWillAppear:(BOOL)animated{
    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
    [super viewWillAppear:animated];
}
-(void)viewDidAppear:(BOOL)animated{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    [super viewDidAppear:animated];
}



#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    if (app.isPassCodeViewShown){
        // ロック中は見せない
        return 0;
    }
    
    self.directorys = [NSMutableArray array];
    self.directoryNames = [NSMutableArray array];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    for (NSString *path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil] )
    {
        BOOL dir;
        
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@",documentsDirectory,path];
        
        if ( [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&dir] ){
            if ( dir ){
                [self.directorys addObject:fullPath];
                [self.directoryNames addObject:path];
            }
        }
    }
    
    return self.directorys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"DirectoryCell";
    UITableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // サムネのリセット
    for (NSInteger i = 10; i<14; i++) {
        UIImageView *image = [cell viewWithTag:i];
        image.image = nil;
        image.alpha = 0;
    }
    
    // 4つのちっこいサムネを表示する。（cellがキャプチャされているから不正な表示になるかもしれないけど・・まあ
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        for (NSInteger i = 10; i<14; i++) {
            NSString *path = self.directorys[indexPath.row];
            NSString *imagePath =[NSString stringWithFormat:@"%@%@--%ld%@",NSTemporaryDirectory(),path.lastPathComponent,i,@".jpg"];
            
            UIImageView *image = [cell viewWithTag:i];
            if ( [[NSFileManager defaultManager] fileExistsAtPath:imagePath isDirectory:nil] ){
                dispatch_async(dispatch_get_main_queue(), ^{
                    image.image = [UIImage imageWithContentsOfFile:imagePath];
                    image.alpha = 0;
                    [UIView animateWithDuration:1.0f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^ {
                        image.alpha = 1;
                    } completion:nil];
                });
            }else{
                image.image = nil;
            }
        }
    });
    
    // ラベルに表示
    UILabel *mainLabel = [cell viewWithTag:1];
    UILabel *countLabel = [cell viewWithTag:2];
    
    mainLabel.text = [self.directoryNames objectAtIndex:indexPath.row];
    
    NSInteger fileCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.directorys[indexPath.row] error:nil] count];
    countLabel.text = [NSString stringWithFormat:@"%ld",fileCount - 1];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    UINavigationController *navi = [[self storyboard] instantiateViewControllerWithIdentifier:@"collectionViewNavi"];
    self.collectionView = (JPPhotoCollectionViewController *)navi.topViewController;
    
    [self.collectionView.collectionView setContentOffset:CGPointMake(0, 0)];
    
    self.collectionView.photoDirectory = [self.directorys objectAtIndex:indexPath.row];
    
    self.collectionView.title = [self.directoryNames objectAtIndex:indexPath.row];
    
    // データロードのためにプログレスを表示
    if (![JPPhotoModel isExistIndexWithDirectoryName:self.collectionView.photoDirectory]){
        [SVProgressHUD showWithStatus:@"写真の一覧を作っています"];
    }
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // データをロード
        self.collectionView.photos = [JPPhotoModel photosWithDirectoryName:self.collectionView.photoDirectory];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController pushViewController:self.collectionView animated:YES];
            [SVProgressHUD dismiss];
        });
    });
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @[
             [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                title:@"削除"
                                              handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                  // own delete action
//                                                  [self.list removeObjectAtIndex:indexPath.row];
                                                  NSString *direc = [self.directoryNames objectAtIndex:indexPath.row];
                                                  [JPPhotoModel removeDirectory:direc];
                                                  
                                                  [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                              }],
             [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                title:@"インデックスの削除"
                                              handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                  // own action
                                                  
                                                  NSString *direc = [self.directoryNames objectAtIndex:indexPath.row];
                                                  [JPPhotoModel removeIndex:direc];
                                                  
                                                  [tableView setEditing:NO animated:YES];
                                              }],
             ];
}

- (IBAction)showSetting:(id)sender {
    // コレクションビューを表示する
    UIViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"settings"];
    [self.navigationController pushViewController:vc animated:YES];

}


@end
