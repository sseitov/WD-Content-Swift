//
//  SMBFile.m
//  WD Content TV
//
//  Created by Сергей Сейтов on 13.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

#import "SMBFile.h"

@implementation SMBFile

- (instancetype)initWithShareName:(NSString*)name {

    self = [super init];
    if (self != nil) {
        _name = name;
        _directory = true;
        _filePath = [NSString stringWithFormat:@"//%@/", name];
    }
    return self;
}

- (instancetype)initWithName:(NSString*)name isDir:(bool)isDir parentDirectoryPath:(NSString *)path
{
    if (self = [self init]) {
        _name = name;
        _directory = isDir;
		if (!_directory)
        _filePath = [path stringByAppendingPathComponent:_name];
    }
    
    return self;
}

@end
