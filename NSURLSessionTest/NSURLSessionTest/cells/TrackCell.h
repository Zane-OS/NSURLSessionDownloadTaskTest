//
//  TrackCell.h
//  NSURLSessionTest
//
//  Created by ZaneWang on 2018/6/25.
//  Copyright © 2018 zz.wang.developer. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TrackCellDelegate;

@interface TrackCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (nonatomic, strong) id<TrackCellDelegate> delegate;

@end

@protocol TrackCellDelegate <NSObject>

- (void)pauseTapped:(TrackCell *)cell;
- (void)resumeTapped:(TrackCell *)cell;
- (void)cancelTapped:(TrackCell *)cell;
- (void)downloadTapped:(TrackCell *)cell;

@end
