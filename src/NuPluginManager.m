//
//  ObjCPluginManager.m
//  PluginManager
//
//  Created by Grayson Hansard
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import "NuPluginManager.h"


@implementation NuPluginManager

@synthesize plugins = _plugins;

+(void)load {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	if (NSClassFromString(@"Nu")) [PluginManager registerManager:[[self new] autorelease]];
	[pool release];
}

-(NSString *)name { return @"Nu"; }
-(NSArray *)extensions { return [NSArray arrayWithObject:@"nu"]; }

- (id)init
{
	self = [super init];
	if (!self) return nil;
	
	return self;
}

- (void)dealloc
{
	self.plugins = nil;
	[super dealloc];
}

- (void)build
{
	NSMutableDictionary *plugins = [NSMutableDictionary dictionary];
	self.plugins = plugins;
	for (NSString *path in [PluginManager pluginFilesForSubmanager:self])
	{
		id parser = [Nu parser];
		NSString *nuCode = [NSString stringWithContentsOfFile:path];
		[parser parseEval:nuCode];
		NSString *property = [parser parseEval:@"(actionProperty)"];
		
		NSMutableArray *arr = [plugins objectForKey:property];
		if (!arr) arr = [NSMutableArray array];
		[arr addObject:nuCode];
		[plugins setObject:arr forKey:property];
		[parser close];
	}
}

-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue
{
	if (!self.plugins) [self build];
	NSArray *plugins = [self.plugins objectForKey:property];
	if (!plugins || ![plugins count]) return nil;
	
	NSEnumerator *pluginEnumerator = [plugins objectEnumerator];
	id plugin;
	NSMutableArray *ret = [NSMutableArray array];
	withValue = withValue ? withValue : [NSNull null];
	forValue = forValue ? forValue : [NSNull null];
	while (plugin = [pluginEnumerator nextObject])
	{
		id parser = [Nu parser];
		[parser parseEval:plugin];
		[parser setValue:forValue forKey:@"_pluginWithValue"];
		[parser setValue:withValue forKey:@"_pluginForValue"];
		if ([[parser parseEval:@"(actionEnable _pluginWithValue _pluginForValue)"] boolValue])
			[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[parser parseEval:@"(actionTitle _pluginWithValue _pluginForValue)"], @"title",
				plugin, @"plugin",
				nil]];
		[parser close];
	}
	
	return ret;
}

-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue
{
	withValue = withValue ? withValue : [NSNull null];
	forValue = forValue ? forValue : [NSNull null];
	NSString *nuCode = [plugin objectForKey:@"plugin"];
	id parser = [Nu parser];
	[parser parseEval:nuCode];
	[parser setValue:forValue forKey:@"_pluginWithValue"];
	[parser setValue:withValue forKey:@"_pluginForValue"];
	[parser parseEval:@"(actionPerform _pluginWithValue _pluginForValue)"];
	[parser close];
}

-(id)runScriptAtPath:(NSString *)path
{
	id parser = [Nu parser];
	id ret = [parser parseEval:[NSString stringWithContentsOfFile:path]];
	[parser close];
	return ret;
}

@end
