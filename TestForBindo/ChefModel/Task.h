//
//  Task.h
//  bindo
//
//  Created by splendourbell on 2019/12/31.
//  Copyright © 2019 bindo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Task : NSObject

@property (nonatomic, assign) NSInteger job;

- (void)start:(NSTimeInterval)speedTime completion:(void(^)(BOOL finished))completion;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
