//
//  Download.h
//  NSURLSessionTest
//
//  Created by ZaneWang on 2018/6/25.
//  Copyright © 2018 zz.wang.developer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Download : NSObject

@property (nonatomic, strong) NSString *url;
@property (nonatomic, assign) BOOL      isDownloading;
@property (nonatomic, assign) float     progress;

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, strong) NSData   *resumeData;

- (instancetype)initWithUrl:(NSString *)url;

@end
