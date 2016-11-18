//
//  NextGenVideoPlayerViewController.h
//  Fork of Apple's AVPlayerDemoPlaybackViewController.h
//


#import "NextGenVideoPlayerViewController.h"
#import "NextGenVideoPlayerPlaybackView.h"

//=========================================================
# pragma mark - Constants
//=========================================================
// AVFoundation KVOs
static NSString * const kAVPlayerItemStatusKVO                   = @"status";
static NSString * const kAVPlayerItemDurationKVO                 = @"duration";
static NSString * const kAVPlayerItemPlaybackBufferEmptyKVO      = @"playbackBufferEmpty";
static NSString * const kAVPlayerItemPlaybackLikelyToKeepUpKVO   = @"playbackLikelyToKeepUp";
static NSString * const kAVPlayerCurrentItemKVO                  = @"currentItem";
static NSString * const kAVPlayerRateKVO                         = @"rate";
static NSString * const kAVPlayerTracksKVO                       = @"tracks";
static NSString * const kAVPlayerPlayableKVO                     = @"playable";

static void *VideoPlayerRateObservationContext                   = &VideoPlayerRateObservationContext;
static void *VideoPlayerStatusObservationContext                 = &VideoPlayerStatusObservationContext;
static void *VideoPlayerDurationObservationContext               = &VideoPlayerDurationObservationContext;
static void *VideoPlayerCurrentItemObservationContext            = &VideoPlayerCurrentItemObservationContext;
static void *VideoPlayerBufferEmptyObservationContext            = &VideoPlayerBufferEmptyObservationContext;
static void *VideoPlayerPlaybackLikelyToKeepUpObservationContext = &VideoPlayerPlaybackLikelyToKeepUpObservationContext;


//=========================================================
# pragma mark - Private variables & methods
//=========================================================
@interface NextGenVideoPlayerViewController ()

@property (weak, nonatomic)   IBOutlet  UIButton                        *playButton;
@property (weak, nonatomic)   IBOutlet  UIButton                        *pauseButton;
@property (weak, nonatomic)   IBOutlet  UISlider                        *scrubber;
@property (weak, nonatomic)   IBOutlet  UILabel                         *timeElapsedLabel;
@property (weak, nonatomic)   IBOutlet  UILabel                         *durationLabel;
@property (weak, nonatomic)   IBOutlet  UIButton                        *subtitlesButton;
@property (strong, nonatomic)           NSArray                         *videoURLS;


/**
 * Observe the kApplicationWillResignActive notification
 */
@property (weak, nonatomic)             id                               applicationResignationObserver;

/**
 * Track the status of full screen video
 */
@property (strong, nonatomic)           UIView                          *originalContainerView;

/**
 * There is a difference between enabling/disabling and showing/hiding
 * player controls.
 * @see playerControlsVisible:
 */
@property (nonatomic, assign)           BOOL                              playerControlsEnabled;
@property (nonatomic, strong)           NSMutableArray                   *assests;



// Player
- (void)removePlayerTimeObserver;
- (void)playerItemDidReachEnd:(NSNotification *)notification;
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;

@end

//=========================================================
# pragma mark - NextGenVideoPlayerViewController
//=========================================================
@implementation NextGenVideoPlayerViewController

//=========================================================
# pragma mark - Playback
//=========================================================
- (void)playAsset:(AVURLAsset *)asset fromStartTime:(NSTimeInterval)startTime {
    playbackSyncStartTime = startTime;
    hasSeekedToPlaybackSyncStartTime = NO;
    
    _URL = asset.URL;
    
    NSArray *requestedKeys = @[kAVPlayerTracksKVO, kAVPlayerPlayableKVO];
    
    /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler: ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
            [self prepareToPlayAsset:asset withKeys:requestedKeys];
        });
    }];
}

//=========================================================
# pragma mark - Movie controller methods
//=========================================================

//=========================================================
# pragma mark - Button Action Methods
//=========================================================
- (IBAction)play:(id)sender {
	// Play media
    [self initScrubberTimer];
    [self playVideo];
}

- (IBAction)pause:(id)sender {
    // Pause media
    [self pauseVideo];
}

- (IBAction)toggleFullScreen:(id)sender {
    // Toggle full screen
    self.isFullScreen = !self.isFullScreen;
}

/**
 * Exits player
 */
- (IBAction)done:(id)sender {
    // Pause playback
    [self pause:nil];
}

//=========================================================
# pragma mark - Controls
//=========================================================
/* Show the pause button in the movie player controller. */
-(void)showPauseButton {
    if (self.state != NextGenVideoPlayerStateVideoLoading) {
        // Disable + Hide Play Button
        self.playButton.enabled     = NO;
        self.playButton.hidden      = YES;
        
        // Enable + Show Pause Button
        self.pauseButton.enabled    = YES;
        self.pauseButton.hidden     = NO;
    }
}

/* Show the play button in the movie player controller. */
-(void)showPlayButton {
    if (self.state == NextGenVideoPlayerStateVideoPaused || self.state == NextGenVideoPlayerStateReadyToPlay) {
        // Disable + Hide Pause Button
        self.pauseButton.enabled    = NO;
        self.pauseButton.hidden     = YES;
        
        // Enable + Show Play Button
        self.playButton.enabled     = YES;
        self.playButton.hidden      = NO;
    }
}

/* If the media is playing, show the stop button; otherwise, show the play button. */
- (void)syncPlayPauseButtons {
	if ([self isPlaying]) {
        [self showPauseButton];
	}
	else {
        [self showPlayButton];        
	}
}

-(void)enablePlayerButtons {
    self.playButton.enabled         = YES;
    self.pauseButton.enabled        = YES;
    self.subtitlesButton.enabled    = YES;
    self.fullScreenButton.enabled   = YES;
}

-(void)disablePlayerButtons {
    self.playButton.enabled         = NO;
    self.pauseButton.enabled        = NO;
    self.subtitlesButton.enabled    = NO;
    self.fullScreenButton.enabled   = NO;
}

- (void)setPlayerControlsEnabled:(BOOL)shouldPlayerControlsBeEnabled {
    // Set instance variable
    _playerControlsEnabled      = shouldPlayerControlsBeEnabled;
    
    // Perform resulting actions
    if (_playerControlsEnabled) {
        [self enableScrubber];
        [self enablePlayerButtons];
    }
    else {
        [self disableScrubber];
        [self disablePlayerButtons];
    }
}

- (void)setPlayerControlsVisible:(BOOL)shouldPlayerControlsBeVisible {
    // Set instance variable
    _playerControlsVisible      = shouldPlayerControlsBeVisible;
    
    // Show controls
    if (shouldPlayerControlsBeVisible) {
        // Top toolbar
        [self.topToolbar setHidden:NO];
        [UIView animateWithDuration:0.2f animations:^{
            [self.topToolbar setTransform:CGAffineTransformIdentity];
        } completion:^(BOOL finished){}];
        
        // Controls toolbar
        [self.playbackToolbar setHidden:NO];
        [UIView animateWithDuration:0.2f animations:^{
            [self.playbackToolbar setTransform:CGAffineTransformIdentity];
        } completion:^(BOOL finished){}];
        
    }
    // Hide controls
    else {
        // Top toolbar
        [UIView animateWithDuration:0.2f animations:^{
            [self.topToolbar setTransform:CGAffineTransformMakeTranslation(0.f, -(CGRectGetHeight([self.topToolbar bounds])))];
        } completion:^(BOOL finished) {
            [self.topToolbar setHidden:YES];
        }];
        
        // Playback toolbar
        [UIView animateWithDuration:0.2f animations:^{
            [self.playbackToolbar setTransform:CGAffineTransformMakeTranslation(0.f, CGRectGetHeight([self.playbackToolbar bounds]))];
        } completion:^(BOOL finished) {
            [self.playbackToolbar setHidden:YES];
        }];
    }
}

- (void)setActivityIndicatorVisible:(BOOL)isVisible {
    // Instance variable
    _activityIndicatorVisible                   = isVisible;
    
    // Show activity indicator
    if (isVisible) {
        [UIView animateWithDuration:0.2f animations:^{
            [self.activityIndicator startAnimating];
            self.activityIndicator.hidden       = NO;
            self.activityIndicator.alpha        = 1;
        } completion:nil];
    }
    // Hide activity indicator
    else {
        [UIView animateWithDuration:0.2f animations:^{
            self.activityIndicator.alpha        = 0;
        } completion:^(BOOL finished) {
            if (self.activityIndicator) {
                self.activityIndicator.hidden   = YES;
                [self.activityIndicator stopAnimating];
                
                // Show play/pause button if player controls are visible
                // Calling setPlayerControlsVisible will now toggle the play/pause
                // button once the player's state is NOT NextGenVideoPlayerStateVideoLoading
                self.playerControlsVisible      = self.playerControlsVisible;
            }
        }];
    }
}

- (void)initAutoHideTimer {
    if (self.playerControlsVisible) {
        // Invalidate existing timer
        if (self.playerControlsAutoHideTimer) {
            [self.playerControlsAutoHideTimer invalidate];
            self.playerControlsAutoHideTimer= nil;
        }
        
        // Start timer
        self.playerControlsAutoHideTimer    = [NSTimer scheduledTimerWithTimeInterval:self.playerControlsAutoHideTime target:self selector:@selector(autoHideControlsIfNecessary) userInfo:nil repeats:NO];
        
    } else {
        // Invalidate playerControlsAutoHideTimer
        if (self.playerControlsAutoHideTimer) {
            [self.playerControlsAutoHideTimer invalidate];
            self.playerControlsAutoHideTimer= nil;
        }
    }
}

- (void)autoHideControlsIfNecessary {
    if (!self.playerControlsVisible) return;
    
    // Auto-hide controls if player is playing
    if (self.state == NextGenVideoPlayerStateVideoPlaying) {
        self.playerControlsVisible = NO;
    }
}


//=========================================================
# pragma mark - Movie scrubber control
//=========================================================
/* ---------------------------------------------------------
**  Methods to handle manipulation of the movie scrubber control
** ------------------------------------------------------- */

/* Requests invocation of a given block during media playback to update the movie scrubber control. */
-(void)initScrubberTimer {
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    /* Update the scrubber during normal playback. */
    __weak NextGenVideoPlayerViewController *weakSelf = self;
    mTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1)
                                                              queue:NULL /* If you pass NULL, the main queue is used. */
                                                         usingBlock:^(CMTime time) {
                                                             // Sync scrubber
                                                             [weakSelf syncScrubber];
                                                         }];
}

/* Set the scrubber based on the player current time. */
- (void)syncScrubber {
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration)) {
		_scrubber.minimumValue = 0.0;
		return;
	} 

	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration)) {
        float minValue = self.scrubber.minimumValue;
		double time = CMTimeGetSeconds(self.player.currentTime);
        self.scrubber.value = (self.scrubber.maximumValue - minValue) * time / duration + minValue;
        
        // Update time labels
        [self updateTimeLabelsWithTime:time];
        
        self.activityIndicatorVisible = NO;
	}
}

- (double)timeValueForSlider:(UISlider *)slider {
    CMTime playerDuration = [self playerItemDuration];
    if (!CMTIME_IS_INVALID(playerDuration)) {
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration)) {
            float minValue = slider.minimumValue;
            return duration * (slider.value - minValue) / (slider.maximumValue - minValue);
        }
    }
    
    return 0;
}

/* The user is dragging the movie controller thumb to scrub through the movie. */
- (IBAction)beginScrubbing:(id)sender {
	mRestoreAfterScrubbingRate  = [self.player rate];
	[self pauseVideo];
    
    // Remove previous timer
    [self removePlayerTimeObserver];
}

/* Set the player current time to match the scrubber position. */
- (IBAction)scrub:(id)sender {
	if ([sender isKindOfClass:[UISlider class]]) {
        // Update time labels
        [self updateTimeLabelsWithTime:[self timeValueForSlider:sender]];
	}
}

- (void)seekPlayerToTime:(CMTime)seekTime {
    // Set instance vars
    isSeeking           = YES;
    
    // Set State
    self.state          = NextGenVideoPlayerStateVideoSeeking;
    
    // Seek
    [self.player seekToTime:seekTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        if (finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Seeking complete
                isSeeking = NO;
                hasSeekedToPlaybackSyncStartTime = YES;
                
                // Play
                [self playVideo];
            });
        }
    }];
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (IBAction)endScrubbing:(id)sender {
	if (!mTimeObserver) {
        [self initScrubberTimer];
	}
    
    if ([sender isKindOfClass:[UISlider class]]) {
        float time = [self timeValueForSlider:sender];
        
        // Update time labels
        [self updateTimeLabelsWithTime:time];
        
        // Seek
        [self seekPlayerToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
    }

	if (mRestoreAfterScrubbingRate) {
		[self.player setRate:mRestoreAfterScrubbingRate];
		mRestoreAfterScrubbingRate = 0.f;
	}
}

- (BOOL)isScrubbing {
	return mRestoreAfterScrubbingRate != 0.f;
}

-(void)enableScrubber {
    self.scrubber.enabled = YES;
}

-(void)disableScrubber {
    self.scrubber.enabled = NO;    
}

- (void)updateTimeLabelsWithTime:(CGFloat)time {
    // Update time labels
    if (_timeElapsedLabel) {
        _timeElapsedLabel.text = [self timeStringFromSecondsValue:time];
    }
}

//=========================================================
# pragma mark - Timecode Labels
//=========================================================
- (NSString *)timeStringFromSecondsValue:(int)seconds {
    NSString *retVal;
    int hours   = seconds / 3600;
    int minutes = (seconds / 60) % 60;
    int secs    = seconds % 60;
    if (hours > 0) {
        retVal  = [NSString stringWithFormat:@"%d:%02d:%02d", hours, minutes, secs];
    } else {
        retVal  = [NSString stringWithFormat:@"%02d:%02d", minutes, secs];
    }
    return retVal;
}

//=========================================================
# pragma mark - View Controller
//=========================================================

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        [self setup];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    
    return self;
}

- (void)setup {
    // Set player state
    [self setState:NextGenVideoPlayerStateUnknown];
    
    [self setPlayer:nil];
    
    [self setEdgesForExtendedLayout:UIRectEdgeAll];
}

- (void)viewDidLoad {
    
    // Disable OS Idle timer
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
	[self setPlayer:nil];
    
    // Setup audio to be heard even if device is on silent
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    
    if (error) {
        //DDLogError(@"%@", error);
    }
    
    // Set player controls auto-hide time
    self.playerControlsAutoHideTime = 5;
    
    // Set screen lock listener
    /*__weak typeof(&*self) weakSelf = self;
    self.applicationResignationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kApplicationWillResignActive
                                                                                            object:NULL
                                                                                             queue:NSOperationQueuePriorityNormal
                                                                                        usingBlock:^(NSNotification * _Nonnull note) {
                                                                                            [weakSelf.player pause];
                                                                                        }];*/
    
    isSeeking = NO;
	[self initScrubberTimer];
	[self syncPlayPauseButtons];
	[self syncScrubber];
    
    [super viewDidLoad];    
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.player pause];
    
    [super viewWillDisappear:animated];
}

-(void)setViewDisplayName {
    /* Set the view title to the last component of the asset URL. */
    self.title = [self.URL lastPathComponent];
    
    /* Or if the item has a AVMetadataCommonKeyTitle metadata, use that instead. */
	for (AVMetadataItem* item in ([[[self.player currentItem] asset] commonMetadata])) {
		NSString* commonKey = [item commonKey];
		
		if ([commonKey isEqualToString:AVMetadataCommonKeyTitle]) {
			self.title = [item stringValue];
		}
	}
}

- (IBAction)handleTap:(UITapGestureRecognizer *)gestureRecognizer {
    self.playerControlsVisible = !self.playerControlsVisible;
    [self initAutoHideTimer];
}

- (void)dealloc {
    // Enable OS Idle timer
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    // Remove observers
    [self.playerItem removeObserver:self forKeyPath:kAVPlayerItemStatusKVO];
    [self.playerItem removeObserver:self forKeyPath:kAVPlayerItemDurationKVO];
    [self.playerItem removeObserver:self forKeyPath:kAVPlayerItemPlaybackBufferEmptyKVO];
    [self.playerItem removeObserver:self forKeyPath:kAVPlayerItemPlaybackLikelyToKeepUpKVO];
    [self.player removeObserver:self forKeyPath:kAVPlayerCurrentItemKVO];
    [self.player removeObserver:self forKeyPath:kAVPlayerRateKVO];
	[self removePlayerTimeObserver];
    
    self.activityIndicator = nil;
	[self.player pause];
}

//=========================================================
# pragma mark - User Feedback
//=========================================================
- (void)displayError:(NSError *)error {
    /* Display the error. */
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                        message:[error localizedFailureReason]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    
    [alertView show];
}

//=========================================================
# pragma mark - Player
//=========================================================
- (void)setState:(NextGenVideoPlayerState)newState {
    // Set _state
    _state  = newState;
    
    //DDLogInfo(@"%@", [NSString stringFromVideoPlayerState:newState]);
    
    switch (_state) {
        case NextGenVideoPlayerStateUnknown:
            [self removePlayerTimeObserver];
            [self syncScrubber];
            //self.playerControlsEnabled = NO;
            break;
            
        case NextGenVideoPlayerStateReadyToPlay:
            // Play from playbackSyncStartTime
            if (playbackSyncStartTime > 1 && !hasSeekedToPlaybackSyncStartTime) {
                if (!isSeeking) {
                    // Seek
                    [self seekPlayerToTime:(CMTimeMakeWithSeconds(playbackSyncStartTime, NSEC_PER_SEC))];
                }
            }
            // Start from either beginning or from wherever left off
            else {
                hasSeekedToPlaybackSyncStartTime = YES;
                
                if (![self isPlaying]) {
                    [self playVideo];
                }
            }
            
            // Scrubber timer
            [self initScrubberTimer];
            
            // Hide activity indicator
            self.activityIndicatorVisible       = NO;
            
            // Enable (not show) controls
            self.playerControlsEnabled          = YES;
            
            break;
            
        case NextGenVideoPlayerStateVideoPlaying:
            // Hide activity indicator
            self.activityIndicatorVisible       = NO;
            
            // Enable (not show) controls
            self.playerControlsEnabled          = YES;
            
            // Auto Hide Timer
            [self initAutoHideTimer];
            
            break;
            
        case NextGenVideoPlayerStateVideoPaused:
            // Hide activity indicator
            self.activityIndicatorVisible       = NO;
            
            // Enable (not show) controls
            self.playerControlsEnabled          = YES;
            
            break;
        
        case NextGenVideoPlayerStateVideoSeeking:
        case NextGenVideoPlayerStateVideoLoading:
            // Show activity indicator
            self.activityIndicatorVisible       = YES;
            
            
        default:
            // Disable controls
            /*if (!isSeeking) {
                self.playerControlsEnabled      = NO;
            }*/
            break;
    }
    
    // Post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kNextGenVideoPlayerPlaybackStateDidChangeNotification object:self];
}

- (void)playVideo {
    // Play
    [self.player play];
        
    // Immediately show pause button. NOTE: syncPlayPauseButtons will actually update this
    // to reflect the playback "rate", e.g. 0.0 will automatically show the pause button.
    [self showPauseButton];
}

- (void)pauseVideo {
    // Pause media
    [self.player pause];
    
    // Immediately show play button. NOTE: syncPlayPauseButtons will actually update this
    // to reflect the playback "rate", e.g. 0.0 will automatically show the pause button.
    [self showPlayButton];
}

- (void)setIsFullScreen:(BOOL)isFullScreen {
    _isFullScreen = isFullScreen;
    
    [self.fullScreenButton setImage:[UIImage imageNamed:(self.isFullScreen ? @"Minimize" : @"Maximize")] forState:UIControlStateNormal];
    [self.fullScreenButton setImage:[UIImage imageNamed:(self.isFullScreen ? @"Minimize Highlighted" : @"Maximize Highlighted")] forState:UIControlStateHighlighted];
    
    if (self.isFullScreen) {
        self.originalContainerView = self.view.superview;
        [[UIApplication sharedApplication].keyWindow addSubview:self.view];
    } else {
        [self.originalContainerView addSubview:self.view];
        self.originalContainerView = nil;
    }
    
    self.view.frame = self.view.superview.bounds;
}


//=========================================================
# pragma mark - Player Item
//=========================================================

- (BOOL)isPlaying {
	return mRestoreAfterScrubbingRate != 0.f || [self.player rate] != 0.f;
}

/* Called when the player item has played to its end time. */
- (void)playerItemDidReachEnd:(NSNotification *)notification {
    // Override me
}

/* ---------------------------------------------------------
 **  Get the duration for a AVPlayerItem. 
 ** ------------------------------------------------------- */

- (CMTime)playerItemDuration {
	AVPlayerItem *playerItem = [self.player currentItem];
	if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
		return([playerItem duration]);
	}
	
	return(kCMTimeInvalid);
}


/* Cancels the previously registered time observer. */
-(void)removePlayerTimeObserver {
    // Player timer
	if (mTimeObserver) {
		[self.player removeTimeObserver:mTimeObserver];
		mTimeObserver = nil;
	}
    
    // Player Controls Auto-Hide Timer
    if (self.playerControlsAutoHideTimer) {
        [self.playerControlsAutoHideTimer invalidate];
        self.playerControlsAutoHideTimer = nil;
    }
}

//=========================================================
# pragma mark - Error Handling - Preparing Assets for Playback Failed
//=========================================================

/* --------------------------------------------------------------
 **  Called when an asset fails to prepare for playback for any of
 **  the following reasons:
 ** 
 **  1) values of asset keys did not load successfully, 
 **  2) the asset keys did load successfully, but the asset is not 
 **     playable
 **  3) the item did not become ready to play. 
 ** ----------------------------------------------------------- */

-(void)assetFailedToPrepareForPlayback:(NSError *)error {
    // Set player state
    [self setState:NextGenVideoPlayerStateError];

    [self removePlayerTimeObserver];
    [self syncScrubber];
    self.playerControlsEnabled = NO;
    
    // Log error
    //DDLogError(@"%@ %@", error, error.description);
    
    
    // Display error
    [self displayError:error];
}

//=========================================================
# pragma mark - Prepare to play asset, URL
//=========================================================

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys {
    // Set player state
    [self setState:NextGenVideoPlayerStateVideoLoading];
    
    /* Make sure that the value of each key has loaded successfully. */
	for (NSString *thisKey in requestedKeys) {
		NSError *error = nil;
		AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
		if (keyStatus == AVKeyValueStatusFailed) {
			[self assetFailedToPrepareForPlayback:error];
			return;
		}
		/* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
	}
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable) {
        /* Generate an error describing the failure. */
		NSString *localizedDescription = NSLocalizedString(@"player-generalError", @"Item cannot be played description");
		NSString *localizedFailureReason = NSLocalizedString(@"player-asset-tracks-load-error", @"Item cannot be played failure reason");
		NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   localizedDescription, NSLocalizedDescriptionKey, 
								   localizedFailureReason, NSLocalizedFailureReasonErrorKey, 
								   nil];
		NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"NextGenVideoPlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
	
	// At this point we're ready to set up for playback of the asset.
    	
    // Stop observing our prior AVPlayerItem, if we have one.
    if (self.playerItem) {
        
        [self.playerItem removeObserver:self forKeyPath:kAVPlayerItemStatusKVO];
        [self.playerItem removeObserver:self forKeyPath:kAVPlayerItemDurationKVO];
        [self.playerItem removeObserver:self forKeyPath:kAVPlayerItemPlaybackBufferEmptyKVO];
        [self.playerItem removeObserver:self forKeyPath:kAVPlayerItemPlaybackLikelyToKeepUpKVO];
		
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.player.currentItem];
    }
	
    // Create a new instance of AVPlayerItem from the now successfully loaded AVAsset.
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
      
    
    
        
    
    // Observe the player item "status" key to determine when it is ready to play.
    [self.playerItem addObserver:self 
                      forKeyPath:kAVPlayerItemStatusKVO
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:VideoPlayerStatusObservationContext];
    
    // Observe the player item "duration" key to determine when it is ready to play.
    [self.playerItem addObserver:self
                      forKeyPath:kAVPlayerItemDurationKVO
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:VideoPlayerDurationObservationContext];
    
    // Observe playback buffer
    [self.playerItem addObserver:self
                       forKeyPath:kAVPlayerItemPlaybackBufferEmptyKVO
                          options:NSKeyValueObservingOptionNew
                          context:VideoPlayerBufferEmptyObservationContext];
    
    // Observe playback buffer status
    [self.playerItem addObserver:self
                       forKeyPath:kAVPlayerItemPlaybackLikelyToKeepUpKVO
                          options:NSKeyValueObservingOptionNew
                          context:VideoPlayerPlaybackLikelyToKeepUpObservationContext];
	
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.player.currentItem];
	
    /* Create new player, if we don't already have one. */
    if (!self.player) {
        /* Get a new AVPlayer initialized to play the specified player item. */
        
        [self setPlayer:[AVQueuePlayer playerWithPlayerItem:self.playerItem]];
        
        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did 
         occur.*/
        [self.player addObserver:self 
                      forKeyPath:kAVPlayerCurrentItemKVO
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:VideoPlayerCurrentItemObservationContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self 
                      forKeyPath:kAVPlayerRateKVO
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:VideoPlayerRateObservationContext];
        
        
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != self.playerItem) {
        /* Replace the player item with a new player item. The item replacement occurs 
         asynchronously; observe the currentItem property to find out when the 
         replacement will/did occur
		 
		 If needed, configure player item here (example: adding outputs, setting text style rules,
		 selecting media options) before associating it with a player
		 */
        
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    }
    
    [self.scrubber setValue:0.0];
}


//=========================================================
# pragma mark - Asset Key Value Observing
//=========================================================

/* ---------------------------------------------------------
**  Called when the value at the specified key path relative
**  to the given object has changed. 
**  Adjust the movie play and pause button controls when the 
**  player item "status" value changes. Update the movie 
**  scrubber control when the player item is ready to play.
**  Adjust the movie scrubber control when the player item 
**  "rate" value changes. For updates of the player
**  "currentItem" property, set the AVPlayer for which the 
**  player layer displays visual output.
**  NOTE: this method is invoked on the main queue.
** ------------------------------------------------------- */

- (void)observeValueForKeyPath:(NSString*) path 
			ofObject:(id)object 
			change:(NSDictionary*)change 
			context:(void*)context {
	/* AVPlayerItem "status" property value observer. */
	if (context == VideoPlayerStatusObservationContext) {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status){
            /* Indicates that the status of the player is not yet known because 
             it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown:{
                // Set player state
                [self setState:NextGenVideoPlayerStateUnknown];
            }
            break;
                
            case AVPlayerStatusReadyToPlay:{
                /* Once the AVPlayerItem becomes ready to play, i.e. 
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                
                // Set player state
                [self setState:NextGenVideoPlayerStateReadyToPlay];
                
                // Notification
                [[NSNotificationCenter defaultCenter] postNotificationName:kNextGenVideoPlayerItemReadyToPlayNotification object:nil];
                
            }
            break;
                
            case AVPlayerStatusFailed:{
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:playerItem.error];
            }
            break;
        }
        
        // Sync play/pause buttons
        [self syncPlayPauseButtons];
	}
    // AVPlayer "duration" property value observer
    else if (context == VideoPlayerDurationObservationContext) {
        NSNumber *duration = @(CMTimeGetSeconds(self.playerItem.duration));
        if (duration.intValue > 1) {
            if (_durationLabel) {
                _durationLabel.text = [self timeStringFromSecondsValue:duration.intValue];
            }
            
            NSDictionary *durationInfo = @{ kAVPlayerItemDurationKVO: duration };
            
            // Post notification
            [[NSNotificationCenter defaultCenter] postNotificationName:kNextGenVideoPlayerItemDurationDidLoadNotification object:self userInfo:durationInfo];
        }
    }
	/* AVPlayer "rate" property value observer. */
	else if (context == VideoPlayerRateObservationContext) {
        // Set player state
        NSNumber *newRate = change[NSKeyValueChangeNewKey];
        if (newRate.boolValue) {
            [self setState:NextGenVideoPlayerStateVideoPlaying];
        } else {
            [self setState:NextGenVideoPlayerStateVideoPaused];
        }
        [self syncPlayPauseButtons];
	}
	/* AVPlayer "currentItem" property observer.
        Called when the AVPlayer replaceCurrentItemWithPlayerItem: 
        replacement will/did occur. */
	else if (context == VideoPlayerCurrentItemObservationContext) {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* Is the new player item null? */
        if (newPlayerItem == (id)[NSNull null]) {
            self.playerControlsEnabled = NO;
        } else { /* Replacement of player currentItem has occurred */
            /* Set the AVPlayer for which the player layer displays visual output. */
            [self.playbackView setPlayer:self.player];
            
            [self setViewDisplayName];
            
            /* Specifies that the player should preserve the video’s aspect ratio and 
             fit the video within the layer’s bounds. */
            [self.playbackView setVideoFillMode:AVLayerVideoGravityResizeAspect];
            
            [self syncPlayPauseButtons];
        }
	}
    else if (context == VideoPlayerBufferEmptyObservationContext) {
        //DDLogInfo(@"playbackBufferEmpty: %@", self.playerItem.isPlaybackBufferEmpty ? @"yes" : @"no");
        
        // Set player state
        [self setState:NextGenVideoPlayerStateVideoLoading];
        
        if (self.playerItem.isPlaybackBufferEmpty && CMTimeGetSeconds([self.playerItem currentTime]) > 0 && CMTimeGetSeconds([self.playerItem currentTime]) < CMTimeGetSeconds([self playerItemDuration]) - 1 && [self isPlaying]) {
            
            // NextGenVideoPlayerDelegate - bufferring started
            if (self.playerItem.isPlaybackBufferEmpty && self.delegate && [self.delegate respondsToSelector:@selector(videoPlayer:isBuffering:)]) {
                [self.delegate videoPlayer:self isBuffering:YES];
            }
            
            // Dispatch notification
            [[NSNotificationCenter defaultCenter] postNotificationName:kNextGenVideoPlayerPlaybackBufferEmptyNotification object:nil];
        }
        
    }
    else if (context == VideoPlayerPlaybackLikelyToKeepUpObservationContext) {
        //DDLogInfo(@"playbackLikelyToKeepUp: %@", self.playerItem.playbackLikelyToKeepUp ? @"yes" : @"no");
        
        if (self.state != NextGenVideoPlayerStateVideoPaused && self.playerItem.playbackLikelyToKeepUp && ![self isPlaying]) {
            // NextGenVideoPlayerDelegate - bufferring ended
            if (self.playerItem.playbackLikelyToKeepUp && self.delegate && [self.delegate respondsToSelector:@selector(videoPlayer:isBuffering:)]) {
                [self.delegate videoPlayer:self isBuffering:NO];
            }
            
            // Dispatch notification
            [[NSNotificationCenter defaultCenter] postNotificationName:kNextGenVideoPlayerPlaybackLikelyToKeepUpNotification object:nil];
            
            // Play
            if (!isSeeking && hasSeekedToPlaybackSyncStartTime) {
                [self playVideo];
            }
        }
    }
	else {
		[super observeValueForKeyPath:path ofObject:object change:change context:context];
	}
}

@end
