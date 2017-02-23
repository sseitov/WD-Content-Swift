//
//  MovieController.h
//  WD Content
//
//  Created by Сергей Сейтов on 21.02.17.
//  Copyright © 2017 Sergey Seitov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@protocol MovieControllerDelegate <NSObject>

- (void)movie:(NSString*)path startWithAudio:(int)channel;

@end

@interface MovieController : UIViewController <GLKViewControllerDelegate>

@property (weak, nonatomic) id<MovieControllerDelegate> delegate;

@property (retain, nonatomic)	NSString*	host;
@property (nonatomic)			int			port;
@property (retain, nonatomic)	NSString*	user;
@property (retain, nonatomic)	NSString*	password;
@property (retain, nonatomic)	NSString*	filePath;
@property (nonatomic)			int			audioChannel;

@end
