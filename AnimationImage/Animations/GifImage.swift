//
//  GifImage.swift
//  AnimationImage
//
//  Created by DJ.HAN on 04/06/2019.
//  Copyright © 2019 DJ.HAN. All rights reserved.
//

import Cocoa
import CommonLibrary
import AnimationImagePrivate

// MARK: - GIF Image Class -
/**
 GIF Image Class
 - AnimationConvertible 프로토콜 상속 (자동으로 collection 프로토콜도 상속)
 */
class GifImage: DefaultAnimationImage, AnimationConvertible {

    // MARK: Properties    
    /// 소스의 연관값
    typealias SourceType = CGImageSource

    /**
     이미지 소스
     */
    internal var imageSource: SourceType? {
        get { return self._imageSource }
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

    /// ExifData
    var exifData: AnimationExifData?

    /// webpImage 프로퍼티: 사용하지 않음
    internal var webpImage: WebpImage?
    /**
    동기화 큐

     # 중요사항
     - lazy 변수는 [원자적으로 초기화되지 않기 때문] (https://sungwon-choi-29.github.io/trend/2019-08-14-trend/)에 lazy 초기화는 취소한다
     - let으로 선언된 내부 프로퍼티 `_syncQueue`를 반환해서 사용하도록 변경한다
     */
    internal var syncQueue: DispatchQueue { return self._syncQueue }
    private let _syncQueue = DispatchQueue(label: "djhan.EdgeView.GifImage", attributes: .concurrent)

    // MARK: Initialization
    /// 초기화
    init(from imageSource: CGImageSource) {
        super.init()
        // 이미지 소스 대입
        self.imageSource = imageSource
        // 소스 설정시 GIF 로 설정
        self.type = .gif
        // exifData 설정
        self.exifData = imageSource.exifData
    }
    /// URL로 초기화
    convenience init?(from url: URL) {
        // 이미지 소스 생성 실패시 nil 반환
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        // 정상적으로 초기화
        self.init(from: imageSource)
    }
    /// Data로 초기화
    convenience init?(from data: Data) {
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
