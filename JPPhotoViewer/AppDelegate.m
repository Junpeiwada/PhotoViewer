//
//  AppDelegate.m
//  JPPhotoViewer
//
//  Created by junpeiwada on 2016/05/10.
//  Copyright © 2016年 soneru. All rights reserved.
//

#import "AppDelegate.h"
#import "PAPasscodeViewController.h"
#import "SSKeychain.h"
#import "JPPhotoModel.h"

@interface AppDelegate ()<PAPasscodeViewControllerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window.tintColor = [UIColor blackColor];
    
    BOOL usePasscode = [[NSUserDefaults standardUserDefaults]boolForKey:@"useLock"];
    if (!usePasscode){
        self.isPassCodeViewPassed = YES;
    }
    return YES;
}

-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    if ([url isFileURL]) {
        if ([[url pathExtension] isEqualToString:@"jpg"]) {
            NSLog(@"%@", url.absoluteString);
            
            NSData *data = [NSData dataWithContentsOfURL:url];
            NSString* filename = [url lastPathComponent];
            NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSError* error = nil;
            NSString* impPath = [NSString stringWithFormat:@"%@/Imports", [paths objectAtIndex:0]];
            [[NSFileManager defaultManager] createDirectoryAtPath:impPath withIntermediateDirectories:YES attributes:nil error:&error];
            NSString* savePath = [NSString stringWithFormat:@"%@/Imports/%@", [paths objectAtIndex:0], filename];
            
            // Importフォルダに保存
            if ([data writeToFile:savePath atomically:YES]){
                // 削除
                if ([[NSFileManager defaultManager]fileExistsAtPath:[url path]]) {
                    [[NSFileManager defaultManager]removeItemAtPath:[url path] error:&error];
                }
                // Importsのインデックス削除
                [JPPhotoModel removeIndex:@"Imports"];
            }
        }
    }
    return YES;
}
- (void)applicationWillResignActive:(UIApplication *)application {
    self.isPassCodeViewPassed = NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    self.isPassCodeViewPassed = NO;
    UIViewController *root = [UIApplication sharedApplication].delegate.window.rootViewController;
    [root dismissViewControllerAnimated:YES completion:nil];
    
    // 黒いビューを表示して、タスクスイッチャに黒い画面が表示されるようにする
    UIViewController *blankViewController = [UIViewController new];
    blankViewController.view.backgroundColor = [UIColor blackColor];
    [self.window.rootViewController presentViewController:blankViewController animated:NO completion:NULL];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    BOOL usePasscode = [[NSUserDefaults standardUserDefaults]boolForKey:@"useLock"];
    if (usePasscode){
        self.isPassCodeViewShown = YES;
        NSString *passcode = [self loadPassword];
        if (passcode){
            // パスコードの画面を表示する
            PAPasscodeViewController *passcodeViewController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionEnter];
            passcodeViewController.delegate = self;
            
            passcodeViewController.passcode = passcode;
            
            UINavigationController *navi =[[UINavigationController alloc] initWithRootViewController:passcodeViewController];
            
            // 黒いビューをdissmissする
            [self.window.rootViewController dismissViewControllerAnimated:NO completion:nil];
            [self.window.rootViewController presentViewController:navi animated:NO completion:nil];
        }else{
            // 新規に設定
            PAPasscodeViewController *passcodeViewController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionSet];
            passcodeViewController.delegate = self;
            
            UINavigationController *navi =[[UINavigationController alloc] initWithRootViewController:passcodeViewController];
            
            // 黒いビューをdissmissする
            [self.window.rootViewController dismissViewControllerAnimated:NO completion:nil];
            [self.window.rootViewController presentViewController:navi animated:NO completion:nil];
        }
    }else{
        self.isPassCodeViewPassed = YES;
        // 黒いビューをdissmissする
        [self.window.rootViewController dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
}
- (void)PAPasscodeViewControllerDidEnterPasscode:(PAPasscodeViewController *)controller{
    // パスワードが正解ならこのビューを非表示にする
    self.isPassCodeViewShown = NO;
    self.isPassCodeViewPassed = YES;
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}
- (void)PAPasscodeViewControllerDidCancel:(PAPasscodeViewController *)controller {
    // パスコードのキャンセルはできないようにする（無視する）
//    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)PAPasscodeViewControllerDidSetPasscode:(PAPasscodeViewController *)controller {
    // パスワードの設定後の処理。パスワードを保存する
    self.isPassCodeViewShown = NO;
    self.isPassCodeViewPassed = YES;

    [self savePassword:controller.passcode];
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)savePassword:(NSString *)password{
    [[NSUserDefaults standardUserDefaults]setObject:password forKey:@"JPPhotoViewerP"];
//    [SSKeychain setPassword:password forService:@"JPPhotoViewer" account:@"jp" error:nil];
}
- (NSString *)loadPassword{
    return [[NSUserDefaults standardUserDefaults]objectForKey:@"JPPhotoViewerP"];
//    return [SSKeychain passwordForService:@"JPPhotoViewer" account:@"jp"];
}

@end
