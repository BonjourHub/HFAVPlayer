//
//  ViewController.m
//  AVPlayerCaching
//
//  Created by Anurag Mishra on 5/19/14.
//  Sample code to demonstrate how to cache a remote audio file while streaming it with AVPlayer
//

#import "TestViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface TestViewController () <NSURLConnectionDataDelegate, AVAssetResourceLoaderDelegate>
{
    UIButton * _playButton;
}
@property (nonatomic, strong) NSMutableData *songData;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) NSURLConnection *connection;

@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSMutableArray *pendingRequests;


@end

@implementation TestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor colorWithRed:0.6 green:0.4 blue:0.2 alpha:0.8];
    
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playButton.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:0.2];
    [_playButton addTarget:self action:@selector(playSong:) forControlEvents:UIControlEventTouchUpInside];
    [_playButton setTitle:@"播放" forState:UIControlStateNormal];
    _playButton.tag = 1001;
    [self.view addSubview:_playButton];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _playButton.frame = CGRectMake(20, 100, 40, 30);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSURL *)songURL
{
    return [NSURL URLWithString:@"http://www.170mv.com/kw/other.web.rh01.sycdn.kuwo.cn/resource/n3/21/19/3413654131.mp3"];
}

- (NSURL *)songURLWithCustomScheme:(NSString *)scheme
{
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[self songURL] resolvingAgainstBaseURL:NO];
    components.scheme = scheme;
    
    return [components URL];
}

- (void)playSong:(id)sender
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[self songURLWithCustomScheme:@"streaming"] options:nil];
    [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    
    self.pendingRequests = [NSMutableArray array];
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
}

#pragma mark - NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.songData = [NSMutableData data];
    self.response = (NSHTTPURLResponse *)response;
    
    [self processPendingRequests];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.songData appendData:data];
    
    [self processPendingRequests];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self processPendingRequests];
    
    NSString *cachedFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"cached.mp3"];
    
    [self.songData writeToFile:cachedFilePath atomically:YES];
}

#pragma mark - AVURLAsset resource loading

- (void)processPendingRequests
{
    NSMutableArray *requestsCompleted = [NSMutableArray array];
    
    for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests)
    {
        [self fillInContentInformation:loadingRequest.contentInformationRequest];
        
        BOOL didRespondCompletely = [self respondWithDataForRequest:loadingRequest.dataRequest];
        
        if (didRespondCompletely)
        {
            [requestsCompleted addObject:loadingRequest];
            
            [loadingRequest finishLoading];
        }
    }
    
    [self.pendingRequests removeObjectsInArray:requestsCompleted];
}

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
{
    if (contentInformationRequest == nil || self.response == nil)
    {
        return;
    }
    
    NSString *mimeType = [self.response MIMEType];
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = [self.response expectedContentLength];
}

- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingDataRequest *)dataRequest
{
    long long startOffset = dataRequest.requestedOffset;
    if (dataRequest.currentOffset != 0)
    {
        startOffset = dataRequest.currentOffset;
    }
    
    // Don't have any data at all for this request
    if (self.songData.length < startOffset)
    {
        return NO;
    }
    
    // This is the total data we have from startOffset to whatever has been downloaded so far
    NSUInteger unreadBytes = self.songData.length - (NSUInteger)startOffset;
    
    // Respond with whatever is available if we can't satisfy the request fully yet
    NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);
    
    [dataRequest respondWithData:[self.songData subdataWithRange:NSMakeRange((NSUInteger)startOffset, numberOfBytesToRespondWith)]];
    
    long long endOffset = startOffset + dataRequest.requestedLength;
    BOOL didRespondFully = self.songData.length >= endOffset;
    
    return didRespondFully;
}


- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    if (self.connection == nil)
    {
        NSURL *interceptedURL = [loadingRequest.request URL];
        NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:interceptedURL resolvingAgainstBaseURL:NO];
        actualURLComponents.scheme = @"http";
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[actualURLComponents URL]];
        self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        [self.connection setDelegateQueue:[NSOperationQueue mainQueue]];
        
        [self.connection start];
    }
    
    [self.pendingRequests addObject:loadingRequest];
    
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.pendingRequests removeObject:loadingRequest];
}

#pragma KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay)
    {
        [self.player play];
    }
}

@end
