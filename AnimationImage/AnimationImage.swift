//
//  AnimationImage.swift
//  AnimationImage
//
//  Created by DJ.HAN on 02/06/2019.
//  Copyright © 2019 DJ.HAN. All rights reserved.
//

import Cocoa
import CommonLibrary
import AnimationImagePrivate

// MARK: - AnimationImage Class -

/**
 Animation Image Class
 - 애니메이션 이미지 클래스
 */
public class AnimationImage {
    
    // MARK: - AnimationImage Enumerations
    
    // CommonLibrary로 이동
    /*
    /// 애니메이션 이미지 종류
    public enum type {
        /// GIF
        case gif
        /// PNG
        case png
        /// WEBP
        case webp
        /// Unknown
        case unknown
    }
     */
    /// 각 프레임 별 지연 시간(duration) 저장 딕셔너리
    private lazy var delays = [Int: Float]()

    /// 현재 인덱스
    public var currentIndex = 0
    
    /// 총 이미지 개수
    public var numberOfItems: Int {
        var count: Int?
        switch self.type {
        case .gif:
            count = self.gifImage?.count
        case .png:
            count = self.pngImage?.count
        case .webp:
            count = self.webpImage?.count
        default:
            return 0
        }
        // count가 nil이 아닌 경우, 강제 옵셔널 벗기기로 반환
        if count != nil { return count! }
        // 실패시 0 반환
        return 0
    }
    /// 재생 반복 횟수
    public var loopCount: UInt {
        var loopCount: UInt?
        switch self.type {
        case .gif:
            loopCount = self.gifImage?.loopCount
        case .png:
            loopCount = self.pngImage?.loopCount
        case .webp:
            loopCount = self.webpImage?.loopCount
        default:
            return 0
        }
        // loopCount가 nil이 아닌 경우, 강제 옵셔널 벗기기로 반환
        if loopCount != nil { return loopCount! }
        // 실패시 0 반환
        return 0
    }

    /// 이미지 소스
    private var image: DefaultAnimationImage?
    /// 이미지 종류
    //private var type: AnimationImage.type = .unknown
    private var type: AnimationImageType = .unknown
    /// GIF 이미지 소스
    private var gifImage: GifImage? {
        return image as? GifImage
    }
    /// PNG 이미지 소스
    private var pngImage: PngImage? {
        return image as? PngImage
    }
    /// webp 이미지 소스
    private var webpImage: WebpExImage? {
        return image as? WebpExImage
    }
    
    /// 애니메이션 이미지 여부
    public var isAnimation: Bool {
        // 이미지 개수가 1개 이상인 경우 true 반환
        if self.numberOfItems > 1 { return true }
            // 아닌 경우, false 반환
        else { return false }
    }
    /// 현재 이미지
    /// - 현재 인덱스의 이미지 반환
    /// - 원본 / 특수효과 이미지 여부는 자동 판별해서 반환
    public var currentImage: NSImage? {
        return self[self.currentIndex]
    }

    /// Exif Data
    /// - PNG/Webp의 EXIF Data
    public var exifData: AnimationExifData? {
        get {
            switch self.type {
            case .gif: return self.gifImage?.exifData
            case .png: return self.pngImage?.exifData
            case .webp: return self.webpImage?.exifData
            default: return nil
            }
        }
        set {
            switch self.type {
            case .gif: self.gifImage?.exifData = newValue
            case .png: self.pngImage?.exifData = newValue
            case .webp: self.webpImage?.exifData = newValue
            default: return
            }
        }
    }
    
    //===================================================//
    // 실제 이미지
    //===================================================//

    // MARK: - Initialization
    init(type: AnimationImageType) {
        //init(type: AnimationImage.type) {
        // 종류 대입
        self.type = type
    }
    /**
     초기화
     - parameters:
        - url: 애니메이션 파일 URL
        - type: 애니메이션 이미지 종류
     */
    public convenience init?(from url: URL, type: AnimationImageType) {
    //public convenience init?(from url: URL, type: AnimationImage.type) {
        // 종류별로 image를 초기화
        switch type {
        case .gif:
            guard let image = GifImage.init(from: url) else { return nil }
            // 초기화 실행
            self.init(type: type)
            self.image = image
        case .png:
            guard let image = PngImage.init(from: url) else { return nil }
            // 초기화 실행
            self.init(type: type)
            self.image = image
        case .webp:
            guard let image = WebpExImage.init(from: url) else { return nil }
            // 초기화 실행
            self.init(type: type)
            self.image = image
        case .unknown:
            // 초기화 중지
            return nil
        }
    }
    /**
     초기화
     - parameters:
        - data: 애니메이션 Data
        - type: 애니메이션 이미지 종류
     */
    public convenience init?(from data: Data, type: AnimationImageType) {
        // 종류별로 image를 초기화
        switch type {
        case .gif:
            guard let image = GifImage.init(from: data) else { return nil }
            // 초기화 실행
            self.init(type: type)
            self.image = image
        case .png:
            guard let image = PngImage.init(from: data) else { return nil }
            // 초기화 실행
            self.init(type: type)
            self.image = image
        case .webp:
            //guard let image = WebpExImage.init(from: data) else { return nil }
            let image = WebpExImage.init(from: data)
            // 초기화 실행
            self.init(type: type)
            self.image = image
        case .unknown:
            // 초기화 중지
            return nil
        }
    }

    // MARK: - Method
    /// 특정 인덱스의 이미지를 반환
    private func image(at index: Int) -> NSImage? {
        return self.makeImage(from: index)
    }

    /// 오리지날 이미지 생성후 캐쉬에 저장
    private func makeImage(from index: Int) -> NSImage? {
        // 반환용 이미지
        var image: NSImage?
        switch self.type {
        case .gif:
            guard let gifImage = self.gifImage else { return nil }
            image = gifImage[index]
        case .png:
            guard let pngImage = self.pngImage else { return nil }
            image = pngImage[index]
        case .webp:
            guard let webpImage = self.webpImage else { return nil }
            image = webpImage[index]
        case .unknown:
            return nil
        }
        // 이미지 반환
        return image
    }

    /// 특정 index의 delay 반환
    /// - delay가 delay 딕셔너리에 없을 땐 가져온 뒤 딕셔너리에 반환
    public func delay(at index: Int)-> Float {
        if let delay = self.delays[index] {
            return delay
        }
        else {
            let delay = self.getDelay(at: index)
            // delays에 해당 인덱스의 delay 추가
            self.delays[index] = delay
            return delay
        }
    }
    
    /// 특정 index의 delay를 가져온다
    private func getDelay(at index: Int)-> Float {
        var delay: Float?
        switch self.type {
        case .gif:
            delay = self.gifImage?.delayTime(at: index)
        case .png:
            delay = self.pngImage?.delayTime(at: index)
        case .webp:
            delay = self.webpImage?.delayTime(at: index)
        default:
            return 0.1
        }
        // delay가 nil이 아닌 경우 강제 옵셔널 벗기기로 반환
        if delay != nil { return delay! }
        // 이외는 0.1을 반환
        return 0.1
    }    
}


// MARK: - AnimationImage Extension for Collection
/// Collection 프로토콜에 대응하기 위한 확장
extension AnimationImage: Collection {
    // MARK: Collection Protocol Related
    // collection 프로토콜용 메쏘드 및 프로퍼티
    public func index(after i: Int) -> Int {
        return i + 1
    }
    public var startIndex: Int {
        return 0
    }
    public var endIndex: Int {
        // 배열인 경우, ..< endIndex 로 비교. endIndex 자체는 포함되지 않기 때문에, numberOfItems를 반환하면 된다!
        return self.numberOfItems
    }
    // 특정 인덱스의 이미지를 반환 : Collection 프로토콜 사용시에도 중요
    public subscript(index: Int)-> NSImage? {
        // 각 AnimationImage가 이미 내부적으로 SyncQueue를 사용해 동기화를 하고 있기 때문에, 별도의 동기화는 불필요
        // 해당 index 이미지 반환
        return self.image(at: index)
    }
    // collection 프로토콜용 메쏘드 및 프로퍼티 종료
}
