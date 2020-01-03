//
//  WorkerManger.h
//  bindo
//
//  Created by splendourbell on 2019/12/31.
//  Copyright © 2019 bindo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class Task;
@class Worker;

@protocol WorkerMangerDelegate<NSObject>

@optional

- (void)completion:(Worker*)worker task:(Task*)task;

- (void)runningStateChanged:(Worker*)worker running:(BOOL)running;

@end

@interface WorkerManger : NSObject

@property (nonatomic, weak) id<WorkerMangerDelegate> delegate;

@property (nonatomic, readonly) NSInteger numberOfWorkers;

- (instancetype)initWithWorker:(NSInteger)numberOfWorkers;

- (void)addTask:(NSInteger)count;

- (void)start;

- (void)pause:(NSInteger)workId;

- (void)resume:(NSInteger)workId;

- (void)pauseAll;

- (void)resumeAll;

- (NSInteger)remainingCount:(NSInteger)workId;

- (NSArray<Task*>*)finishedTasks:(NSInteger)workId;

- (NSTimeInterval)speedTime:(NSInteger)workId;

- (BOOL)running:(NSInteger)workId;

@end

NS_ASSUME_NONNULL_END
