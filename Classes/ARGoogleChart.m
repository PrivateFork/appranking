/**
 * Author: Todor Dimitrov
 * License: http://todor.mit-license.org/
 */

#import "ARGoogleChart.h"
#import "ARRankEntry.h"
#import "ARColor.h"


@interface ARGoogleChart()

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSMutableDictionary *postParameters;

@end


@implementation ARGoogleChart

@synthesize startDate = _startDate;
@synthesize endDate = _endDate;
@synthesize postParameters = _postParameters;

+ (NSDateFormatter *)dateFormatter 
{
	static NSDateFormatter *dateFormatter = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	});
	return dateFormatter;
}

// Same as simple encoding, but for extended encoding.
static NSString * const EXTENDED_MAP = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-.";

static NSString *extendedEncode(double value, double maxValue) 
{
	static NSUInteger EXTENDED_MAP_LENGTH;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		EXTENDED_MAP_LENGTH = [EXTENDED_MAP length];
	});
	
	NSString *encodedValue;
	double scaledVal = floor(EXTENDED_MAP_LENGTH * EXTENDED_MAP_LENGTH * value / maxValue);
	if(scaledVal > (EXTENDED_MAP_LENGTH * EXTENDED_MAP_LENGTH) - 1) {
		encodedValue = @"..";
	} else if (scaledVal < 0) {
		encodedValue = @"__";
	} else {
		// Calculate first and second digits and add them to the output.
		double quotient = floor(scaledVal / EXTENDED_MAP_LENGTH);
		double remainder = scaledVal - EXTENDED_MAP_LENGTH * quotient;
		encodedValue = [NSString stringWithFormat:@"%C%C", [EXTENDED_MAP characterAtIndex:quotient], [EXTENDED_MAP characterAtIndex:remainder]];
	}
	return encodedValue;
}

+ (id)chartForEntries:(NSArray *)entries sorted:(BOOL)sorted 
{
	return [[[self class] alloc] initWithEntries:entries sorted:sorted];
}

- (void)processSortedEntries:(NSArray *)entries 
{
	NSTimeInterval timeSpan = [self.endDate timeIntervalSinceDate:self.startDate];
	NSMutableDictionary *country2entries = [NSMutableDictionary dictionary];
	for (ARRankEntry *entry in entries) {
		NSMutableArray *data = [country2entries objectForKey:entry.country];
		if (!data) {
			data = [NSMutableArray array];
			[country2entries setObject:data forKey:entry.country];
		}
		[data addObject:entry];
	}
	
	NSMutableString *data = [NSMutableString stringWithFormat:@"e:"];
	NSMutableString *labels = [NSMutableString string];
	NSMutableString *lineSizes = [NSMutableString string];
	NSMutableString *colors = [NSMutableString string];
	NSMutableString *markers = [NSMutableString string];

	NSUInteger countryIndex = 0;
	for (NSString *country in country2entries) {
		NSArray *entriesForCountry = [country2entries objectForKey:country];
		NSMutableString *x = [NSMutableString string];
		NSMutableString *y = [NSMutableString string];
		
		for (ARRankEntry *entry in entriesForCountry) {
			NSString *timeValue = extendedEncode([entry.timestamp timeIntervalSinceDate:self.startDate], timeSpan);
			static double maxValue = 300.0;
			NSString *rankValue = extendedEncode(maxValue-[entry.rank doubleValue], maxValue);
			[x appendString:timeValue];
			[y appendString:rankValue];
		}
		
		[data appendFormat:@"%@,%@", x, y];
		[labels appendString:country];
		[lineSizes appendString:@"2"];
		[colors appendString:[ARColor colorForCountry:country].hex];
		[markers appendFormat:@"o,FF0000,%ld,-1,2", countryIndex];
		if (countryIndex++ < [country2entries count]-1) {
			[data appendString:@","];
			[labels appendString:@"|"];
			[lineSizes appendString:@"|"];
			[colors appendString:@","];
			[markers appendString:@"|"];
		}
	}
	
	[self.postParameters setObject:data forKey:@"chd"];
	[self.postParameters setObject:labels forKey:@"chdl"];
	[self.postParameters setObject:lineSizes forKey:@"chls"];
	[self.postParameters setObject:colors forKey:@"chco"];
	[self.postParameters setObject:markers forKey:@"chm"];
}

- (id)initWithEntries:(NSArray *)entries sorted:(BOOL)sorted 
{
	if (self = [super init]) {
		assert([entries count] > 1);
		
		NSArray *sortedEntries;
		if (!sorted) {
			sortedEntries = [entries sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" 
																														ascending:YES]]];
		} else {
			sortedEntries = entries;
		}
		self.startDate = ((ARRankEntry *)[sortedEntries objectAtIndex:0]).timestamp;
		self.endDate = ((ARRankEntry *)[sortedEntries lastObject]).timestamp;
		
		assert(self.startDate);
		assert(self.endDate);
		assert([self.startDate isLessThan:self.endDate]);
		
		NSMutableDictionary *postParameters = [NSMutableDictionary dictionary];
		NSDate *midPoint = [NSDate dateWithTimeInterval:[self.endDate timeIntervalSinceDate:self.startDate]/2 sinceDate:self.startDate];
		NSString *labels = [NSString stringWithFormat:@"0:|%@|%@|%@|1:|300|270|240|210|180|150|120|90|60|30|1|", 
							[[ARGoogleChart dateFormatter] stringFromDate:self.startDate],
							[[ARGoogleChart dateFormatter] stringFromDate:midPoint],
							[[ARGoogleChart dateFormatter] stringFromDate:self.endDate]];
		[postParameters setObject:labels forKey:@"chxl"];
		[postParameters setObject:@"0,10,50,90|1,300,270,240,210,180,150,120,90,60,30,1" forKey:@"chxp"];
		[postParameters setObject:@"1,300,0" forKey:@"chxr"];
		[postParameters setObject:@"x,y" forKey:@"chxt"];
		[postParameters setObject:@"700x420" forKey:@"chs"];
		[postParameters setObject:@"lxy" forKey:@"cht"];
		[postParameters setObject:@"0,10,4,8" forKey:@"chg"]; // Grid
		[postParameters setObject:@"40,20,20,30" forKey:@"chma"]; // Margins
        self.postParameters = postParameters;

		[self processSortedEntries:sortedEntries];
	}
	return self;
}

- (NSURLRequest *)URLRequest 
{
	NSURL *url = [NSURL URLWithString:@"http://chart.apis.google.com/chart"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"POST"];
	NSMutableString *postData = [NSMutableString string];
	NSUInteger count = 0;
	for (NSString *param in self.postParameters) {
		[postData appendFormat:@"%@=%@", param, [self.postParameters objectForKey:param]];
		if (count++ < [self.postParameters count]-1) {
			[postData appendString:@"&"];
		}
	}
	[request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
	return request;
}

- (NSImage *)image 
{
	NSError *error = nil;
	NSData *imageData = [NSURLConnection sendSynchronousRequest:[self URLRequest] returningResponse:NULL error:&error];
	if (imageData) {
		return [[NSImage alloc] initWithData:imageData];
	} else {
		NSLog(@"Unable to retrieve chart image, error = %@", [error localizedDescription]);
	}
	return nil;
}

@end
