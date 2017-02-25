//
//  Demuxer.m
//  WD Content
//
//  Created by Sergey Seitov on 19.01.15.
//  Copyright (c) 2015 Sergey Seitov. All rights reserved.
//

#import "Demuxer.h"
#import "AudioDecoder.h"
#import "VTDecoder.h"
#include "ConditionLock.h"
#include <mutex>
#import "SMBConnection.h"

extern "C" {
#	include "libavformat/avformat.h"
};

@interface Demuxer () <DecoderDelegate> {
	
	dispatch_queue_t	_networkQueue;
	std::mutex			_audioMutex;
    
    unsigned char*		_ioBuffer;
    AVIOContext*		_ioContext;
    AVFormatContext*	_mediaContext;
}

@property (strong, nonatomic) VTDecoder *videoDecoder;
@property (strong, nonatomic) AudioDecoder *audioDecoder;

@property (atomic) int audioIndex;
@property (nonatomic) int videoIndex;

@property (strong, nonatomic) NSCondition *demuxerState;
@property (strong, nonatomic) NSConditionLock *threadState;
@property (atomic) BOOL stopped;
@property (atomic) BOOL buffering;

@property (strong, nonatomic, readonly) SMBConnection* connection;
@property (nonatomic, readonly) smb_fd file;

@end

static const int kBufferSize = 4 * 1024;

extern "C" {
    
    static int readContext(void *opaque, unsigned char *buf, int buf_size) {
        Demuxer* demuxer = (__bridge Demuxer *)(opaque);
        return [demuxer.connection readFile:demuxer.file buffer:buf size:buf_size];
    }
    
    static int64_t seekContext(void *opaque, int64_t offset, int whence) {
        Demuxer* demuxer = (__bridge Demuxer *)(opaque);
        return [demuxer.connection seekFile:demuxer.file offset:offset whence:whence];
    }
}

@implementation Demuxer

- (id)init
{
	self = [super init];
	if (self) {
        av_register_all();
        avcodec_register_all();
        int ret = avformat_network_init();
        NSLog(@"avformat_network_init = %d", ret);

		_audioDecoder = [[AudioDecoder alloc] init];
		_audioDecoder.delegate = self;
		_videoDecoder = [[VTDecoder alloc] init];
		_videoDecoder.delegate = self;
		
        _connection = [[SMBConnection alloc] init];
        _ioBuffer = new unsigned char[kBufferSize];
        _ioContext = avio_alloc_context((unsigned char*)_ioBuffer, kBufferSize, 0, (__bridge void*)self, readContext, NULL, seekContext);

		_networkQueue = dispatch_queue_create("com.vchannel.WD-Content.SMBNetwork", DISPATCH_QUEUE_SERIAL);
	}
	return self;
}

+ (void)setTimebaseForLayer:(AVSampleBufferDisplayLayer*)layer {
    CMTimebaseRef tmBase = nil;
    CMTimebaseCreateWithMasterClock(CFAllocatorGetDefault(), CMClockGetHostTimeClock(),&tmBase);
    layer.controlTimebase = tmBase;
    CMTimebaseSetTime(layer.controlTimebase, kCMTimeZero);
    CMTimebaseSetRate(layer.controlTimebase, 40.0);
}

- (NSArray*)openWithPath:(NSString*)path host:(NSString*)host port:(int)port user:(NSString*)user password:(NSString*)password
{
    if (![_connection connectTo:host port:port user:user password:password])
        return nil;
    
    _file = [_connection openFile:path];
    if (!_file)
        return nil;
    
    _mediaContext = avformat_alloc_context();
    _mediaContext->pb = _ioContext;
    _mediaContext->flags = AVFMT_FLAG_CUSTOM_IO;

    int err = avformat_open_input(&_mediaContext, "", NULL, NULL);
    if ( err < 0) {
        return NULL;
    }
    
    // Retrieve stream information
    avformat_find_stream_info(_mediaContext, NULL);
    
    _audioIndex = -1;
    _videoIndex = -1;
    AVCodecContext* enc;
    NSMutableArray *audioChannels = [NSMutableArray array];
    for (unsigned i=0; i<_mediaContext->nb_streams; ++i) {
        enc = _mediaContext->streams[i]->codec;
        if (enc->codec_type == AVMEDIA_TYPE_AUDIO && enc->codec_descriptor) {
            [audioChannels addObject:@{@"channel" : [NSNumber numberWithInt:i],
                                       @"codec" : [NSString stringWithFormat:@"%s, %d channels", enc->codec_descriptor->long_name, enc->channels]}];
        } else if (enc->codec_type == AVMEDIA_TYPE_VIDEO) {
            if ([_videoDecoder openWithContext:enc]) {
                _videoIndex = i;
            }
        }
    }
    
    return (_videoIndex >= 0) ? audioChannels : nil;
}

- (BOOL)changeAudio:(int)audioCahnnel
{
	std::unique_lock<std::mutex> lock(_audioMutex);
	
	[_audioDecoder stop];
	[_audioDecoder close];
	AVCodecContext* enc = _mediaContext->streams[audioCahnnel]->codec;
	if (![self.audioDecoder openWithContext:enc]) {
		enc = _mediaContext->streams[_audioIndex]->codec;
		[_audioDecoder openWithContext:enc];
		[_audioDecoder start];
		return NO;
	}
	self.audioIndex = audioCahnnel;
	[_audioDecoder start];
	return YES;
}

- (BOOL)play:(int)audioCahnnel
{
	AVCodecContext* enc = _mediaContext->streams[audioCahnnel]->codec;
	if (![_audioDecoder openWithContext:enc]) {
		return NO;
	}
	
	self.audioIndex = audioCahnnel;
 
	self.stopped = NO;

	[_audioDecoder start];
	[_videoDecoder start];
	
	_threadState = [[NSConditionLock alloc] initWithCondition:ThreadStillWorking];
	av_read_play(_mediaContext);
	
	dispatch_async(_networkQueue, ^() {
		while (!self.stopped) {
			AVPacket nextPacket;
			if (av_read_frame(_mediaContext, &nextPacket) < 0) { // eof
				break;
			}
			
			std::unique_lock<std::mutex> lock(_audioMutex);
			
			if (nextPacket.stream_index == self.audioIndex) {
				[_audioDecoder push:&nextPacket];
			} else if (nextPacket.stream_index == self.videoIndex) {
				[_videoDecoder push:&nextPacket];
			} else {
				av_packet_unref(&nextPacket);
			}
			
			ConditionLock locker(_demuxerState);
			while (_audioDecoder.isFull && _videoDecoder.isFull) {
				[_demuxerState wait];
			}
		}
		[_threadState lock];
		[_threadState unlockWithCondition:ThreadIsDone];
	});
	return YES;
}

- (void)close
{
	self.stopped = YES;
	
	[_audioDecoder stop];
	[_audioDecoder close];
	[_videoDecoder stop];
	[_videoDecoder close];
	
	[_threadState lockWhenCondition:ThreadIsDone];
	[_threadState unlock];
	
	avformat_close_input(&_mediaContext);
}

- (CMSampleBufferRef)takeVideo
{
	if (self.buffering || _audioDecoder.currentTime < 0) {
		return NULL;
	} else {
		return [_videoDecoder takeWithTime:_audioDecoder.currentTime];
	}
}

- (bool)enqueBufferOnLayer:(AVSampleBufferDisplayLayer*)layer {
    CMSampleBufferRef buffer = [self takeVideo];
    if (buffer) {
        [layer enqueueSampleBuffer:buffer];
        CFRelease(buffer);
        return true;
    } else {
        return false;
    }
}

- (void)decoder:(Decoder*)decoder changeState:(enum DecoderState)state
{
	switch (state) {
		case Continue:
		{
			ConditionLock locker(_demuxerState);
			[_demuxerState signal];
		}
			break;
		case StartBuffering:
			[self.delegate demuxer:self buffering:YES];
			self.buffering = YES;
			break;
		case StopBuffering:
			[self.delegate demuxer:self buffering:NO];
			self.buffering = NO;
			break;
		default:
			break;
	}
}

@end
