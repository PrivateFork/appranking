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

#import "ARCategoryTuple.h"
#import "ARConfiguration.h"
#import "SBJSON+Additions.h"


static NSString * const kFeedURLTemplate_SelectedCategory = @"http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/%@/sf=%@/limit=300/genre=%@/json";
static NSString * const kFeedURLTemplate_All = @"http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/%@/sf=%@/limit=300/json";

static NSArray *typeNames;


NSString * tupleTypeName(CategoryTupleType type) {
	return [typeNames objectAtIndex:type];
}

NSString * tupleTypeUrlPart(CategoryTupleType type) {
	NSString *typeName = tupleTypeName(type);
	return [NSString stringWithFormat:@"%@applications", [[typeName stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString]];
}

@implementation ARCategoryTuple

@synthesize name, type;

+ (void)initialize {
	typeNames = [[NSArray alloc] initWithObjects:@"Top Free", @"Top Paid", 
				 @"Top Grossing", @"Top Free iPad", @"Top Paid iPad", 
				 @"Top Grossing iPad", nil];
}

- (id)initWithName:(NSString *)categoryName type:(CategoryTupleType)tupleType {
	self = [super init];
	if (self != nil) {
		if (categoryName) {
			assert([categoryName length] > 0);
		}
		name = [categoryName copy];
		type = tupleType;
	}
	return self;
}

- (NSError *)errorForUnderlyingError:(NSError *)error {
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:@"Unable to create category from dictionary" forKey:NSLocalizedDescriptionKey];
	if (error) {
		[userInfo setObject:error forKey:NSUnderlyingErrorKey];
	}
	return [NSError errorWithDomain:@"CategoryTupleErrorDomain" code:0 userInfo:userInfo];
}

- (id)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
	self = [super init];
	if (self != nil) {
		NSError *underlyingError = nil;
		
		NSString *category = [dictionary stringForKey:@"category" error:&underlyingError];
		if (underlyingError) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			[self release];
			self = nil;
			return self;
		}
		name = [category copy];
		NSString *typeStr = [dictionary stringForKey:@"type" error:&underlyingError];
		if (underlyingError) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			[self release];
			self = nil;
			return self;
		}
		if (![typeNames containsObject:typeStr]) {
			if (error) {
				*error = [self errorForUnderlyingError:underlyingError];
			}
			[self release];
			self = nil;
			return self;
		}
		type = [typeNames indexOfObject:typeStr];
	}
	return self;
}

- (void)dealloc {
	[name release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
	return [self retain];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ (%@)", (name?name:@"All"), tupleTypeName(type)];
}

- (BOOL)isEqual:(id)object {
	if (object == self)
        return YES;
    if (!object || ![object isKindOfClass:[self class]])
        return NO;
	
	ARCategoryTuple *ref = (ARCategoryTuple *)object;
	return [name isEqualToString:ref.name] && type == ref.type;
}

- (NSUInteger)hash {
	int prime = 31;
	int result = 1;
	result += prime * [name hash];
	result += prime * type;
	return result;
}

- (NSComparisonResult)compare:(ARCategoryTuple *)otherTuple {
	NSComparisonResult result;
	if (name && !otherTuple.name) {
		result = NSOrderedDescending;
	} else if (!name && otherTuple.name) {
		result = NSOrderedAscending;
	} else {
		result = [name compare:otherTuple.name];
	}
	if (result == NSOrderedSame) {
		if (type < otherTuple.type) {
			result = NSOrderedAscending;
		} else if (type > otherTuple.type) {
			result = NSOrderedDescending;
		}
	}
	return result;

}

- (NSURL *)rankingURLForCountry:(NSString *)country {
	ARConfiguration *config = [ARConfiguration sharedARConfiguration];
	NSString *storeId = [config.appStoreIds objectForKey:country];
	if (!storeId) {
		return nil;
	}
	if (name) {
		NSString *ganreId = [config.genres objectForKey:name];
		if (!ganreId) {
			return nil;
		}
		return [NSURL URLWithString:[NSString stringWithFormat:kFeedURLTemplate_SelectedCategory, tupleTypeUrlPart(type), storeId, ganreId]];
	} else {
		return [NSURL URLWithString:[NSString stringWithFormat:kFeedURLTemplate_All, tupleTypeUrlPart(type), storeId]];
	}
}
			   
- (id)proxyForJson {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:type] forKey:@"type"];
	if (name) {
		[dict setObject:name forKey:@"name"];
	}
	return dict;
}

@end
