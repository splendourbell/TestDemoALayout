//
//  Worker.m
//  bindo
//
//  Created by splendourbell on 2019/12/31.
//  Copyright © 2019 bindo. All rights reserved.
//

#import "Worker.h"
#import "Task.h"

@interface Worker()
@property (atomic, readwrite) BOOL running;
@end

@implementation Worker
{
    NSInteger _workId;
    NSTimeInterval _speedTime;
    
    NSRunLoop* _runloop;
    NSPort* _threadPort;
    NSThread* _thread;
    
    Task* _runningTask;

    NSMutableArray<Task*>* _tasks;
    NSMutableArray<Task*>* _finishedTasks;
    
    NSLock* _lock;
}

#pragma mark user interface

- (instancetype)initWithId:(NSInteger)workId speedTime:(NSTimeInterval)speedTime
{
    if(self = [super init])
    {
        self.running = YES;
        _workId = workId;
        _speedTime = speedTime;
        _tasks = NSMutableArray.new;
        _finishedTasks = NSMutableArray.new;
        _lock = NSLock.new;
    }
    return self;
}
- (void)start
{
    _thread = [[NSThread alloc] initWithTarget:self selector:@selector(_run) object:nil];
    [_thread start];
}

- (void)addTasks:(NSArray<Task*>*)tasks
{
    [_lock lock];
    [_tasks addObjectsFromArray:tasks];
    [_lock unlock];
}

- (void)pause
{
    if(_thread)
    {
        [self performSelector:@selector(_pause) onThread:_thread withObject:nil waitUntilDone:NO];
    }
}

- (void)resume
{
    if(_thread)
    {
        [self performSelector:@selector(_resume) onThread:_thread withObject:nil waitUntilDone:NO];
    }
}

- (void)stop
{
    [_runloop removePort:_threadPort forMode:NSDefaultRunLoopMode];
}

- (NSInteger)remainingCount
{
    NSInteger ret = 0;
    [_lock lock];
    ret = _tasks.count;
    [_lock unlock];
    return ret;
}

- (NSArray<Task*>*)finishedTasks
{
    NSArray* finishedTasks = nil;
    [_lock lock];
    finishedTasks = _finishedTasks.copy;
    [_lock unlock];
    return finishedTasks;
}

#pragma mark internal functions
- (void)_run
{
    @autoreleasepool
    {
        _runloop = [NSRunLoop currentRunLoop];
        _threadPort = [NSMachPort port];
        [_runloop addPort:_threadPort forMode:NSDefaultRunLoopMode];
        [self _resume];
        [_runloop run];
        [self _pause];
    };
}

- (void)_resumeIfNeed
{
    if(!_runningTask && self.running)
    {
        [_lock lock];
        _runningTask = _tasks.firstObject;
        [_lock unlock];
        __weak typeof(self) weakSelf = self;
        [_runningTask start:_speedTime completion:^(BOOL finished) {
            if(finished)
            {
                [weakSelf _popTask];
            }
        }];
    }
}

- (void)_resume
{
    self.running = YES;
    [self _resumeIfNeed];
    [self runningStateChanged];
}

- (void)runningStateChanged
{
    if(_runningChanged)
    {
        _runningChanged(self, self.running);
    }
}

- (void)_popTask
{
    Task* task = nil;
    [_lock lock];
    if(_tasks.count > 0)
    {
        task = _tasks.firstObject;
        [_finishedTasks addObject:task];
        [_tasks removeObjectAtIndex:0];
    }
    [_lock unlock];
    _runningTask = nil;
    [self performSelector:@selector(_resumeIfNeed) withObject:nil afterDelay:0];
    if(task && _completion)
    {
        _completion(self, task);
    }
}

- (void)_pause
{
    self.running = NO;
    //是否要将正在进行的任务终止掉?
    [_runningTask cancel];
    _runningTask = nil;
    
    [self runningStateChanged];
}

@end
