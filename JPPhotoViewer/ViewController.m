//
//  ViewController.m
//  JPPhotoViewer
//
//  Created by junpeiwada on 2016/05/10.
//  Copyright © 2016年 soneru. All rights reserved.
//
#import <ImageIO/ImageIO.h>
#import "ViewController.h"
#import "JPPhoto.h"
#import "JPPhotoModel.h"
#import "JPPhotoCollectionViewController.h"

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
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}
- (IBAction)lockSwitchChanged:(id)sender {
    UISwitch *s = sender;
    
    [[NSUserDefaults standardUserDefaults]setBool:s.on forKey:@"useLock"];
    
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
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
    [self.navigationController pushViewController:self.collectionView animated:YES];
}

- (IBAction)reloadData:(id)sender {
    [self.tableView reloadData];
    
    // ついでにキャッシュを削除
    JPPhoto *t = [[JPPhoto alloc]init];
    [t remove];
}

@end
