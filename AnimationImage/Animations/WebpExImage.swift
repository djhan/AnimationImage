//
//  WebpExImage.swift
//  AnimationImage
//
//  Created by DJ.HAN on 05/06/2019.
//  Copyright © 2019 DJ.HAN. All rights reserved.
//

import Cocoa
import AnimationImagePrivate

//================================================================================//
//
// Webp Extended Image Class - Objective C 코드의 Wrapper로 작동
// AnimationConvertible 프로토콜 상속 (자동으로 collection 프로토콜도 상속)
//
//================================================================================//
class WebpExImage: NSObject, AnimationConvertible {
    // 소스 타입 연관값
    typealias SourceType = WebpImage
    
    // 종류
    public var type: AnimationImage.type = .unknown
    // webp 이미지 소스
    internal var imageSource: SourceType? {
        didSet {
            // 첫 번째 이미지를 가져온다
            if let firstImage = self[0] {
                // 크기 설정
                self.size = firstImage.size
            }
            // loopCount 값을 받아온다
            // 값을 받아오지 못한 경우는 실패 처리
            guard let webpImage = self.imageSource else { return }
            self.loopCount = webpImage.loopCount
        }
    }
    // 사용하지 않음
    internal var source: CGImageSource?
    // 
    public var size: NSSize = NSZeroSize
    // 반복 횟수
    public var loopCount: UInt = 0
    
    // MARK: Initialization
    // URL로 초기화
    init(from url:URL) {
        super.init()
        
        self.imageSource = WebpImage.init(url: url)
        // 소스 설정시 webp 로 설정
        if self.imageSource != nil { self.type = .webp }
    }
    
    // Data로 초기화
    init(from data:Data) {
        super.init()
        
        self.imageSource = WebpImage.init(data: data)
        // 소스 설정시 webp 로 설정
        if self.imageSource != nil { self.type = .webp }
    }
    
    // MARK: Method

}
