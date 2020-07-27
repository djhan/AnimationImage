//
//  PngImage.swift
//  AnimationImage
//
//  Created by DJ.HAN on 04/06/2019.
//  Copyright © 2019 DJ.HAN. All rights reserved.
//

import Cocoa
import AnimationImagePrivate

//================================================================================//
//
// PNG Image Class
// AnimationConvertible 프로토콜 상속 (자동으로 collection 프로토콜도 상속)
//
//================================================================================//
class PngImage: DefaultAnimationImage, AnimationConvertible {
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
            guard let loopCount = self.dictionaryValue(at: NSNotFound, key: kCGImagePropertyAPNGLoopCount as NSString) as? NSNumber else { return }
            self.loopCount = UInt(truncating: loopCount)
        }
    }
    // 사용하지 않음
    internal var webpImage: WebpImage?

    // 동기화 큐
    lazy var syncQueue = DispatchQueue(label: "djhan.EdgeView.PngImage", attributes: .concurrent)

    // MARK: Initialization
    // 초기화
    init(from imageSource: CGImageSource) {
        super.init()
        // 이미지 소스 대입
        self.imageSource = imageSource
        // 소스 설정시 PNG 로 설정
        self.type = .png
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
    // 특정 인덱스의 Delay를 반환
    func delayTime(at index: Int) -> Float {
        // delayTime을 NSNumber로 가져온다. 실패시 0.1초 반환
        guard let delayTime = (self.dictionaryValue(at: index, key: kCGImagePropertyAPNGDelayTime) as? NSNumber)?.floatValue else { return 0.1 }
        // unclamped Delay Time이 있는지 확인
        if let unclampeedDelayTime = (self.dictionaryValue(at: index, key: kCGImagePropertyAPNGUnclampedDelayTime) as? NSNumber)?.floatValue {
            if unclampeedDelayTime < delayTime {
                return unclampeedDelayTime
            }
        }
        return delayTime
    }
}
