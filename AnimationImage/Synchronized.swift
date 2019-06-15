//
//  Synchronized.swift
//  EdgeView 3
//
//  Created by DJ.HAN on 24/05/2019.
//  Copyright © 2019 DJ.HAN. All rights reserved.
//

import Cocoa

// Objective-C의 Synchronized와 동일한 효과
// 프로토콜에도 사용되기 때문에 lock object 로 AnyObject 대신 Any를 사용한다
public func synchronized<T>(_ lock: Any, _ closure: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return try closure()
}
