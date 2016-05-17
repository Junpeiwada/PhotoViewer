//
//  AppDelegate.m
//  JPPhotoViewer
//
//  Created by junpeiwada on 2016/05/10.
//  Copyright © 2016年 soneru. All rights reserved.
//

#import "AppDelegate.h"
#import "PAPasscodeViewController.h"

@interface AppDelegate ()<PAPasscodeViewControllerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    UIViewController *blankViewController = [UIViewController new];
    blankViewController.view.backgroundColor = [UIColor blackColor];
    [self.window.rootViewController presentViewController:blankViewController animated:NO completion:NULL];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {

}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self.window.rootViewController dismissViewControllerAnimated:NO completion:nil];
    
    NSString *passcode = nil;
    // KeyChainから読み出すようにする。とりあえずバンドル・・・
    passcode = [[NSUserDefaults standardUserDefaults]stringForKey:@"passcode"];
    if (passcode){
        // 認証
        PAPasscodeViewController *passcodeViewController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionEnter];
        passcodeViewController.delegate = self;
        
        passcodeViewController.passcode = passcode;
        [self.window.rootViewController presentViewController:[[UINavigationController alloc] initWithRootViewController:passcodeViewController] animated:NO completion:nil];
    }else{
        // セット
        PAPasscodeViewController *passcodeViewController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionSet];
        passcodeViewController.delegate = self;
        
        [self.window.rootViewController presentViewController:[[UINavigationController alloc] initWithRootViewController:passcodeViewController] animated:NO completion:nil];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
- (void)PAPasscodeViewControllerDidEnterPasscode:(PAPasscodeViewController *)controller{
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}
- (void)PAPasscodeViewControllerDidCancel:(PAPasscodeViewController *)controller {
//    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)PAPasscodeViewControllerDidSetPasscode:(PAPasscodeViewController *)controller {
    // Do stuff with controller.passcode...
    
    [[NSUserDefaults standardUserDefaults]setObject:controller.passcode forKey:@"passcode"];
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
