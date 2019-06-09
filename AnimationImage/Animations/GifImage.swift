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
            guard let loopCount = self.dictionaryValue(at: NSNotFound, key: kCGImagePropertyGIFLoopCount as NSString) as? NSNumber else { return }
            self.loopCount = UInt(truncating: loopCount)
        }
    }
    // 사용하지 않음
    internal var webpImage: WebpImage?
    
    // MARK: Initialization
    // 초기화
    init(from imageSource: CGImageSource) {
        super.init()
        // 이미지 소스 대입
        self.imageSource = imageSource
        // 소스 설정시 GIF 로 설정
        self.type = .gif
    }
    // URL로 초기화
    convenience init?(from url:URL) {
        // 이미지 소스 생성 실패시 nil 반환
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        // 정상적으로 초기화
        self.init(from: imageSource)
    }
    
    // Data로 초기화
    convenience init?(from data:Data) {
        // 이미지 소스 생성 실패시 nil 반환
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        // 정상적으로 초기화
        self.init(from: imageSource)
    }

    // MARK: Method
}
