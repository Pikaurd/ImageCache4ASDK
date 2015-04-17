//
//  Extension.swift
//  ASDKLesson
//
//  Created by Pikaurd on 4/15/15.
//  Copyright (c) 2015 Shanghai Zuijiao Infomation Technology Inc. All rights reserved.
//

import Foundation

func debugLog<T>(x: T, filename: String = __FILE__, line: Int = __LINE__, fn: String = __FUNCTION__) {
    #if DEBUG
    println("\(filename.lastPathComponent)(\(line)) \(fn) -> \t\(x)")
    #endif
}
