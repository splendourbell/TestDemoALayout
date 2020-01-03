//
//  DebugRefreshView.m
//
//  Copyright © 2017年 splendourbell. All rights reserved.
//

#ifdef DEBUG

#import <UIKit/UIKit.h>
#import <ALayout/ALayout.h>
#import <objc/runtime.h>

@interface DebugRefreshView : UIWindow

@end

@implementation DebugRefreshView
{
    NSMutableArray* _keyCommands;
}

static DebugRefreshView* win = nil;
static void* _AttrForView = &_AttrForView;
static NSMutableArray* gDebugMapView;
static NSMutableArray* gDebugBorderView;
static BOOL showBorder = NO;

+ (void)load {

#if TARGET_OS_SIMULATOR
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self ShowTest];
    });
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ALayoutViewCreated:) name:@"ALayoutViewCreated" object:nil];
#endif
}

+ (void)ALayoutViewCreated:(NSNotification*)notify
{
    NSDictionary* dict = notify.object;
    UIView* view = dict[@"view"];
    NSMutableDictionary* attr = [dict[@"attr"] mutableCopy];
    [attr removeObjectForKey:@"children"];
    if(!gDebugMapView)
    {
        gDebugMapView = NSMutableArray.new;
    }
    [gDebugMapView addObject:view];
    __weak UIView* weakView = view;
    [view addDidLayoutBlock:@"layouted" block:^(CGRect rect) {
        [self addBorderView:weakView];
    }];
}

+ (void)removeDebugMapView
{
    gDebugMapView = nil;
    gDebugBorderView = nil;
}

+ (void)addBorderView:(UIView*)hostView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self addBorderViewRun:hostView];
    });
}
+ (void)addBorderViewRun:(UIView*)hostView
{
    if(![hostView findSuperviewByViewId:@"_mainView"])
    {
        return;
    }
    
    int color = hostView.superview.frame.size.height * hostView.superview.frame.size.width*hostView.frame.size.width * hostView.frame.size.height;
    UIView* borderView = [[UIView alloc] init];
    if(color % 3 == 0)
    {
        borderView.layer.borderColor = UIColor.redColor.CGColor;
    }
    else if(color % 3 == 1)
    {
        borderView.layer.borderColor = UIColor.greenColor.CGColor;
    }
    else
    {
        borderView.layer.borderColor = UIColor.blueColor.CGColor;
    }
    borderView.layer.borderWidth = 1;
    borderView.tag = 'bder';
    borderView.userInteractionEnabled = NO;
    CGRect bounds = hostView.bounds;
    bounds.origin.x += (color%2)?1:0;
    bounds.origin.y += (color%2)?1:0;
    bounds.size.width -= 2 * ((color%2)?1:0);
    bounds.size.height -= 2 * ((color%2)?1:0);
    borderView.frame = bounds;
    [hostView addSubview:borderView];
    borderView.alpha = showBorder?1:0;
    if(!gDebugBorderView)
    {
        gDebugBorderView = NSMutableArray.new;
    }
    [gDebugBorderView addObject:borderView];
}

+ (void)switchBorder
{
    showBorder = !showBorder;
    [gDebugBorderView enumerateObjectsUsingBlock:^(UIView*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.alpha = showBorder?1:0;
    }];
}

+ (void)ShowTest {

    AViewCreator* viewCreator = [AViewCreator viewCreatorWithName:@"@layout/Test.json" withTarget:self];
    if(viewCreator)
    {
        win = [[DebugRefreshView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        win.hidden = NO;
        win.windowLevel = 2000;
        [win makeKeyWindow];
        UIViewController* rootVC = UIViewController.new;
        win.rootViewController = rootVC;
        [win TestJson];
    }
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self ShowTest];
        });
    }
}

- (void)TestJson {
    [self[@"_fullView"] removeFromSuperview];
    [self[@"_mainView"] removeFromSuperview];
    
    ResourceManager* resourceManager = [ResourceManager defualtResourceManager];
    ResourceInfo* info = [resourceManager resourceInfo:@"@layout/Test.json"];
    NSData* jsonData = [NSData dataWithContentsOfFile:info.value];
    AViewCreator* viewCreator = nil;
    if(jsonData.length)
    {
        NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
        if(dict)
        {
            dict = @{
                @"class": @"RelativeLayout",
                @"layout_width": @"match_parent",
                @"layout_height": @"match_parent",
                @"background": @"#aaa",
                @"gravity": @"center_vertical",
                @"children":@[dict]
            };
            viewCreator = [AViewCreator viewCreatorWithRawAttr:dict withTarget:self];
            viewCreator.layout = @"@layout/Test.json";
        }
    }
    
    if(viewCreator)
    {
        [DebugRefreshView.class removeDebugMapView];
        UIView* contentView = [viewCreator loadViewHierarchy];
        contentView.viewId = @"_mainView";
        [self addLayoutContentView:contentView];
        
        [self becomeFirstResponder];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self TestJson];
        });
    }
    else
    {
        self.hidden = YES;
        [self.class ShowTest];
    }
}

- (void)addLayoutContentView:(UIView*)layoutContentView
{
    AViewCreator* viewCreator = [AViewCreator viewCreatorWithName:@"@layout/ATool/LayoutTool" withTarget:self];
    if(viewCreator)
    {
        UIView* contentView = [viewCreator loadViewHierarchy];
        contentView.viewId = @"_fullView";
        [contentView[@"_workplace"] addLayoutContentView:layoutContentView];
        [self.rootViewController.view addLayoutContentView:contentView];
        
        UIView* detailView = contentView[@"_detailView"];
        __weak typeof(self) weakSelf = self;
        [detailView addDidLayoutBlock:@"layouted" block:^(CGRect rect) {
            [weakSelf updateDetailView:weakSelf[@"_mainView"].subviews.firstObject];
        }];
        
        [layoutContentView addDidLayoutBlock:@"layouted" block:^(CGRect rect) {
            [weakSelf updateDetailView:weakSelf[@"_mainView"].subviews.firstObject];
        }];
    }
    else
    {
        [self.rootViewController.view addLayoutContentView:layoutContentView];
    }
}

- (void)updateDetailView:(UIView*)currentView
{
    UIView* detailView = self[@"_detailView"];
    
    CGRect containerRect = detailView.bounds;
    if(0 == containerRect.size.width * containerRect.size.height){
        return;
    }
    containerRect.origin.x += 10;
    containerRect.origin.y += 10;
    containerRect.size.width -= 20;
    containerRect.size.height -= 20;
    
    CGRect contentRect = currentView.frame;
    if(0 == contentRect.size.width * contentRect.size.height){
        return;
    }
    
    CGFloat contentRate = contentRect.size.width / contentRect.size.height;
    CGFloat containerRate = containerRect.size.width / containerRect.size.height;
    
    CGRect targetRect = containerRect;
    if(contentRate > containerRate){
        targetRect.size.height = containerRect.size.width / contentRate;
        targetRect.origin.y = (containerRect.size.height - targetRect.size.height) / 2;
    } else {
        targetRect.size.width = targetRect.size.height * contentRate;
        targetRect.origin.x = (containerRect.size.width - targetRect.size.width) / 2;
    }
    
    CGFloat scale = targetRect.size.width / contentRect.size.width;
    
    UIView* mirrorView = [[UIView alloc] initWithFrame:targetRect];
    mirrorView.backgroundColor = [UIColor colorWithRed:0x55/255.0 green:0x77/255.0 blue:0x66/255.0 alpha:1];
    [currentView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.tag == 'bder'){
            return;
        }
        CGRect subRect = obj.frame;
        subRect.origin.x *= scale;
        subRect.origin.y *= scale;
        subRect.size.width *= scale;
        subRect.size.height *= scale;
        UIView* subView = [[UIView alloc] initWithFrame:subRect];
        NSArray* colors = @[
            [UIColor colorWithRed:0x99/255.0 green:0xaa/255.0 blue:0x99/255.0 alpha:1],
            [UIColor colorWithRed:0x88/255.0 green:0x99/255.0 blue:0x88/255.0 alpha:1],
            [UIColor colorWithRed:0x77/255.0 green:0x88/255.0 blue:0x77/255.0 alpha:1]
        ];
        UIColor* color = colors[idx % colors.count];
        subView.backgroundColor = color;
        [mirrorView addSubview:subView];
        
        if(subRect.size.width < 5 || subRect.size.height < 5){
            UIView* centerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
            centerView.backgroundColor = [UIColor colorWithRed:0x55/255.0 green:0x66/255.0 blue:0x55/255.0 alpha:1];
            centerView.center = subView.center;
            [mirrorView addSubview:centerView];
        }
    }];
    
    [detailView addSubview:mirrorView];
}

#pragma mark command

- (NSArray<UIKeyCommand*>*)keyCommands
{
    if(!_keyCommands){
        _keyCommands = [NSMutableArray new];
 
        NSString* commandString = @"\r\b\t abcdefghijklmnopqrstuvwxyz`1234567890-=[]\\';/.,<>?\":{}|";
        int flags[] = {
            0,
            UIKeyModifierAlphaShift,
            UIKeyModifierShift,
            UIKeyModifierControl,
            UIKeyModifierAlternate,
            UIKeyModifierCommand,
            UIKeyModifierNumericPad
        };
        
        for(int i=0; i<commandString.length; i++){
            for(int flag = 0; flag < sizeof(flags)/sizeof(flags[0]); flag++){
                NSString* cmdStr = [commandString substringWithRange:NSMakeRange(i, 1)];
                UIKeyCommand* keyCommand = [UIKeyCommand
                                            keyCommandWithInput:cmdStr
                                            modifierFlags:flags[flag]
                                            action:@selector(keyEvent:)];
                [_keyCommands addObject:keyCommand];
            }
        }
        NSArray* preDefCmd = @[UIKeyInputUpArrow, UIKeyInputDownArrow, UIKeyInputLeftArrow, UIKeyInputRightArrow, UIKeyInputEscape];
        for(int i=0; i<preDefCmd.count; i++){
            for(int flag = 0; flag < sizeof(flags)/sizeof(flags[0]); flag++){
                UIKeyCommand* keyCommand = [UIKeyCommand
                                            keyCommandWithInput:preDefCmd[i]
                                            modifierFlags:flags[flag]
                                            action:@selector(keyEvent:)];
                [_keyCommands addObject:keyCommand];
            }
        }

    }
    return _keyCommands;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)keyEvent:(UIKeyCommand*)keyCommand
{
    NSDictionary* dict = @{
        @(0):@"0",
        @(UIKeyModifierAlphaShift):@"UIKeyModifierAlphaShift",
        @(UIKeyModifierShift):@"UIKeyModifierShift",
        @(UIKeyModifierControl):@"UIKeyModifierControl",
        @(UIKeyModifierAlternate):@"UIKeyModifierAlternate",
        @(UIKeyModifierCommand):@"UIKeyModifierCommand",
        @(UIKeyModifierNumericPad):@"UIKeyModifierNumericPad"
    };
    
    printf("-%s-%s-\n", keyCommand.input.UTF8String, [dict[@(keyCommand.modifierFlags)] UTF8String]);
    
    if(UIKeyModifierAlternate == keyCommand.modifierFlags){
        if([keyCommand.input isEqualToString:@"i"]){
            [self.class switchBorder];
        }
    }
}
    
@end

#endif

