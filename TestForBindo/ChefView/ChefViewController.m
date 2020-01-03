//
//  ChefViewController.m
//  ALayoutDemo
//
//  Created by bell on 2019/12/31.
//  Copyright © 2019 Splendour Bell. All rights reserved.
//

#import "ChefViewController.h"
#import <ALayout/ALayout.h>
#import "WorkerManger.h"
#import "Task.h"

const NSInteger COUNT_OF_WORKER = 7;
const NSInteger TOTAL_OF_WORK = 1000;

#define Layout_ChefInfo @"@layout/ChefInfo"
#define Layout_FactorySummaryChefItem @"@layout/FactorySummaryChefItem"
#define Layout_ChefViewController @"@layout/ChefViewController"
#define Layout_ChefFinishedTaskItem @"@layout/ChefFinishedTaskItem"

@interface ChefViewController () <WorkerMangerDelegate>

@property (nonatomic, strong) WorkerManger* workManager;

@property (nonatomic, strong) NSArray<NSString*>* backgrounds;

@property (nonatomic, strong) NSArray<NSString*>* textColors;

@end

@implementation ChefViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configWorkManager];
    [self resetView];
    [self showConfirm];
}

- (void)configWorkManager
{
    self.workManager = [[WorkerManger alloc] initWithWorker:COUNT_OF_WORKER];
    self.workManager.delegate = self;
    [self.workManager addTask:TOTAL_OF_WORK];
}

- (void)resetView
{
    NSLog(@"resetView");
    AViewNode* viewNode = AViewNode.new;
    viewNode.actionTarget = self;
    
    AViewNode* chefsTableNode = viewNode[@"ChefsTable"];
    AViewNode* factorySummaryViewsNode = viewNode[@"factorySummaryViews"];
    
    NSInteger numberOfWorkers = self.workManager.numberOfWorkers;
    
    NSMutableArray<AViewNode*>* factorySummaryViewNodes = [[NSMutableArray alloc] initWithCapacity:numberOfWorkers];
    NSMutableArray<AViewNode*>* chefViewNodes = [[NSMutableArray alloc] initWithCapacity:numberOfWorkers];
    for(NSInteger i = 0; i < numberOfWorkers; i++)
    {
        AViewNode* chefViewNode = [[AViewNode alloc] initWithLayout:Layout_ChefInfo];
        chefViewNode[@"switchButton"].extData = @(i);
        chefViewNode.tag = 'chef'+i;
        [chefViewNodes addObject:chefViewNode];
        
        AViewNode* summaryViewNode = [[AViewNode alloc] initWithLayout:Layout_FactorySummaryChefItem];
        summaryViewNode.tag = 'smry'+i;
        [factorySummaryViewNodes addObject:summaryViewNode];
        
        chefViewNode[@"chef_id"].text = [NSString stringWithFormat:@"Pizza Chef %@", @(i)];
    }
    
    factorySummaryViewsNode.children = factorySummaryViewNodes;
    chefsTableNode.children = chefViewNodes;
    
    AViewCreator* viewCreator = [AViewCreator viewCreatorWithName:Layout_ChefViewController withTarget:self];
    UIView* view = [viewCreator loadViewHierarchy];
    if(self.view.bounds.size.height < 500)
    {
        view[@"contentView"].layoutParams.layout_height = 500;
    }
    [viewNode updateToView:view];
    [self.view addLayoutContentView:view];
    [self updateData];
    [self.view layoutSubviews];
}

- (void)updateData
{
    NSInteger numberOfWorkers = self.workManager.numberOfWorkers;

    UIView* chefsTable = self.view[@"ChefsTable"];
    UIView* factorySummaryViews = self.view[@"factorySummaryViews"];
    
    BOOL runningAnyOne = NO;
    
    for(NSInteger i = 0; i < numberOfWorkers; i++)
    {
        NSInteger remainingCount = [self.workManager remainingCount:i];
        NSTimeInterval speedTime = [self.workManager speedTime:i];
        NSString* speedText = [NSString stringWithFormat:@"Remaining Pizza: %@\nSpeed:%@ seconds per pizza",@(remainingCount), @(speedTime)];
        UIView* chefsTableItem = [chefsTable viewWithTag:'chef'+i];
        AViewNode* chefViewNode = AViewNode.new;
        chefViewNode[@"speedText"].text = speedText;
        
        BOOL running = [self.workManager running:i];
        runningAnyOne = runningAnyOne || running;
        chefViewNode[@"switchButton"].on = running;
        [chefViewNode updateToView:chefsTableItem];
        
        AViewNode* summaryViewNode = AViewNode.new;
        summaryViewNode[@"factorySummaryChefItem"].text = [NSString stringWithFormat:@"Pizza Chef 0: %@", @(remainingCount)];
        [summaryViewNode updateToView:[factorySummaryViews viewWithTag:'smry'+i]];
        
        UITableView* tableView = chefsTableItem[@"tableView"];
        [self updateTableViewDetail:i tableView:tableView];
    }
    
    SwitchControl* switchControl = self.view[@"switchAll"];
    switchControl.on = runningAnyOne;
}

- (void)updateTableViewDetail:(NSInteger)workId tableView:(UITableView*)tableView
{
    TableViewNodeAdapter* tableViewAdapter = [TableViewNodeAdapter tableViewNodeAdapter:tableView];
    NSArray<Task*>* finishedTasks = [self.workManager finishedTasks:workId];
    NSMutableArray<AViewNode*>* viewNodes = [[NSMutableArray alloc] initWithCapacity:finishedTasks.count];
    [finishedTasks enumerateObjectsUsingBlock:^(Task * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AViewNode* viewNode = [[AViewNode alloc] initWithLayout:Layout_ChefFinishedTaskItem];
        AViewNode* textNode = viewNode[@"text"];
        textNode.text = [NSString stringWithFormat:@"PIZZA_%04d", (int)obj.job];
        textNode.forHeight = YES;
        textNode.background = self.backgrounds.count <= workId ? self.backgrounds.firstObject : self.backgrounds[workId];
        textNode.textColor = self.textColors.count <= workId ? self.textColors.firstObject : self.textColors[workId];
        [viewNodes addObject:viewNode];
    }];
    tableViewAdapter.viewNodes = viewNodes;
//    if(viewNodes.count > 0)
//    {
//        [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:viewNodes.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
//    }
}

- (void)showConfirm
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"点击确定开始工作" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* alertAction = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        [self.workManager start];
    }];
    [alert addAction:alertAction];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:NO completion:^{
            
        }];
    });
}

- (NSArray<NSString*>*)backgrounds
{
    if(!_backgrounds)
    {
        _backgrounds = @[
            @"#ece3ff",@"#ffeae5",@"#fff3b0",@"#ddfef0",@"#ece3ff",@"#dceaff",@"#fff3b0"
        ];
    }
    return _backgrounds;
}

- (NSArray<NSString*>*)textColors
{
    if(!_textColors)
    {
        _textColors = @[
            @"#4b1796",@"#d52900",@"#3b495d",@"#006c46",@"#4b1796",@"#1739a9",@"#3b495d"
        ];
    }
    return _textColors;
}

#pragma mark view action

- (void)workerSwitchAction:(SwitchControl*)switchControl
{
    NSInteger workId = [switchControl.viewParams.extData integerValue];
    if(switchControl.on)
    {
        [self.workManager resume:workId];
    }
    else
    {
        [self.workManager pause:workId];
    }
}

- (void)add10Pizza
{
    [self.workManager addTask:10];
    dispatch_async(dispatch_get_main_queue(), ^{
       [self updateData];
    });
}

- (void)add100Pizza
{
    [self.workManager addTask:100];
    dispatch_async(dispatch_get_main_queue(), ^{
       [self updateData];
    });
}

- (void)switchAll:(SwitchControl*)switchControl
{
    if(switchControl.on)
    {
        [self.workManager resumeAll];
    }
    else
    {
        [self.workManager pauseAll];
    }
}

#pragma mark WorkerMangerDelegate imp

- (void)completion:(Worker *)worker task:(Task *)task
{
    //TODO:优化为仅更新对应worker的变化
    [self updateData];
}

- (void)runningStateChanged:(Worker *)worker running:(BOOL)running
{
    //TODO:优化为仅更新对应worker的变化
    [self updateData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self resetView];
}

@end

