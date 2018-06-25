//
//  ViewController.m
//  NSURLSessionTest
//
//  Created by ZaneWang on 2018/6/25.
//  Copyright © 2018 zz.wang.developer. All rights reserved.
//

#import "ViewController.h"
@import MediaPlayer;
#import "Track.h"
#import "TrackCell.h"
#import "Download.h"
#import "AppDelegate.h"

@interface ViewController ()<NSURLSessionDelegate, NSURLSessionDownloadDelegate, UISearchBarDelegate, TrackCellDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSDictionary *activeDownloads;

@property (strong, nonatomic) NSURLSession *defaultSession;

@property (strong, nonatomic) NSURLSessionDataTask *dataTask;

@property (strong, nonatomic) NSMutableArray <Track *>*searchResults;

@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;

@property (strong, nonatomic) NSURLSession *downloadSession;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation ViewController

- (NSURLSession *)defaultSession {
    if (!_defaultSession) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _defaultSession = [NSURLSession sessionWithConfiguration:config];
    }
    return _defaultSession;
}

- (NSURLSession *)downloadSession {
    if (!_downloadSession) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"bgSessionConfiguration"];
        _downloadSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return _downloadSession;
}

- (UITapGestureRecognizer *)tapRecognizer {
    if (!_tapRecognizer) {
        _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    }
    return _tapRecognizer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
    self.searchResults = @[].mutableCopy;
    self.activeDownloads = @{}.mutableCopy;
    self.searchBar.delegate = self;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)dismissKeyboard:(id)sender {
    [self.searchBar resignFirstResponder];
}

- (void)updateSearchResults:(NSData *)data {
    [self.searchResults removeAllObjects];
    typeof(self) __weak weakSelf = self;
    if (data) {
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        //Get the result array
        NSArray *result = resp[@"results"];
        [result enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *previewUrl = object[@"previewUrl"];
            NSString *name = object[@"trackName"];
            NSString *artist = object[@"artistName"];
            Track *track = [[Track alloc] initWithName:name withArtist:artist withPreviewUrl:previewUrl];
            [weakSelf.searchResults addObject:track];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
            [weakSelf.tableView setContentOffset:CGPointZero animated:YES];
        });
    }
}

- (void)startDownload:(Track *)track {
    if (track.previewUrl) {
        NSURL *url = [NSURL URLWithString:track.previewUrl];
        Download *download = [[Download alloc] initWithUrl:track.previewUrl];
        download.downloadTask = [self.downloadSession downloadTaskWithURL:url];
        [download.downloadTask resume];
        download.isDownloading = YES;
        [self.activeDownloads setValue:download forKey:track.previewUrl];
    }
}

- (void)pauseDownload:(Track *)track {
    if (track.previewUrl) {
        Download __block *download = self.activeDownloads[track.previewUrl];
        if (download.isDownloading) {
            [download.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                if (resumeData) {
                    download.resumeData = resumeData;
                }
            }];
        }
        download.isDownloading = NO;
    }
}

- (void)cancelDownload:(Track *)track {
    if (track.previewUrl) {
        Download *download = self.activeDownloads[track.previewUrl];
        [download.downloadTask cancel];
        [self.activeDownloads setValue:nil forKey:track.previewUrl];
    }
    
}

- (void)resumeDownload:(Track *)track {
    if (track.previewUrl) {
        Download *download = self.activeDownloads[track.previewUrl];
        if (download.resumeData) {
            download.downloadTask = [self.downloadSession downloadTaskWithResumeData:download.resumeData];
            [download.downloadTask resume];
        } else {
            NSURL *url = [NSURL URLWithString:track.previewUrl];
            download.downloadTask = [self.downloadSession downloadTaskWithURL:url];
            [download.downloadTask resume];
        }
        download.isDownloading = YES;
    }
}

- (void)playDownload:(Track *)track {
    NSURL *url = [self localFilePathForUrl:track.previewUrl];
    url = [NSURL fileURLWithPath:url.absoluteString];
    MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
    [self presentViewController:moviePlayer animated:YES completion:nil];
}

- (NSURL *)localFilePathForUrl:(NSString *)previewUrl {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSURL *url = [NSURL URLWithString:previewUrl];
    NSString *lastPathComponent = url.lastPathComponent;
    if (lastPathComponent) {
        NSString *fullPath = [documentsPath stringByAppendingPathComponent:lastPathComponent];
        return [NSURL URLWithString:fullPath];
    }
    return nil;
}

- (NSInteger)trackIndexForDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    NSString *url = downloadTask.originalRequest.URL.absoluteString;
    for (Track *track in self.searchResults) {
        if ([url isEqualToString:track.previewUrl]) {
            return [self.searchResults indexOfObject:track];
        }
    }
    return -1;
}

#pragma mark - NSURLSessionDelegate
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    void(^complete)(void) = appDelegate.backgroundSessionCompletionHandler;
    if (complete) {
        appDelegate.backgroundSessionCompletionHandler = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            complete();
        });
    }
}

#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    typeof(self) __weak weakSelf = self;
    NSString *originalURL = downloadTask.originalRequest.URL.absoluteString;
    if (originalURL) {
        NSURL *destinationURL = [self localFilePathForUrl:originalURL];
        destinationURL = [NSURL fileURLWithPath:destinationURL.absoluteString];
        NSLog(@"download success destinationURL-->>%@",destinationURL.path);
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtURL:destinationURL error:nil];
        NSError *error;
        [fileManager copyItemAtURL:location toURL:destinationURL error:&error];
        NSLog(@"copy error = > %@", error);
    }
    NSString *url = downloadTask.originalRequest.URL.absoluteString;
    if (url) {
        [self.activeDownloads setValue:nil forKey:url];
        NSInteger trackIndex = [self trackIndexForDownloadTask:downloadTask];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:trackIndex inSection:0];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:(UITableViewRowAnimationNone)];
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSString *downloadUrl = downloadTask.originalRequest.URL.absoluteString;
    Download *download = self.activeDownloads[downloadUrl];
    download.progress = (totalBytesWritten*0.01f*100.f)/totalBytesExpectedToWrite;
    NSString *totalSize = [NSByteCountFormatter stringFromByteCount:totalBytesExpectedToWrite countStyle:(NSByteCountFormatterCountStyleBinary)];
    NSInteger trackIndex = [self trackIndexForDownloadTask:downloadTask];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:trackIndex inSection:0];
    dispatch_async(dispatch_get_main_queue(), ^{
        TrackCell *trackCell = [self.tableView cellForRowAtIndexPath:indexPath];
        trackCell.progressView.progress = download.progress;
        trackCell.progressLabel.text = [NSString stringWithFormat:@"%.1f& of %@", download.progress * 100.f,totalSize];
    });
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self dismissKeyboard:searchBar];
    if (searchBar.text.length != 0) {
        if (!self.dataTask) {
            [self.dataTask cancel];
        }
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSCharacterSet *expectedCharSet = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *searchTerm = [searchBar.text stringByAddingPercentEncodingWithAllowedCharacters:expectedCharSet];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/search?media=music&entity=song&term=%@",searchTerm]];
    self.dataTask = [self.defaultSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
        if (error) {
            NSLog(@"\nsearch error---->%@\n",error.localizedDescription);
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                [self updateSearchResults:data];
            }
        }
    }];
    [self.dataTask resume];
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTop;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.view addGestureRecognizer:self.tapRecognizer];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [self.view removeGestureRecognizer:self.tapRecognizer];
}

#pragma mark - TrackCellDelegate
- (void)pauseTapped:(TrackCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Track *track = self.searchResults[indexPath.row];
    [self pauseDownload:track];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:(UITableViewRowAnimationNone)];
}

- (void)resumeTapped:(TrackCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Track *track = self.searchResults[indexPath.row];
    [self resumeDownload:track];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:(UITableViewRowAnimationNone)];
}

- (void)cancelTapped:(TrackCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Track *track = self.searchResults[indexPath.row];
    [self cancelDownload:track];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:(UITableViewRowAnimationNone)];
}

- (void)downloadTapped:(TrackCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Track *track = self.searchResults[indexPath.row];
    [self startDownload:track];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:(UITableViewRowAnimationNone)];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TrackCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TrackCell" forIndexPath:indexPath];
    cell.delegate = self;
    Track *track = self.searchResults[indexPath.row];
    cell.titleLabel.text = track.name;
    cell.artistLabel.text = track.artist;
    BOOL showDownloadControls = NO;
    Download *download = self.activeDownloads[track.previewUrl];
    if (download) {
        showDownloadControls = YES;
        cell.progressView.progress = download.progress;
        cell.progressLabel.text = download.isDownloading ? @"Downloading...":@"Paused";
        NSString *title = download.isDownloading ? @"Pause":@"Resume";
        [cell.pauseButton setTitle:title forState:UIControlStateNormal];
    }
    cell.progressView.hidden = !showDownloadControls;
    cell.progressLabel.hidden = !showDownloadControls;
    
    BOOL downloaded = [self localFileExistsForTrack:track];
    cell.selectionStyle = downloaded ? UITableViewCellSelectionStyleGray:UITableViewCellAccessoryNone;
    cell.downloadButton.hidden = downloaded || showDownloadControls;
    
    cell.pauseButton.hidden = !showDownloadControls;
    cell.cancelButton.hidden = !showDownloadControls;
    
    return cell;
}

- (BOOL)localFileExistsForTrack:(Track *)track {
    if (track.previewUrl) {
        NSURL *localUrl = [self localFilePathForUrl:track.previewUrl];
        localUrl = [NSURL fileURLWithPath:localUrl.absoluteString];
        NSLog(@"download success localUrl-->>%@",localUrl.path);
        if (localUrl) {
            BOOL isDir = NO;
            if (localUrl.path) {
                return [[NSFileManager defaultManager] fileExistsAtPath:localUrl.path isDirectory:&isDir];
            }
        }
        return NO;
    }
    return NO;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 62.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Track *track = self.searchResults[indexPath.row];
    if ([self localFileExistsForTrack:track]) {
        [self playDownload:track];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
