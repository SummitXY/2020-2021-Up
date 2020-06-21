# Runloop

照例先给出Refrence:

1. 周源的runloop的分享视频[视频链接](https://v.youku.com/v_show/id_XODgxODkzODI0.html)

## Runloop运行顺序

> Runloop顺序根据[这篇博客]([https://github.com/Desgard/iOS-Source-Probe/blob/master/Objective-C/Foundation/Run%20Loop%20%E8%AE%B0%E5%BD%95%E4%B8%8E%E6%BA%90%E7%A0%81%E6%B3%A8%E9%87%8A.md](https://github.com/Desgard/iOS-Source-Probe/blob/master/Objective-C/Foundation/Run Loop 记录与源码注释.md))中的内容

以下是启动 run loop 后比较关键的运行步骤：

1. 通知 observers: `kCFRunLoopEntry`, 进入 run loop
2. 通知 observers: `kCFRunLoopBeforeTimers`, __CFRunloopDoObservers
3. 通知 observers: `kCFRunLoopBeforeSources`,__CFRunloopDoObservers
4. 处理 blocks, 可以对 `__CFRUNLOOP_IS_CALLING_OUT_TO_A_BLOCK__` 函数下断点观察到
5. 处理 sources 0, 可以对 `__CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__` 函数下断点观察到
6. 如果第 5 步实际处理了 sources 0，再一次处理 blocks
7. 如果在主线程，检查是否有 GCD 事件需要处理，有的话，跳转到第 11 步（跳过sleep
8. 通知 observers: `kCFRunLoopBeforeWaiting`, 即将进入等待（睡眠）
9. 等待被唤醒，可以被 sources 1、timers、`CFRunLoopWakeUp` 函数和 GCD 事件（如果在主线程）
10. 通知 observers: `kCFRunLoopAfterWaiting`, 即停止等待（被唤醒）
11. 被什么唤醒就处理什么：
    - 被 timers 唤醒，处理 timers，可以在 `__CFRUNLOOP_IS_CALLING_OUT_TO_A_TIMER_CALLBACK_FUNCTION__` 函数下断点观察到
    - 被 GCD 唤醒或者从第 7 步跳转过来的话，处理 GCD，可以在 `__CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__` 函数下断点观察到
    - 被 sources 1 唤醒，处理 sources 1，可以在 `__CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE1_PERFORM_FUNCTION__` 函数下断点观察到
12. 再一次处理 blocks
13. 判断是否退出，不需要退出则跳转回第 2 步
14. 通知 observers: `kCFRunLoopExit`, 退出 run loop

有一点出入的地方是如果在第 5 步实际处理了 sources 0，是不会进入睡眠的

## 回调方法

1. `__CFRUNLOOP_IS_CALLING_OUT_TO_A_BLOCK__`
2. `__CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__`
3. `__CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE1_PERFORM_FUNCTION__`
4. `__CFRUNLOOP_IS_CALLING_OUT_TO_A_TIMER_CALLBACK_FUNCTION__`
5. `__CFRUNLOOP_IS_CALLING_OUT_TO_AN_OBSERVER_CALLBACK_FUNCTION__`
6. `__CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__`

## CFRunloopMode

为什么要存在Mode这一层级，直接Runloop和Item两层不可以吗？

苹果是为了是iOS应用列表滑动更顺畅而区分Mode，当滑动时执行UITrackingMode不执行多余的代码，所以滑动会更顺畅

1. NSDefaultRunloopMode
2. UITrackingRunloopMode
3. UIInitializationRunloopMode:App启动时运行的Mode，当展现第一个UI后就切换到defaultMode
4. NSRunloopCommonModes

## CFRunloopTimer

`timerWithTimeInterval:`

`scheduledTimerWithTimeInterval:`

`performSelector:withObject:afterDelay:`

`displayLinkWithTarget:`

上面四个本质上都是对`CFRunloopTimer的封装`，blcok通过`__CFRUNLOOP_IS_CALLING_OUT_TO_A_TIMER_CALLBACK_FUNCTION__`调用

## CFRunloopSouce

Source本质上是一个protocol（抽象类），任何遵守这个protocol的对象都能成为一个source

souce0:APP应用内事件，APP自己负责管理的，比如UIEvent

souce1:由系统内核管理的事件，通过Mach Port传递消息的事件



## Runloop与GCD

GCD本身的async/after等和Runloop没有关系，但是get_main_queue和Runloop有关

## Runloop作用

1. 节省CPU时间，因为CPU是按照时间片去调度各个任务队列，如果CPU调到一个任务但什么也没干就很浪费CPU资源
2. 实现了消息队列，生产者和消费者给自入队和出队，不用同步进行

# MRC

> 关闭所有ARC操作：
>
> Target -> Build Settings -> Objective-C Automatic Reference Counting 改成NO
>
> 关闭部分文件ARC操作：
>
> Target -> Build Phases -> Compile Sources -> -fno-objc-arc

获取引用计数：

```objc
NSObject *obj = [NSObject new];
NSLog(@"%ld",(long)CFGetRetainCount((__bridge CFTypeRef)obj));

// 或者直接用retainCount
NSLog(@"%ld",(long)[obj retainCount]);
```

MRC例子：

```objc
// 在MRC环境下
NSObject *obj = [NSObject new];
id obj2 = obj;
NSLog(@"%ld",(long)CFGetRetainCount((__bridge CFTypeRef)obj));
// MRC环境下返回的是1

// 但如果在ARC环境下
NSObject *obj = [NSObject new];
id obj2 = obj;
NSLog(@"%ld",(long)CFGetRetainCount((__bridge CFTypeRef)obj));
// ARC环境下返回的是2，因为第二行实际是__strong id obj2 = obj;

// 在MRC环境下需要手动retain才能使引用计数加1
NSObject *obj = [NSObject new];
id obj2 = obj;
[obj2 retain];
NSLog(@"%ld",(long)CFGetRetainCount((__bridge CFTypeRef)obj));//返回2
```

> 不要向已释放的对象传递消息，包括retainCount，此时会产生不可预计结果

