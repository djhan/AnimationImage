//
//  GifImage.swift
//  AnimationImage
//
//  Created by DJ.HAN on 04/06/2019.
//  Copyright © 2019 DJ.HAN. All rights reserved.
//

import Cocoa
import AnimationImagePrivate

//================================================================================//
//
// GIF Image Class
// AnimationConvertible 프로토콜 상속 (자동으로 collection 프로토콜도 상속)
//
//================================================================================//
// MARK: - GIFImageClass
class GifImage: DefaultAnimationImage, AnimationConvertible {
    // 소스의 연관값
    typealias SourceType = CGImageSource

    // 종류
    // type: DefaultAnimationImage에서 선언됨
    // 이미지 소스
    internal var imageSource: SourceType? {
        // 설정 직후 할 일
        didSet {
            // 첫 번째 이미지를 가져온다
            if let firstImage = self[0] {
                // 크기 설정
                self.size = firstImage.size
            }
            // NSNumber로 loopCount 값을 받아온다
            // 값을 받아오지 못한 경우는 실패 처리
            guard let loopCount = self.getDictionaryValue(at: NSNotFound, key: kCGImagePropertyGIFLoopCount as NSString) as? NSNumber else { return }
            self.loopCount = UInt(truncating: loopCount)
        }
    }
    // 사용하지 않음
    internal var webpImage: WebpImage?
    
    // MARK: Initialization
    // URL로 초기화
    init(from url:URL) {
        super.init()
        
        self.imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)
        // 소스 설정시 GIF 로 설정
        if self.imageSource != nil { self.type = .gif }
    }
    
    // Data로 초기화
    init(from data:Data) {
        super.init()
        
        self.imageSource = CGImageSourceCreateWithData(data as CFData, nil)
        // 소스 설정시 GIF 로 설정
        if self.imageSource != nil { self.type = .gif }
    }

    // MARK: Method
}
