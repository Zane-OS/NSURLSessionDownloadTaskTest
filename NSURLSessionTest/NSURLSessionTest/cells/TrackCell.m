//
//  TrackCell.m
//  NSURLSessionTest
//
//  Created by ZaneWang on 2018/6/25.
//  Copyright © 2018 zz.wang.developer. All rights reserved.
//

#import "TrackCell.h"

@interface TrackCell()

@end

@implementation TrackCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (IBAction)pauseOrResumeTapped:(UIButton *)sender {
    if ([sender.titleLabel.text isEqualToString:@"Pause"]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(pauseTapped:)]) {
            [self.delegate pauseTapped:self];
        }
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(resumeTapped:)]) {
            [self.delegate resumeTapped:self];
        }
    }
}

- (IBAction)cancelTapped:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cancelTapped:)]) {
        [self.delegate cancelTapped:self];
    }
}

- (IBAction)downloadTapped:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTapped:)]) {
        [self.delegate downloadTapped:self];
    }
}

@end
