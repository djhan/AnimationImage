//
//  WebpExImage.swift
//  AnimationImage
//
//  Created by DJ.HAN on 05/06/2019.
//  Copyright © 2019 DJ.HAN. All rights reserved.
//

import Cocoa
import CommonLibrary
import WebpFramework

// MARK: - Webp Image Class -
//================================================================================//
//
// Webp Extended Image Class - Objective C 코드의 Wrapper로 작동
// AnimationConvertible 프로토콜 상속 (자동으로 collection 프로토콜도 상속)
//
//================================================================================//
class WebpExImage: DefaultAnimationImage, AnimationConvertible {
    /// 소스 타입 연관값
    typealias SourceType = WebpImage
    
    /**
     webp 이미지 소스
     */
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
    
    /// ExifData
    var exifData: AnimationExifData?

    /**
    동기화 큐

     # 중요사항
     - lazy 변수는 [원자적으로 초기화되지 않기 때문] (https://sungwon-choi-29.github.io/trend/2019-08-14-trend/)에 lazy 초기화는 취소한다
     - let으로 선언된 내부 프로퍼티 `_syncQueue`를 반환해서 사용하도록 변경한다
     */
    internal var syncQueue: DispatchQueue { return self._syncQueue }
    private let _syncQueue = { let syncQueue = DispatchQueue(label: "djhan.EdgeView.WebpExImage_" + UUID().uuidString,
                                                             qos: .default,
                                                             attributes: .concurrent,
                                                             autoreleaseFrequency: .workItem,
                                                             target: nil)
        // 동일 큐 판별을 위해 등록 처리
        DispatchQueue.registerDetection(of: syncQueue)
        return syncQueue
    }()

    // MARK: Initialization
    /// 초기화
    init(from imageSource: WebpImage) {
        super.init()
        // 이미지 소스 대입
        self.imageSource = imageSource
        // 소스 설정시 webp 로 설정
        self.type = .webp
    }
    /// URL로 초기화
    convenience init?(from url: URL) {
        // 이미지 소스 생성 실패시 nil 반환
        guard let imageSource = WebpImage.init(url: url) else { return nil }
        // 정상적으로 초기화
        self.init(from: imageSource)
        
        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) {
            self.exifData = imageSource.exifData
        }
    }
    
    /// Data로 초기화
    convenience init?(from data: Data) {
        // 이미지 소스 생성 실패시 nil 반환
        guard let imageSource = WebpImage.init(data: data) else { return nil }
        // 정상적으로 초기화
        self.init(from: imageSource)
        
        if let imageSource = CGImageSourceCreateWithData(data as CFData, nil) {
            self.exifData = imageSource.exifData
        }
    }
    
    // MARK: Method
    /// 특정 인덱스의 Delay를 반환
    func delayTime(at index: Int) -> Float {
        // delayTime을 NSNumber로 가져온다. 실패시 0.1초 반환
        guard let delayTime = self.imageSource?.duration(at: index) else { return 0.1 }
        return delayTime
    }
}
