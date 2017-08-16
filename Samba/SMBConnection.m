//
//  SMBConnection.m
//  WD Content TV
//
//  Created by Сергей Сейтов on 13.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

#import "SMBConnection.h"

#import "TOSMBConstants.h"
#import "TONetBIOSNameService.h"
#import "TONetBIOSNameServiceEntry.h"

#import <bdsm/smb_session.h>
#import <bdsm/smb_share.h>
#import <bdsm/smb_stat.h>
#import <bdsm/smb_dir.h>
#import <arpa/inet.h>

#if IOS
#include "WD_Content-Swift.h"
#else
#include "WD_Content_TV-Swift.h"
#endif

@interface SMBConnection () {
}

@property (nonatomic, assign) smb_session *session;

@end

@implementation SMBConnection

- (instancetype)init {
    self = [super init];
    if (self) {
        _session = nil;
    }
    return self;
}

- (void)dealloc {
    if (_session != nil) {
        smb_session_destroy(_session);
    }
}

- (bool)connectTo:(NSString*)host port:(int)port user:(NSString*)user password:(NSString*)password {
    
    if (_session != nil) {
        smb_session_destroy(_session);
    }
    
    TONetBIOSNameService *nameService = [[TONetBIOSNameService alloc] init];
    NSString* hostName = [nameService lookupNetworkNameForIPAddress:host];
    
    struct sockaddr_in   sin;
    memset ((char *)&sin,0,sizeof(sin));
    sin.sin_family = AF_INET;
    sin.sin_addr.s_addr = inet_addr(host.UTF8String);
    sin.sin_port = htons ( port );

    _session = smb_session_new();
    int err = smb_session_connect(_session, hostName.UTF8String, sin.sin_addr.s_addr, SMB_TRANSPORT_TCP);
    if (err != 0) {
        smb_session_destroy(_session);
        _session = nil;
        return false;
    }
    if (smb_session_is_guest(_session) >= 0) {
        return true;
	} else {
		//Attempt a login. Even if we're downgraded to guest, the login call will succeed
		smb_session_set_creds(_session, hostName.UTF8String, user.UTF8String, password.UTF8String);
		int result = smb_session_login(_session);
		return ( result >= 0);
	}
}

- (void)disconnect {
	smb_session_destroy(_session);
	_session = nil;
}

- (bool)isConnected {
	return (_session != nil);
}


static NSString* relativePath(NSString* path)
{
    //work out the remainder of the file path and create the search query
    NSString *relativePath = [Node filePathExcludingSharePathFromPath:path];
    //prepend double backslashes
    relativePath = [NSString stringWithFormat:@"\\%@",relativePath];
    //replace any additional forward slashes with backslashes
    relativePath = [relativePath stringByReplacingOccurrencesOfString:@"/" withString:@"\\"]; //replace forward slashes with backslashes
    //append double backslash if we don't have one
    if (![[relativePath substringFromIndex:relativePath.length-1] isEqualToString:@"\\"])
        relativePath = [relativePath stringByAppendingString:@"\\"];
    
    //Add the wildcard symbol for everything in this folder
    return [relativePath stringByAppendingString:@"*"]; //wildcard to search for all files
}

- (NSArray *)folderContentsByRoot:(Node*)root
{
  
    if (_session == nil) {
        return [NSMutableArray array];
    }
    
    //If the path is nil, or '/', we'll be specifically requesting the
    //parent network share names as opposed to the actual file lists
    
    if (root == nil) {
        NSMutableArray *shareList = [NSMutableArray array];
        smb_share_list list;
        size_t shareCount = 0;
        smb_share_get_list(_session, &list, &shareCount);
        if (shareCount == 0)
            return shareList;
        
        for (NSInteger i = 0; i < shareCount; i++) {
            const char *shareName = smb_share_list_at(list, i);
			
            //Skip system shares suffixed by '$'
            if (shareName[strlen(shareName)-1] == '$')
                continue;
            
            NSString *shareNameString = [NSString stringWithCString:shareName encoding:NSUTF8StringEncoding];
            [shareList addObject:shareNameString];
        }
        
        smb_share_list_destroy(list);
        return [shareList sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
    //-----------------------------------------------------------------------------
    
    //Replace any backslashes with forward slashes
    NSString* path = [root.filePath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    
    //Work out just the share name from the path (The first directory in the string)
    NSString *shareName = [Node shareNameFromPath:path];
    
    //Connect to that share
    
    //If not, make a new connection
    const char *cStringName = [shareName cStringUsingEncoding:NSUTF8StringEncoding];
    smb_tid shareID = -1;
    smb_tree_connect(self.session, cStringName, &shareID);
    if (shareID == 0) {
        return [NSArray array];
    }
    
    //work out the remainder of the file path and create the search query
    NSString *relPath = relativePath(path);
    
    //Query for a list of files in this directory
    smb_stat_list statList = smb_find(self.session, shareID, relPath.UTF8String);
    size_t listCount = smb_stat_list_count(statList);
    if (listCount == 0) {
        return [NSArray array];
    }
    
    NSMutableArray *fileList = [NSMutableArray array];
    
    for (NSInteger i = 0; i < listCount; i++) {
        smb_stat item = smb_stat_list_at(statList, i);
        const char* name = smb_stat_name(item);
		
		if (strcmp(name, "$RECYCLE.BIN") == 0)
			continue;
		if (strcmp(name, "System Volume Information") == 0)
			continue;
		if (strstr(name, "HFS+ Private") != nil)
			continue;
		
		//Skip hidden files
        if (name[0] == '.')
            continue;
		
        bool isDir = (smb_stat_get(item, SMB_STAT_ISDIR) != 0);
        NSString* fileName = [[NSString alloc] initWithBytes:name length:strlen(name) encoding:NSUTF8StringEncoding];
        if ([fileName containsString:@" "]) {
            NSString* newFileName = [fileName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
            NSString* oldPath = [root.filePath stringByAppendingPathComponent:fileName];
            NSString* newPath = [root.filePath stringByAppendingPathComponent:newFileName];
            if (isDir) {
                if ([self moveDir:shareID oldPath:oldPath newPath:newPath]) {
                    fileName = newFileName;
                }
            } else {
                if ([self moveFile:shareID oldPath:oldPath newPath:newPath]) {
                    fileName = newFileName;
                }
            }
        }
        if (isDir) {
            Node* dir = [[Node alloc] initWithName:fileName isDir:isDir parent:root];
            [fileList addObject:dir];
        } else {
            if ([Model isValidMediaTypeWithName:fileName]) {
                Node* file = [[Node alloc] initWithName:fileName isDir:isDir parent:root];
                [fileList addObject:file];
            }
        }
    }
    smb_stat_list_destroy(statList);
    smb_tree_disconnect(_session, shareID);
    
    if (fileList.count == 0)
        return [NSArray array];
    else
        return [fileList sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
}

- (NSArray *)foldersByRoot:(Node*)root
{
    
    if (_session == nil) {
        return nil;
    }
    
    if (root == nil) {
        return nil;
    }
    
    //-----------------------------------------------------------------------------
    
    //Replace any backslashes with forward slashes
    NSString* path = [root.filePath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    
    //Work out just the share name from the path (The first directory in the string)
    NSString *shareName = [Node shareNameFromPath:path];
    
    //Connect to that share
    
    //If not, make a new connection
    const char *cStringName = [shareName cStringUsingEncoding:NSUTF8StringEncoding];
    smb_tid shareID = -1;
    if (smb_tree_connect(self.session, cStringName, &shareID) != 0) {
        return nil;
    }
    
    //work out the remainder of the file path and create the search query
    NSString *relPath = relativePath(path);
    
    //Query for a list of files in this directory
    smb_stat_list statList = smb_find(self.session, shareID, relPath.UTF8String);
    size_t listCount = smb_stat_list_count(statList);
    if (listCount == 0) {
        return nil;
    }
    
    NSMutableArray *fileList = [NSMutableArray array];
    
    for (NSInteger i = 0; i < listCount; i++) {
        smb_stat item = smb_stat_list_at(statList, i);
        const char* name = smb_stat_name(item);
        
        if (strcmp(name, "$RECYCLE.BIN") == 0)
            continue;
        if (strcmp(name, "System Volume Information") == 0)
            continue;
        if (strstr(name, "HFS+ Private") != nil)
            continue;
        
        //Skip hidden files
        if (name[0] == '.')
            continue;
        
        bool isDir = (smb_stat_get(item, SMB_STAT_ISDIR) != 0);
        NSString* fileName = [[NSString alloc] initWithBytes:name length:strlen(name) encoding:NSUTF8StringEncoding];
        if ([fileName containsString:@" "]) {
            NSString* newFileName = [fileName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
            NSString* oldPath = [root.filePath stringByAppendingPathComponent:fileName];
            NSString* newPath = [root.filePath stringByAppendingPathComponent:newFileName];
            if (isDir) {
                if ([self moveDir:shareID oldPath:oldPath newPath:newPath]) {
                    fileName = newFileName;
                }
            } else {
                if ([self moveFile:shareID oldPath:oldPath newPath:newPath]) {
                    fileName = newFileName;
                }
            }
        }
        if (isDir) {
            Node* file = [[Node alloc] initWithName:fileName isDir:isDir parent:root];
            [fileList addObject:file];
        }
    }
    smb_stat_list_destroy(statList);
    smb_tree_disconnect(self.session, shareID);
    
    if (fileList.count == 0)
        return nil;
    else
        return [fileList sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
}

#pragma mark - private methods

- (smb_fd)openFile:(NSString*)path {
	smb_tid treeID = 0;
	smb_fd fileID = 0;
	
    NSString *shareName = [Node shareNameFromPath:path];

	smb_tree_connect(_session, shareName.UTF8String, &treeID);
	if (!treeID)
		return 0;
	
    NSString *formattedPath = [Node filePathExcludingSharePathFromPath:path];
	formattedPath = [NSString stringWithFormat:@"\\%@",formattedPath];
	formattedPath = [formattedPath stringByReplacingOccurrencesOfString:@"/" withString:@"\\\\"];

	smb_fopen(_session, treeID, formattedPath.UTF8String, SMB_MOD_RO, &fileID);
	return fileID;
}

- (void)closeFile:(smb_fd)file {
	smb_fclose(_session, file);
}

- (int)readFile:(smb_fd)file buffer:(void*)buffer size:(size_t)size {
	return (int)smb_fread(_session, file, buffer, size);
}

- (int)seekFile:(smb_fd)file offset:(off_t)offset whence:(int)whence {
	return (int)smb_fseek(_session, file, offset, whence);
}

- (bool)moveDir:(smb_tid)treeID oldPath:(NSString*)oldPath newPath:(NSString*)newPath
{
    NSString *newDir = [Node filePathExcludingSharePathFromPath:newPath];
    newDir = [newDir stringByReplacingOccurrencesOfString:@"/" withString:@"\\\\"];
    int err = smb_directory_create(_session, treeID, newDir.UTF8String);
    if (err)
        return false;
    
    NSString *relPath = relativePath(oldPath);
    smb_stat_list statList = smb_find(_session, treeID, relPath.UTF8String);
    size_t listCount = smb_stat_list_count(statList);
    for (NSInteger i = 0; i < listCount; i++) {
        smb_stat item = smb_stat_list_at(statList, i);
        const char* name = smb_stat_name(item);
        NSString* oldName = [[NSString alloc] initWithBytes:name length:strlen(name) encoding:NSUTF8StringEncoding];
        NSString* _oldPath = [oldPath stringByAppendingPathComponent:oldName];
        NSString* _newPath = [newPath stringByAppendingPathComponent:oldName];
        if (![self moveFile:treeID oldPath:_oldPath newPath:_newPath])
            return false;
    }
    
    NSString *oldDir = [Node filePathExcludingSharePathFromPath:oldPath];
    oldDir = [oldDir stringByReplacingOccurrencesOfString:@"/" withString:@"\\\\"];
    return (smb_directory_rm(_session, treeID, oldDir.UTF8String) == 0);
}

- (bool)moveFile:(smb_tid)treeID oldPath:(NSString*)oldPath newPath:(NSString*)newPath
{
    NSString* old = [Node filePathExcludingSharePathFromPath:oldPath];
    old = [NSString stringWithFormat:@"\\%@", old];
    old = [old stringByReplacingOccurrencesOfString:@"/" withString:@"\\\\"];
    
    NSString* new = [Node filePathExcludingSharePathFromPath:newPath];
    new = [NSString stringWithFormat:@"\\%@", new];
    new = [new stringByReplacingOccurrencesOfString:@"/" withString:@"\\\\"];
    
    int err = smb_file_mv(_session, treeID, old.UTF8String, new.UTF8String);
    return (err == 0);
}

@end
