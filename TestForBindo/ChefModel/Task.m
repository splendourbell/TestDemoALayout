//
//  Task.m
//  bindo
//
//  Created by splendourbell on 2019/12/31.
//  Copyright © 2019 bindo. All rights reserved.
//

#import "Task.h"

@implementation Task
{
    void(^_completion)(BOOL finished);
}

- (void)start:(NSTimeInterval)speedTime completion:(void(^)(BOOL finished))completion
{
    _completion = completion;
    [self performSelector:@selector(done) withObject:nil afterDelay:speedTime];
}

- (void)cancel
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(done) object:nil];
    if(_completion)
    {
        _completion(NO);
    }
}

- (void)done
{
    if(_completion)
    {
        _completion(YES);
    }
}

@end
