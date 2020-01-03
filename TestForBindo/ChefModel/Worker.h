//
//  Worker.h
//  bindo
//
//  Created by splendourbell on 2019/12/31.
//  Copyright © 2019 bindo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Task;

@interface Worker : NSObject

@property (nonatomic, readonly) NSTimeInterval speedTime;
@property (nonatomic, readonly) NSInteger remainingCount;

@property (atomic, readonly) BOOL running;

@property (nonatomic, readonly, copy) NSArray<Task*>* finishedTasks;
@property (nonatomic, strong) void (^completion)(Worker* worker, Task* task);
@property (nonatomic, strong) void (^runningChanged)(Worker* worker, BOOL running);

/**
 @param workId 编号
 @param speedTime 完成单次任务需要的时间
 */
- (instancetype)initWithId:(NSInteger)workId speedTime:(NSTimeInterval)speedTime;

/**
 @brief 开启线程
 */
- (void)start;

/**
 @param tasks 添加任务到队列
 @brief 派发任务
 */
- (void)addTasks:(NSArray<Task*>*)tasks;

/**
 @brief 暂停任务执行
 */
- (void)pause;

/**
@brief 启动任务执行
*/
- (void)resume;

/**
 @brief 结束线程
*/
- (void)stop;

@end

NS_ASSUME_NONNULL_END
