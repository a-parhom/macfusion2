//
//  MFPreferencesController.m
//  MacFusion2
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "MFPreferencesController.h"
#import "MFCore.h"
#import "MFClient.h"
#import "MFPreferences.h"
#import "MFLogging.h"

#define kMFPrefsPluginToolbarIdentifier @"Plugin"
#define kMFPrefsGeneralToolbarIdentifier @"General"
#define kMFPrefsInfoToolbarIdentifier @"Info"

@implementation MFPreferencesController
- (id)initWithWindowNibName:(NSString *)name {
	if (self = [super initWithWindowNibName: name]) {
		_client = [MFClient sharedClient];
		_sharedPreferences = [MFPreferences sharedPreferences];
	}
	
	return self;
}

- (NSArray *)prefsViews {
	return [NSArray arrayWithObjects: pluginPrefsView, generalPrefsView, infoPrefsView, nil];
}

- (void)awakeFromNib {
	NSDictionary* infoDict = [[NSBundle bundleForClass:[self class]] infoDictionary];

	[agentLoginItemButton setState:mfcGetStateForAgentLoginItem()];
	[menuLoginItemButton setState:[_sharedPreferences getBoolForPreference: kMFPrefsAutoloadMenuling]];
	NSString *fuseVersion = mfcGetFuseVersion();
	NSString *versionString = fuseVersion ? [NSString stringWithFormat: @"FUSE Version %@ Found", fuseVersion] : @"FUSE not Found!";
	[fuseVersionTextField setStringValue: versionString];

	[macfusionVersionInfo setStringValue: infoDict[@"CFBundleShortVersionString"]];
	[buildVersionInfo setStringValue: infoDict[@"CFBundleVersion"]];
	[githashVersionInfo setStringValue: infoDict[@"GitHash"]];
	[fuseVersionInfo setStringValue: fuseVersion];

	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: @"Preferences"];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:NO];
	[toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
	[[self window] setToolbar:toolbar];
	_prefsViewSizes = [NSMapTable new];
	_emptyView = [NSView new];
	for(NSView *view in [self prefsViews])	{
		NSValue *sizeValue = [NSValue valueWithSize:[view frame].size];
		[_prefsViewSizes setObject:sizeValue forKey:view];
	}
	
	[self toolbarItemChanged:[[toolbar items] objectAtIndex:0]];
}


- (IBAction)openWebsite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"https://macfusion-ng.github.io"]];
}

- (IBAction)loginItemCheckboxChanged:(id)sender {
	if (sender == agentLoginItemButton) {
		mfcSetStateForAgentLoginItem([sender state]);
	} else if (sender == menuLoginItemButton) {
		[[MFPreferences sharedPreferences] setBool:[sender state] forPreference:kMFPrefsAutoloadMenuling];
	} else {
		MFLogS(self, @"Invalid sender for loginItemCheckboxChanged");
	}
}

# pragma mark Toolbar
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
	NSToolbarItem *item = nil;

	if ([itemIdentifier  isEqual: kMFPrefsPluginToolbarIdentifier]) {
		item = [[NSToolbarItem alloc] initWithItemIdentifier: kMFPrefsPluginToolbarIdentifier];

		[item setLabel:@"Plugins"];
		[item setImage:[NSImage imageNamed: @"NSAdvanced"]];
	} else if ([itemIdentifier  isEqual: kMFPrefsGeneralToolbarIdentifier]) {
		item = [[NSToolbarItem alloc] initWithItemIdentifier: kMFPrefsGeneralToolbarIdentifier];
		[item setLabel:@"General"];
		[item setImage:[NSImage imageNamed: @"NSPreferencesGeneral"]];
	} else if ([itemIdentifier  isEqual: kMFPrefsInfoToolbarIdentifier]) {
		item = [[NSToolbarItem alloc] initWithItemIdentifier: kMFPrefsInfoToolbarIdentifier];
		[item setLabel:@"Info"];
		[item setImage:[NSImage imageNamed: @"NSInfo"]];
	}
	
	[item setTarget:self];
	[item setAction:@selector(toolbarItemChanged:)];	
	return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:kMFPrefsGeneralToolbarIdentifier, kMFPrefsPluginToolbarIdentifier, kMFPrefsInfoToolbarIdentifier, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [self toolbarAllowedItemIdentifiers:toolbar];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	return [self toolbarAllowedItemIdentifiers:toolbar];
}

- (IBAction)toolbarItemChanged:(id)sender {
	NSView *newView;
	if ([[sender itemIdentifier]  isEqual: kMFPrefsPluginToolbarIdentifier]) {
		newView = pluginPrefsView;
	} else if ([[sender itemIdentifier]  isEqual: kMFPrefsGeneralToolbarIdentifier]) {
		newView = generalPrefsView;
	} else if ([[sender itemIdentifier]  isEqual: kMFPrefsInfoToolbarIdentifier]) {
		newView = infoPrefsView;
	}else {
		return;
	}
	
	NSWindow *window = [self window];
	NSSize size = [[_prefsViewSizes objectForKey: newView] sizeValue];
	NSRect windowContentFrame = [window contentRectForFrameRect:[window frame]];
	windowContentFrame.origin.y += windowContentFrame.size.height;
	windowContentFrame.origin.y -= size.height;
	windowContentFrame.size.width = size.width;
	windowContentFrame.size.height = size.height;
	
	NSRect newWindowFrame = [window frameRectForContentRect:windowContentFrame];
	[[[self window] toolbar] setSelectedItemIdentifier:[sender itemIdentifier]];
	[window setContentView:_emptyView];
	[window setFrame:newWindowFrame display:YES animate:[window isVisible]];
	[window setContentView:newView];
}

@end
