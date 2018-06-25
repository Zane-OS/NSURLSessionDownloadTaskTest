//
//  Track.m
//  NSURLSessionTest
//
//  Created by ZaneWang on 2018/6/25.
//  Copyright © 2018 zz.wang.developer. All rights reserved.
//

#import "Track.h"

@implementation Track

- (instancetype)initWithName:(NSString *)name withArtist:(NSString *)artist withPreviewUrl:(NSString *)previewUrl {
    if (self = [super init]) {
        self.name = name;
        self.artist = artist;
        self.previewUrl = previewUrl;
    }
    return self;
}

@end
