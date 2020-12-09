//
//  WebpImage.swift
//  AnimationImage
//
//  Created by DJ.HAN on 2020/11/23.
//  Copyright © 2020 DJ.HAN. All rights reserved.
//

/*
import Foundation

// MARK: - WebpImageClass -
/**
 Webp Image Class
 - AnimationConvertible 프로토콜 상속 (자동으로 collection 프로토콜도 상속)
 - Important:
    - 현재 loopCount / frame delay time은 GIF 키값을 가져오고 있는데, 추후 CGImageSource 문서의 갱신사항을 검토할 필요 있음
 */
class WebpImage: DefaultAnimationImage, AnimationConvertible {
    
    // MARK: Properties
    /**
     이미지 소스
     */
    internal var imageSource: CGImageSource? {
        get { self._imageSource }
        set {
            self._imageSource = newValue
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
    /// 실제 이미지 소스
    private var _imageSource: CGImageSource?

    // MARK: Initialization
    /// 초기화
    init(from imageSource: CGImageSource) {
        super.init()
        // 이미지 소스 대입
        self.imageSource = imageSource
        // 소스 설정시 webp 로 설정
        self.type = .webp
    }
    /// URL로 초기화
    convenience init?(from url:URL) {
        // 이미지 소스 생성 실패시 nil 반환
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        // 정상적으로 초기화
        self.init(from: imageSource)
    }
    /// Data로 초기화
    convenience init?(from data:Data) {
        // 이미지 소스 생성 실패시 nil 반환
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        // 정상적으로 초기화
        self.init(from: imageSource)
    }

    // MARK: Method
    /// 특정 인덱스의 Delay를 반환
    func delayTime(at index: Int) -> Float {
        // delayTime을 NSNumber로 가져온다. 실패시 0.1초 반환
        guard let delayTime = (self.dictionaryValue(at: index, key: kCGImagePropertyGIFDelayTime) as? NSNumber)?.floatValue else { return 0.1 }
        // unclamped Delay Time이 있는지 확인
        if let unclampeedDelayTime = (self.dictionaryValue(at: index, key: kCGImagePropertyGIFUnclampedDelayTime) as? NSNumber)?.floatValue {
            if unclampeedDelayTime < delayTime {
                return unclampeedDelayTime
            }
        }
        return delayTime
    }
}
*/

