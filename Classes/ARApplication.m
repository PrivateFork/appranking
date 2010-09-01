/*
 * Copyright (c) 2010 Todor Dimitrov
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "ARApplication.h"


@implementation ARApplication

@dynamic appStoreId, name, categories, iconData, rankEntries;
@synthesize iconImage;

- (void)awakeFromFetch {
	if (self.iconData) {
		self.iconImage = [[[NSImage alloc] initWithData:self.iconData] autorelease];
	}
}

- (NSImage *)iconImage {
	return iconImage;
}

- (void)setIconImage:(NSImage *)image {
	if (iconImage != image) {
		[self willChangeValueForKey:@"iconImage"];
		[iconImage release];
		iconImage = [image retain];
		if (iconImage) {
			self.iconData = [NSBitmapImageRep representationOfImageRepsInArray:[iconImage representations] 
																	 usingType:NSJPEGFileType
																	properties:nil];
		} else {
			self.iconData = nil;
		}
		[self didChangeValueForKey:@"iconImage"];
	}
}

- (void)dealloc {
	self.rankEntries = nil;
	self.appStoreId = nil;
	self.name = nil;
	self.categories = nil;
	self.iconData = nil;
	self.iconImage = nil;
	[super dealloc];
}

- (BOOL)validateCategories:(id *)value error:(NSError **)error {
	if (*value == nil) {
		return YES;
	}
	if ([*value count] == 0) {
		if (error) {
			*error = [NSError errorWithDomain:@"ARApplication" 
										 code:0 
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"At least one category should be specified"] 
																		  forKey:NSLocalizedDescriptionKey]];
		}
		return NO;
	} else {
		return YES;
	}
}

@end
