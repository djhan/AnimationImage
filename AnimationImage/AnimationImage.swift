//
//  AnimationImage.swift
//  AnimationImage
//
//  Created by DJ.HAN on 02/06/2019.
//  Copyright © 2019 DJ.HAN. All rights reserved.
//

import Cocoa

public class AnimationImage: NSObject, Collection {
    // MARK: Collection Protocol Related
    // collection 프로토콜용 메쏘드 및 프로퍼티
    public func index(after i: Int) -> Int {
        return i + 1
    }
    public var startIndex: Int {
        get { return 0 }
    }
    public var endIndex: Int {
        get { return self.numberOfItems - 1 }
    }
    // collection 프로토콜용 메쏘드 및 프로퍼티 종료

    // 기본 캐쉬
    lazy var originalCache = NSCache<NSNumber, NSImage>()
    // 변형 전용 캐쉬
    lazy var additionalCache = NSCache<NSNumber, NSImage>()
    
    // 현재 인덱스
    public var currentIndex = 0
    // 총 이미지 개수
    public var numberOfItems = 0
    
    // 실제로는 1장뿐인 정지 이미지 여부
    // 이 경우, 효과, 회전 적용시 ImageCache의 AdditionalImage를 사용한다
    public var isStillImage: Bool {
        get {
            if self.numberOfItems > 1 { return true }
            else { return false }
        }
    }
    
    // 현재 이미지 - 현재 인덱스의 이미지 반환
    var currentImage: NSImage? {
        get {
            return self[self.currentIndex]
        }
    }
    
    override init() {
        super.init()
    }
    
    // MARK: - Method
    // 특정 인덱스의 이미지를 반환 : Collection 프로토콜 사용시에도 중요
    public subscript(index: Int)-> NSImage? {

        return nil
    }
}
