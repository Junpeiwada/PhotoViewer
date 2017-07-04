//
//  SettingsVC.m
//  JPPhotoViewer
//
//  Created by JunpeiWada on 2016/05/27.
//  Copyright © 2016年 soneru. All rights reserved.
//

#import "SettingsVC.h"
#import "JPPhoto.h"
#import "JPPhotoModel.h"
#import <SVProgressHUD.h>

@interface SettingsVC ()
@property (weak, nonatomic) IBOutlet UISwitch *useLockSwitch;
@property (weak, nonatomic) IBOutlet UILabel *tempSizeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *exifFilterSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *splitExifDateSwitch;

@end

@implementation SettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.useLockSwitch.on = [[NSUserDefaults standardUserDefaults]boolForKey:@"useLock"];
    self.exifFilterSwitch.on = [[NSUserDefaults standardUserDefaults]boolForKey:@"exifFilter"];
    self.splitExifDateSwitch.on = [[NSUserDefaults standardUserDefaults]boolForKey:@"splitDate"];
    [self showTempSize];
}

-(void)showTempSize{
    self.tempSizeLabel.text = @"Loading...";
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSInteger size = [JPPhoto tempFilesSize];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.tempSizeLabel.text = [NSString stringWithFormat:@"%ld MB",(size / (1000 * 1000))];
        });
    });
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
//    return 0;
//}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)lockValueChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults]setBool:self.useLockSwitch.on forKey:@"useLock"];
}
- (IBAction)exifFilterChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults]setBool:self.exifFilterSwitch.on forKey:@"exifFilter"];
}
- (IBAction)splitDateChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults]setBool:self.splitExifDateSwitch.on forKey:@"splitDate"];
}
- (IBAction)removeCache:(id)sender {
    [self.tableView reloadData];
    
    // キャッシュを削除
    [JPPhotoModel removeAllThumb];
    
    // インデックスを削除
    [JPPhotoModel removeAllIndex];
    
    [self showTempSize];
    
    NSNotification *n = [NSNotification notificationWithName:@"removeCache" object:self];
    [[NSNotificationCenter defaultCenter] postNotification:n];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 2){
        [self removeCache:tableView];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self showTempSize];
    }else if (indexPath.row == 3){
        [self createIndexies];
        

    }
}

-(void)createIndexies{
    // 事前にインデックスと一番ちっさいサムネを作る
    NSMutableArray *directorys = [NSMutableArray array];
    NSMutableArray *directoryNames = [NSMutableArray array];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    for (NSString *path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil] )
    {
        BOOL dir;
        
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@",documentsDirectory,path];
        
        if (![path isEqualToString:@".thumb"]){
            if ( [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&dir] ){
                if ( dir ){
                    [directorys addObject:fullPath];
                    [directoryNames addObject:path];
                }
            }
        }
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 一覧生成
        for (NSInteger i = 0; i < directorys.count; i++) {
            [SVProgressHUD showProgress:(float)i/(float)directorys.count status:@"写真の一覧を作っています"];
            NSString *path = directorys[i];
            NSArray *photos = [JPPhotoModel photosWithDirectoryName:path showProgress:NO];
            
            for (NSInteger j = 0; j < 4; j++) {
                if (photos.count > j){
                    JPPhoto *p = photos[j];
                    [p makeThumbnail];
                }
            }
        }
        [SVProgressHUD dismiss];
        [self.tableView reloadData];
    });
    
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

@end
