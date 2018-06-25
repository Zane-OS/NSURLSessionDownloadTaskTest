//
//  Track.h
//  NSURLSessionTest
//
//  Created by ZaneWang on 2018/6/25.
//  Copyright © 2018 zz.wang.developer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Track : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) NSString *previewUrl;

- (instancetype)initWithName:(NSString *)name
                  withArtist:(NSString *)artist
              withPreviewUrl:(NSString *)previewUrl;

@end
