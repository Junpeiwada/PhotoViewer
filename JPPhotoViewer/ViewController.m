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
}
- (IBAction)sliderChanged:(id)sender {
    self.columnCountSlider.value = (int)self.columnCountSlider.value;
    self.debugLabel.text = [NSString stringWithFormat:@"%d",(int)self.columnCountSlider.value];
}
- (IBAction)sliderValueChanged:(id)sender {
    self.debugLabel.text = [NSString stringWithFormat:@"%d",(int)self.columnCountSlider.value];
}

-(void)viewWillAppear:(BOOL)animated{
    [self.tableView reloadData];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
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
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    cell.textLabel.text = [self.directoryNames objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!self.collectionView){
        // コレクションビューを表示する
        UINavigationController *navi = [[self storyboard] instantiateViewControllerWithIdentifier:@"collectionViewNavi"];
        self.collectionView = (JPPhotoCollectionViewController *)navi.topViewController;
    }
    
    [self.collectionView.collectionView setContentOffset:CGPointMake(0, 0)];
    
    self.collectionView.photoDirectory = [self.directorys objectAtIndex:indexPath.row];
    
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
