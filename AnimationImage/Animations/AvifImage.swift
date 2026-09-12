//
//  AvifImage.swift
//  AnimationImage
//
//  Created by DJ.HAN on 2022/09/23.
//  Copyright © 2022 DJ.HAN. All rights reserved.
//


/// 특허 라이센스 문제로 비활성화 2022/10/03
/// ventura 릴리즈로 ventura 이상에서만 작동되게 활성화 2022/10/27
/// CGImageSource 사용으로 완전 교체 2026/05/26

import Foundation
import CommonLibrary
import Cocoa

// MARK: - AVIF Image Class -

class AvifImage: DefaultAnimationImage, AnimationConvertible {
    
    /// 소스 타입 연관값
    typealias SourceType = CGImageSource
    
    /// 이미지 소스
    var imageSource: SourceType? {
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
    /// MacOS Ventrua의 이미지
    /// - SDImageAVIFCoder 가 읽기 실패시 사용
    private var _image: NSImage?
    
    /// 싱크 큐
    var syncQueue: DispatchQueue = DispatchQueue(label: "djhan.EdgeView.AvifImage", attributes: .concurrent)
    
    /// EXIF
    var exifData: AnimationExifData?
    
    /// 전체 이미지 개수
    var numberOfItems: Int {
        guard let imageSource else { return 0 }
        return CGImageSourceGetCount(imageSource)
    }
    
    /// 초기화
    /// - Parameters:
    ///   - imageSource: 기본 이미지소스로 `CGImageSource` 지정
    ///   - subImage: 기본 이미지소스로 초기화 실패시 `NSImage` 지정. MacOS ventrua 이상에서만 유효하다
    init(from imageSource: CGImageSource?) {
        super.init()
        // 이미지 소스 대입
        self.imageSource = imageSource
        // 소스 설정시 avif 로 설정
        self.type = .avif
    }
  /// URL로 초기화
    convenience init?(from url: URL) {
        do {
            let data = try Data.init(contentsOf: url)
            self.init(from: data)
        }
        catch {
            if #available(macOS 11.0, *) {
                EdgeLogger.shared.imageIOLogger.log(level: .error, "\(#function) :: Data 생성 실패. 에러 = \(error.localizedDescription).")
            }
            return nil
        }
    }
    
    /// Data로 초기화
    convenience init?(from data: Data) {
        if #available(macOS 11.0, *) {
            EdgeLogger.shared.imageIOLogger.log(level: .error, "\(#function) :: AVIF 이미지소스 생성 실패.")
        }
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        // 정상적으로 초기화
        self.init(from: imageSource)
        self.exifData = imageSource.exifData
    }
    
    /// 지연 시간
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
