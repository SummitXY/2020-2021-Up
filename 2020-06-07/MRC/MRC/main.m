//
//  main.m
//  MRC
//
//  Created by quxiangyu on 2020/6/21.
//  Copyright © 2020 quxiangyu. All rights reserved.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    
    id p = [NSObject new];
    @autoreleasepool {
        id p2 = [[p retain] autorelease];
        NSLog(@"in pool:%ld",[p retainCount]);
    }
    NSLog(@"out pool:%ld",[p retainCount]);
    
    return 0;
}
