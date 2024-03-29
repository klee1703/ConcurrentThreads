//
//  ConcurrentProcessor.m
//  ConcurrentThreads
//
//  Created by Keith Lee on 6/1/13.
//  Copyright (c) 2013 Keith Lee. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//   1. Redistributions of source code must retain the above copyright notice, this list of
//      conditions and the following disclaimer.
//
//   2. Redistributions in binary form must reproduce the above copyright notice, this list
//      of conditions and the following disclaimer in the documentation and/or other materials
//      provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY Keith Lee ''AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Keith Lee OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of Keith Lee.

#import "ConcurrentProcessor.h"

@interface ConcurrentProcessor()

@property (readwrite) NSInteger computeResult;

@end

@implementation ConcurrentProcessor
{
  NSString *computeID;        // Unique object for @synchronize lock
  NSUInteger computeTasks;    // Count of number of concurrent compute tasks
  NSLock *computeLock;        // lock object
}

- (id)init
{
  if ((self = [super init]))
  {
    _isFinished = NO;
    _computeResult = 0;
    computeLock = [NSLock new];
    computeID = @"1";
    computeTasks = 0;
  }
  return self;
}

- (void)computeTask:(id)data
{
  NSAssert(([data isKindOfClass:[NSNumber class]]), @"Not an NSNumber instance");
  NSUInteger computations = [data unsignedIntegerValue];
  @autoreleasepool
  {
    @try
    {
      // Obtain lock and increment number of active tasks
      if ([[NSThread currentThread] isCancelled])
      {
        return;
      }
      @synchronized(computeID)
      {
        computeTasks++;
      }

      // Obtain lock and perform computation in critical section
      [computeLock lock];
      if ([[NSThread currentThread] isCancelled])
      {
        [computeLock unlock];
        return;
      }
      NSLog(@"Performing computations");
      for (int ii=0; ii<computations; ii++)
      {
        self.computeResult = self.computeResult + 1;
      }
      [computeLock unlock];
      // Simulate additional processing time (outside of critical section)
      [NSThread sleepForTimeInterval:1.0];
      
      // Decrement number of active tasks, if none left update flag
      @synchronized(computeID)
      {
        computeTasks--;
        if (!computeTasks)
        {
          self.isFinished = YES;
        }
      }
    }
    @catch (NSException *ex) {}
  }
}

@end
