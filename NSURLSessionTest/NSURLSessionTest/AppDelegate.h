//
//  AppDelegate.h
//  NSURLSessionTest
//
//  Created by ZaneWang on 2018/6/25.
//  Copyright © 2018 zz.wang.developer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (copy, nonatomic) void(^backgroundSessionCompletionHandler)(void);

@end

