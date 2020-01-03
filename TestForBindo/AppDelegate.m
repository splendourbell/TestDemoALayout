//
//  AppDelegate.m
//  TestForBindo
//
//  Created by bell on 2020/1/1.
//  Copyright © 2020 BindoTest Bell. All rights reserved.
//

#import "AppDelegate.h"
#import <ALayout/ALayout.h>
#import "ChefViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self configResouceManager];
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = ChefViewController.new;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)configResouceManager {
    
    [ResourceManager Config:^(ResourceManager *resourceManager) {
        NSString* firstPath = nil;
        NSString* secondPath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"uiassets"];
        
#if TARGET_OS_SIMULATOR
        NSString* curFile = @(__FILE__);
        curFile = [curFile.stringByDeletingLastPathComponent stringByAppendingPathComponent:@"Resource/uiassets"];
        firstPath = curFile;
        secondPath = curFile;
#endif
        [resourceManager configFirstPath:firstPath secondPath:secondPath];
        
//字号调整支持
//        resourceManager.fontScale = ^ CGFloat(CGFloat size) {
//            return size*1.5;
//        };
        
//多语言支持
//        [resourceManager addLanguageChangedNotify:@"LANGUAGE_CHANGED"];
//        resourceManager.getCurrentLanguage = ^NSString *{
//            //支持多语言切换
//            return @"en";
//        };
    }];
}

@end
