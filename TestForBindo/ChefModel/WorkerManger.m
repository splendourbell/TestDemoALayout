//
//  WorkerManger.m
//  bindo
//
//  Created by splendourbell on 2019/12/31.
//  Copyright © 2019 bindo. All rights reserved.
//

#import "WorkerManger.h"
#import "Task.h"
#import "Worker.h"

@interface WorkerManger()<NSMachPortDelegate>

@property (nonatomic, strong) NSMutableArray<Worker*>* workers;

@property (nonatomic, assign) NSInteger totalWork;

@end

@implementation WorkerManger

- (instancetype)initWithWorker:(NSInteger)numberOfWorkers
{
    if(self = [super init])
    {
        self.totalWork = 0;
        [self createWorkers:numberOfWorkers];
    }
    return self;
}

- (void)createWorkers:(NSInteger)numberOfWorkers
{
    self.workers = [[NSMutableArray alloc] initWithCapacity:numberOfWorkers];
    for(NSInteger i = 0; i < numberOfWorkers; i++)
    {
        Worker* worker = [[Worker alloc] initWithId:i speedTime:i+1];
        __weak typeof(self) weakSelf = self;
        worker.completion = ^(Worker* worker, Task * _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf completion:worker task:task];
            });
        };
        worker.runningChanged = ^(Worker * _Nonnull worker, BOOL running) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf runningStateChanged:worker running:running];
            });
        };
        [self.workers addObject:worker];
    }
}

- (void)completion:(Worker*)worker task:(Task*)task
{
    if([_delegate respondsToSelector:@selector(completion:task:)])
    {
        [_delegate completion:worker task:task];
    }
}

- (void)runningStateChanged:(Worker*)worker running:(BOOL)running
{
    if([_delegate respondsToSelector:@selector(runningStateChanged:running:)])
    {
        [_delegate runningStateChanged:worker running:running];
    }
}

- (void)addTask:(NSInteger)count
{
    NSInteger numberOfWorkers = self.workers.count;
    for(NSInteger i = 0; i < numberOfWorkers; i++)
    {
        Worker* worker = self.workers[i];
        NSMutableArray<Task*>* tasks = [[NSMutableArray alloc] init];
        
        NSInteger lastTailIndex = (self.totalWork + numberOfWorkers-1 - i)/numberOfWorkers * numberOfWorkers;
        NSInteger sIndex = lastTailIndex + (i % numberOfWorkers);
        for(NSInteger j = sIndex; j < self.totalWork + count; j += numberOfWorkers)
        {
            Task* task = [[Task alloc] init];
            task.job = j+1;
            [tasks addObject:task];
        }
        [worker addTasks:tasks];
    }
    self.totalWork += count;
}

- (void)start
{
    [self.workers enumerateObjectsUsingBlock:^(Worker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj start];
    }];
}

- (void)pause:(NSInteger)workId
{
    [self.workers[workId] pause];
}

- (void)resume:(NSInteger)workId
{
    [self.workers[workId] resume];
}

- (void)pauseAll
{
    [self.workers enumerateObjectsUsingBlock:^(Worker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj pause];
    }];
}

- (void)resumeAll
{
    [self.workers enumerateObjectsUsingBlock:^(Worker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj resume];
    }];
}

- (NSInteger) numberOfWorkers
{
    return self.workers.count;
}

- (NSInteger)remainingCount:(NSInteger)workId
{
    return self.workers[workId].remainingCount;
}

- (NSArray<Task*>*)finishedTasks:(NSInteger)workId
{
    return self.workers[workId].finishedTasks;
}

- (NSTimeInterval)speedTime:(NSInteger)workId
{
    return self.workers[workId].speedTime;
}

- (BOOL)running:(NSInteger)workId
{
    return self.workers[workId].running;
}

@end
