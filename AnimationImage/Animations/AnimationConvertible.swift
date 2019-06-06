//
//  AnimationConvertible.swift
//  AnimationImage
//
//  Created by DJ.HAN on 05/06/2019.
//  Copyright © 2019 DJ.HAN. All rights reserved.
//

import Foundation
import Cocoa
import AnimationImagePrivate

// MARK: Animation Convertible Protocol
public protocol AnimationConvertible: Collection {
    // 소스 연관 타입 설정
    associatedtype SourceType
    // 이미지 소스
    var imageSource: SourceType? { get }
    
    // DefaultAnimationImage 클래스에서 선언
    // type
    var type: AnimationImage.type { get }
    // 크기
    var size: NSSize { get set }
    // 애니메이션 여부
    var isAnimation: Bool { get }
    // 루프 횟수
    var loopCount: UInt { get set }
}

// MARK: Animation Convertible Extension
extension AnimationConvertible {
    // imageSource를 cgImageSource로 캐스팅해서 반환 (가능한 경우)
    // Core Foundation 변수가 opaque 타입이기 때문에 as 를 이용한 CF 타입 -> swift 타입 다운캐스팅에 문제가 있음. 따라서 이 같은 처리가 필요
    private var castedCGImageSource: CGImageSource? {
        if self.imageSource != nil {
            guard CFGetTypeID(self.imageSource as CFTypeRef) == CGImageSourceGetTypeID() else { return nil }
            return (self.imageSource as! CGImageSource)
        }
        return nil
    }
    
    // GIF/PNG의 특정 인덱스의 메타데이터 딕셔너리에서 값을 구한다
    public func getDictionaryValue(at index: Int, key: NSString) -> Any?  {
        // webp 또는 unknown 포맷은 처리 불가, NIL 반환
        if self.type == .webp || self.type == .unknown { return nil }
        // imageSource가 제대로 설정되지 않은 경우 중지
        guard let imageSource = self.castedCGImageSource else { return nil }
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
    
    // 애니메이션 여부
    public var isAnimation: Bool {
        get {
            // 프레임 갯수가 1개 이상일 때, True 반환
            if self.frameCount > 1 { return true }
            return false
        }
    }
    // 프레임 갯수
    public var frameCount: Int {
        get {
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
    }

    // MARK: Collection Protocol Related
    // collection 프로토콜용 메쏘드 및 프로퍼티
    public func index(after i: Int) -> Int {
        return i+1
    }
    public var startIndex: Int {
        get { return 0 }
    }
    public var endIndex: Int {
        get {
            let _endIndex = self.frameCount - 1
            return _endIndex >= 0 ? _endIndex : 0
        }
    }
    // 특정 인덱스의 이미지를 반환 : Collection 프로토콜 사용
    public subscript(index: Int)-> NSImage? {
        // 동시성 확보를 위해, 싱크 처리 : Synchronized 익스텐션에 사용되는 것과 동일
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if index < self.frameCount {
            var cgImage: CGImage?
            // webp 인 경우
            if self.type == .webp {
                guard let webpImage = self.imageSource as? WebpImage else { return nil }
                // Objective C로부터의 반환값이라서 Unmanaged로 넘어온다
                // new로 생성된 것이 아니기 때문에, unretained로 처리
                cgImage = webpImage.cgImage(from: index)?.takeUnretainedValue()
            }
                // GIF/PNG 인 경우
            else if self.type == .gif || self.type == .png {
                guard let imageSource = self.castedCGImageSource else { return nil }
                cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, nil)
            }
            // cgImage를 정상적으로 받은 경우
            if cgImage != nil {
                let size = NSMakeSize(CGFloat(cgImage!.width), CGFloat(cgImage!.height))
                return NSImage.init(cgImage: cgImage!, size: size)
            }
        }
        // 이외의 경우, NIL 반환
        return nil
    }
}

// MARK: - Default Animation Image Class for Identification
public class DefaultAnimationImage: NSObject {
    // Dummy Class
    override init() {
        super.init()
    }
    // type
    var type: AnimationImage.type = .unknown
    // 크기: NSZeroSize로 초기화
    public var size: NSSize = NSZeroSize
    // 반복 횟수 = 0으로 초기화
    public var loopCount: UInt = 0
}
