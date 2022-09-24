//
//  AvifImage.swift
//  AnimationImage
//
//  Created by DJ.HAN on 2022/09/23.
//  Copyright © 2022 DJ.HAN. All rights reserved.
//

import Foundation
import CommonLibrary
import os.log
import AnimationImagePrivate
import SDWebImageAVIFCoder

// MARK: - AVIF Image Class -

class AvifImage: DefaultAnimationImage, AnimationConvertible {
    
    /// 소스 타입 연관값
    typealias SourceType = SDImageAVIFCoder

    /// 이미지 소스
    var imageSource: SourceType? {
        didSet {
            self.loopCount = self.imageSource?.animatedImageLoopCount ?? 0
        }
    }
    
    /// 싱크 큐
    var syncQueue: DispatchQueue = DispatchQueue(label: "djhan.EdgeView.AvifImage", attributes: .concurrent)
    
    /// EXIF
    var exifData: AnimationExifData?
    
    /// 전체 이미지 개수
    var numberOfItems: Int {
        guard let numberOfItems = self.imageSource?.animatedImageFrameCount else { return 0 }
        return Int(numberOfItems)
    }
    
    // MARK: Initialization
    /// 초기화
    init(from imageSource: SDImageAVIFCoder) {
        super.init()
        // 이미지 소스 대입
        self.imageSource = imageSource
        // 소스 설정시 avif 로 설정
        self.type = .avif
    }
    /// URL로 초기화
    convenience init?(from url: URL) {
        // 이미지 소스 생성 실패시 nil 반환
        guard let data = try? Data.init(contentsOf: url),
            let imageSource = SDImageAVIFCoder.init(animatedImageData: data) else {
            os_log("AvifImage>%@ :: %@ >> AVIF 이미지소스 생성 실패...", log: .fileIO, type: .error, #function, url.path)
            return nil
        }
        // 정상적으로 초기화
        self.init(from: imageSource)
    }
    
    /// Data로 초기화
    convenience init?(from data: Data) {
        // 이미지 소스 생성 실패시 nil 반환
        guard let imageSource = SDImageAVIFCoder.init(animatedImageData: data) else {
            os_log("AvifImage>%@ :: AVIF 이미지소스 생성 실패...", log: .fileIO, type: .error, #function)
            return nil
        }
        // 정상적으로 초기화
        self.init(from: imageSource)
    }
    
    /// 지연 시간
    func delayTime(at index: Int) -> Float {
        return Float(self.imageSource?.animatedImageDuration(at: UInt(index)) ?? 0)
    }
    
    /// 특정 인덱스의 이미지
    func image(at index: Int) -> NSImage? {
        guard index >= 0 else { return nil }
        return self.imageSource?.animatedImageFrame(at: UInt(index))
    }
}
