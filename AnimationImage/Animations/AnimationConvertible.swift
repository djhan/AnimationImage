//
//  AnimationConvertible.swift
//  AnimationImage
//
//  Created by DJ.HAN on 05/06/2019.
//  Copyright © 2019 DJ.HAN. All rights reserved.
//

import Foundation
import Cocoa
import CommonLibrary
import AnimationImagePrivate


// MARK: - Typealiases -

/// EXIF Properties 배열
public typealias AnimationExifData = Array<AnimationExifProperties>
/// EXIF Properties 타입
public typealias AnimationExifProperties = Dictionary<String, Any>


// MARK: - Animation Convertible Protocol -
/**
 Animation Convertible 프로토콜

 - 2020/12 기준으로 Big Sur의 Webp 지원을 사용하려고 시도
 - 현재 버그가 너무 많아서 다시 libWebp로 회귀
 - MacOS 11.3 Update 이후 class -> AnyObject로 변경
 */
public protocol AnimationConvertible: AnyObject, Collection {
    /// 소스 연관 타입 설정
    associatedtype SourceType
    /// 이미지 소스
    var imageSource: SourceType? { get }

    /// 싱크용 큐
    var syncQueue: DispatchQueue { get }
    
    /// ExifData
    var exifData: AnimationExifData? { get set }

    /** DefaultAnimationImage 클래스에서 선언 */
    /// type
    var type: AnimationImageType { get }
    //var type: AnimationImage.type { get }
    /// 크기
    var size: NSSize { get set }
    /// 애니메이션 여부
    var isAnimation: Bool { get }
    /// 루프 횟수
    var loopCount: UInt { get set }
    /// 특정 인덱스의 delay(duration)
    func delayTime(at index: Index)-> Float
}

// MARK: - Animation Convertible Extension
extension AnimationConvertible {
    /**
     imageSource를 cgImageSource로 캐스팅해서 반환 (가능한 경우)
     
     - Note: Core Foundation 변수가 opaque 타입이기 때문에 as 를 이용한 CF 타입 -> swift 타입 다운캐스팅에 문제가 있음. 따라서 이 같은 처리가 필요
     */
    private var castedCGImageSource: CGImageSource? {
        if self.imageSource != nil {
            guard CFGetTypeID(self.imageSource as CFTypeRef) == CGImageSourceGetTypeID() else { return nil }
            return (self.imageSource as! CGImageSource)
        }
        return nil
    }
    
    /// GIF/PNG/Webp의 특정 인덱스의 메타데이터 딕셔너리에서 값을 구한다
    public func dictionaryValue(at index: Int, key: NSString) -> Any?  {
        // webp 또는 unknown 포맷은 처리 불가, NIL 반환
        if self.type == .webp || self.type == .unknown { return nil }
        
        // unknown 포맷은 처리 불가, NIL 반환
        if self.type == .unknown { return nil }
        // imageSource가 제대로 설정되지 않은 경우 중지
        guard let imageSource = self.castedCGImageSource else { return nil }
        //guard let imageSource = self.imageSource else { return nil }
        // Metadata Dictionaries Key를 설정
        let metadadaKey = self.type == .gif ? kCGImagePropertyGIFDictionary as NSString : kCGImagePropertyPNGDictionary as NSString
        // Metadata Dictionaries 를 설정
        // 해당 인덱스의 imageProperties를 가져온다
        // 인덱스가 NSNotfound인 경우, 특정 인덱스가 아닌 파일에서 가져온다
        let imageProperties = index != NSNotFound ? CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) :CGImageSourceCopyProperties(imageSource, nil)
        if imageProperties == nil { return nil }
        // 기본 Dictionary를 가져온다
        guard let rawDicts = CFDictionaryGetValue(imageProperties, Unmanaged.passUnretained(metadadaKey).toOpaque()) else { return nil }
        let metadataDicts = Unmanaged<CFDictionary>.fromOpaque(rawDicts).takeUnretainedValue() as NSDictionary
        // 키값의 결과 반환
        return metadataDicts[key]
    }
    
    /// 애니메이션 여부
    public var isAnimation: Bool {
        // 프레임 갯수가 1개 이상일 때, True 반환
        if self.frameCount > 1 { return true }
        return false
    }
    /// 프레임 갯수
    /// - syncQueue로 동기화된 값 반환
    public var frameCount: Int {
        return self.syncQueue.sync { [weak self] () -> Int in
            guard let strongSelf = self else { return 0 }
            return strongSelf._frameCount
        }
    }
    /// 프레임 갯수 반환 내부 private 메쏘드
    /// - syncQueue 동기화를 위해서 내부에서만 사용한다
    private var _frameCount: Int {
        // webp 인 경우
        if self.type == .webp {
            // imageSource가 없을 떄는 0 반환
            guard let webpImage = self.imageSource as? WebpImage else {
                return 0
            }
            return Int(webpImage.frameCount)
            
        }
            // GIF/PNG 인 경우
        else if self.type == .gif || self.type == .png {
            // imageSource가 없을 떄는 0 반환
            guard let imageSource = self.castedCGImageSource else {
                return 0
            }
            return CGImageSourceGetCount(imageSource)
        }
        // 그 외의 경우
        return 0
    }

    /// 특정 인덱스의 ExifProperties
    private func exifProperties(at index: Int) -> AnimationExifProperties? {
        return self.exifData?[index]
    }
    /// 특정 인덱스의 메타데이터의 Orientation 방향
    private func orientationByMetadata(at index: Int) -> CGImagePropertyOrientation {
        guard let exifProperties = self.exifProperties(at: index),
              let orientationValue = exifProperties[kCGImagePropertyOrientation as String],
              let orientation = orientationValue as? UInt32 else { return CGImagePropertyOrientation.up }
        // orientation값 기반으로 CGImagePropertyOrientation 키값을 반환
        // 강제 옵셔널 벗기기로 반환한다 (항상 값이 있을 것으로 간주)
        return CGImagePropertyOrientation(rawValue: orientation)!
    }

    // MARK: Collection Protocol Related
    /** collection 프로토콜용 메쏘드 및 프로퍼티 **/
    public func index(after i: Int) -> Int {
        return i+1
    }
    public var startIndex: Int {
        return 0
    }
    public var endIndex: Int {
        // 배열인 경우, ..< endIndex 로 비교. endIndex 자체는 포함되지 않기 때문에, frameCount를 반환하면 된다!
        // syncQueue로 동기화된 `frameCount` 반환
        return self.frameCount
    }
    /// 특정 인덱스의 이미지를 반환 : Collection 프로토콜 사용
    public subscript(index: Int)-> NSImage? {
        // 동시성 확보를 위해, 싱크 처리
        self.syncQueue.sync { [weak self] () -> NSImage? in

            // self가 NIL인 경우, NIL 반환
            guard let strongSelf = self else { return nil }
            // 동기화되지 않은 _frameCount 사용해서 범위 확인
            guard 0 ..< strongSelf._frameCount ~= index else {
                print("AnimationConvertible>subscript: \(index)가 프레임 범위 \(strongSelf.frameCount)를 초과!")
                return nil
            }
            
            var cgImage: CGImage?
            // webp 인 경우
            if strongSelf.type == .webp {
                guard let webpImage = strongSelf.imageSource as? WebpImage else { return nil }
                // Objective C로부터의 반환값이라서 Unmanaged로 넘어온다
                // new로 생성된 것이 아니기 때문에, unretained로 처리
                cgImage = webpImage.cgImage(from: index)?.takeUnretainedValue()
            }
            // GIF/PNG 인 경우
            else if strongSelf.type == .gif || strongSelf.type == .png {
                guard let imageSource = strongSelf.castedCGImageSource else { return nil }
                cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, nil)
            }
            
            // cgImage를 정상적으로 받았는지 확인
            guard cgImage != nil else { return nil }
            
            // 정상적으로 받아온 경우, NSImage로 반환
            
            // PNG / webP 파일은 현재 Orientation에 맞춰서 변환, 반환
            if strongSelf.type == .png || strongSelf.type == .webp {
                return strongSelf.transfromBy(strongSelf.orientationByMetadata(at: index), cgImage: cgImage!)
            }
            // 그 외의 경우는 그대로 반환
            else {
                let size = NSMakeSize(CGFloat(cgImage!.width), CGFloat(cgImage!.height))
                return NSImage.init(cgImage: cgImage!, size: size)
            }
        }
    }
    
    /**
     EXIF Property 기준으로 orientation 전환된 NSImage 반환

     - Important: 재활용된 코드
     - EdgeView 3 의`CGImageExtenstion`의 코드를 그대로 복사해 가져옴.
     - CommonLibrary에 넣고 싶으나, CommonLibrary가 먼저 AnimationImage를 참고하기 때문에, 어쩔 수 없이 여기에 복사해서 사용한다

     - Parameters:
        - orientation: 회전/반전 여부. CGImagePropertyOrientation 값
        - cgImage: `CGImage`
     - Returns: NSImage. 실패시 NIL 반환
     */
    private func transfromBy(_ orientation: CGImagePropertyOrientation, cgImage: CGImage) -> NSImage? {
        
        //----------------------------------------------------------------------------//
        /// CGImage를 NSImage로 반환하는 내부 메쏘드
        func convertedImage(_ cgImage: CGImage) -> NSImage? {
            let size = NSMakeSize(CGFloat(cgImage.width), CGFloat(cgImage.height))
            return NSImage.init(cgImage: cgImage, size: size)
        }
        //----------------------------------------------------------------------------//

        guard orientation != .up else {
            // 별도 변환 없이 반환
            return convertedImage(cgImage)
        }
        
        // up 이외의 방향인 경우
        guard let transformedCGImage = cgImage.transfrom(orientation: orientation) else { return nil }
        return convertedImage(transformedCGImage)
    }
}

// MARK: - Default Animation Image Class for Identification -
public class DefaultAnimationImage {
    // Dummy Class로 선언됨
    
    /// type
    var type: AnimationImageType = .unknown
    //var type: AnimationImage.type = .unknown
    /// 크기: NSZeroSize로 초기화
    public var size: NSSize = NSZeroSize
    /// 반복 횟수 = 0으로 초기화
    public var loopCount: UInt = 0
}
