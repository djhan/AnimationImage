//
//  AvifImage.swift
//  AnimationImage
//
//  Created by DJ.HAN on 2022/09/23.
//  Copyright © 2022 DJ.HAN. All rights reserved.
//


/// 특허 라이센스 문제로 비활성화 2022/10/03

/*
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
    /// MacOS Ventrua의 이미지
    /// - SDImageAVIFCoder 가 읽기 실패시 사용
    private var _image: NSImage?

    /// 싱크 큐
    var syncQueue: DispatchQueue = DispatchQueue(label: "djhan.EdgeView.AvifImage", attributes: .concurrent)
    
    /// EXIF
    var exifData: AnimationExifData?
    
    /// 전체 이미지 개수
    var numberOfItems: Int {
        guard let numberOfItems = self.imageSource?.animatedImageFrameCount else {
            guard self._image != nil else {
                // _image가 없는 경우, 0 반환
                return 0
            }
            // _image가 있는 경우, 1 반환
            return 1
        }
        return Int(numberOfItems)
    }
    
    // MARK: Initialization
    /// 초기화
    /// - Parameters:
    ///   - imageSource: 기본 이미지소스로 `SDImageAVIFCoder` 지정
    ///   - subImage: 기본 이미지소스로 초기화 실패시 `NSImage` 지정. MacOS ventrua 이상에서만 유효하다
    init(from imageSource: SDImageAVIFCoder?, subImage: NSImage? = nil) {
        super.init()
        // 이미지 소스 대입
        self.imageSource = imageSource
        if subImage != nil {
            self._image = subImage
        }
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
            os_log("AvifImage>%@ :: %@ >> Data 생성 실패. 에러 = %@", log: .fileIO, type: .error, #function, url.path, error.localizedDescription)
            return nil
        }
    }
    
    /// Data로 초기화
    convenience init?(from data: Data) {
        // 이미지 소스 생성
        guard let imageSource = SDImageAVIFCoder.init(animatedImageData: data) else {
            os_log("AvifImage>%@ :: AVIF 이미지소스 생성 실패...", log: .fileIO, type: .error, #function)
            // MacOS 13.0 ventura 이상인지 확인
            guard #available(macOS 13.0, *),
               let image = NSImage.init(data: data),
                  image.size.width > 0, image.size.height > 0 else {
                os_log("AvifImage>%@ ::초기화 실패...", log: .fileIO, type: .error, #function)
                return nil
            }
            
            os_log("AvifImage>%@ ::ventura 대응 시도 성공. w/h = %f/%f", log: .fileIO, type: .debug, #function, image.size.width, image.size.height)
            // 초기화
            self.init(from: nil, subImage: image)
            // exif data 추가
            let imageSource = CGImageSourceCreateWithData(data as CFData, nil)
            self.exifData = imageSource?.exifData
            return
        }

        // 정상적으로 초기화
        self.init(from: imageSource)
        
        // MacOS 13.0 ventura 이상인 경우 exifData 생성 시도
        if #available(macOS 13.0, *),
           let imageSource = CGImageSourceCreateWithData(data as CFData, nil) {
            self.exifData = imageSource.exifData
        }
    }
    
    /// 지연 시간
    func delayTime(at index: Int) -> Float {
        return Float(self.imageSource?.animatedImageDuration(at: UInt(index)) ?? 0)
    }
    
    /// 특정 인덱스의 NSImage
    /// - SDImageAVIFCoder 로 초기화된 경우 사용 가능
    func image(at index: Int) -> NSImage? {
        guard index >= 0,
              let imageSource = self.imageSource else {
            return self._image
        }
        // NSImage로 반환
        return imageSource.animatedImageFrame(at: UInt(index))
    }
}
*/
