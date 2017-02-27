//
//  SMBFile.h
//  WD Content TV
//
//  Created by Сергей Сейтов on 13.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMBFile : NSObject

@property (retain, nonatomic, readonly) NSString* name;         // The name of the file
@property (nonatomic, readonly) NSString *filePath;             // The filepath of this file, excluding the share name.
@property (nonatomic, readonly) bool directory;                 // Whether this file is a directory or not


- (instancetype)initWithShareName:(NSString*)name;
- (instancetype)initWithName:(NSString*)name isDir:(bool)isDir parentDirectoryPath:(NSString *)path;

@end
