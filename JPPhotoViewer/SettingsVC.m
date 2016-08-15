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

@interface SettingsVC ()
@property (weak, nonatomic) IBOutlet UISwitch *useLockSwitch;
@property (weak, nonatomic) IBOutlet UILabel *tempSizeLabel;

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
    self.tempSizeLabel.text = @"Loading...";
    [self showTempSize];
}

-(void)showTempSize{
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
- (IBAction)removeThumb:(id)sender {
    [self.tableView reloadData];
    
    // ついでにキャッシュを削除
    JPPhoto *t = [[JPPhoto alloc]init];
    [t removeAllThumb];
    
    // インデックスを削除
    [JPPhotoModel removeAllIndex];
    
    
    [self showTempSize];
}

@end
