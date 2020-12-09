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
/**
 Animation Convertible 프로토콜

 - 2020/12 기준으로 Big Sur의 Webp 지원을 사용하려고 시도
 - 현재 버그가 너무 많아서 다시 libWebp로 회귀
 */
public protocol AnimationConvertible: class, Collection {
    /// 소스 연관 타입 설정
    associatedtype SourceType
    /// 이미지 소스
    var imageSource: SourceType? { get }
    
    /// 이미지 소스
    /// - CGImageSource로 통일됨. webp 독자 소스 사용하지 않음
    // var imageSource: CGImageSource? { get }

    /// 싱크용 큐
    var syncQueue: DispatchQueue { get }
    
    /** DefaultAnimationImage 클래스에서 선언 */
    /// type
    var type: AnimationImage.type { get }
    /// 크기
    var size: NSSize { get set }
    /// 애니메이션 여부
    var isAnimation: Bool { get }
    /// 루프 횟수
    var loopCount: UInt { get set }
    /// 특정 인덱스의 delay(duration)
    func delayTime(at index: Index)-> Float
}

// MARK: Animation Convertible Extension
extension AnimationConvertible {
    /**
     imageSource를 cgImageSource로 캐스팅해서 반환 (가능한 경우)
     
     # 참고사항
     - Core Foundation 변수가 opaque 타입이기 때문에 as 를 이용한 CF 타입 -> swift 타입 다운캐스팅에 문제가 있음. 따라서 이 같은 처리가 필요
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
    public var frameCount: Int {
        /*
        // imageSource가 없을 떄는 0 반환
        //guard let imageSource = self.castedCGImageSource else {
        guard let imageSource = self.imageSource else {
            print("AnimationConvertible>frameCount: imageSource가 없음...")
            return 0
        }
        return CGImageSourceGetCount(imageSource)
         */
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

    // MARK: Collection Protocol Related
    /// collection 프로토콜용 메쏘드 및 프로퍼티
    public func index(after i: Int) -> Int {
        return i+1
    }
    public var startIndex: Int {
        return 0
    }
    public var endIndex: Int {
        // 배열인 경우, ..< endIndex 로 비교. endIndex 자체는 포함되지 않기 때문에, frameCount를 반환하면 된다!
        return self.frameCount
    }
    /// 특정 인덱스의 이미지를 반환 : Collection 프로토콜 사용
    public subscript(index: Int)-> NSImage? {
        // 동시성 확보를 위해, 싱크 처리
        self.syncQueue.sync { [weak self] () -> NSImage? in

            // self가 NIL인 경우, NIL 반환
            guard let strongSelf = self else { return nil }
            guard 0 ..< strongSelf.frameCount ~= index else {
                print("AnimationConvertible>subscript: \(index)가 프레임 범위 \(strongSelf.frameCount)를 초과!")
                return nil
            }
            if index < strongSelf.frameCount {
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
                let size = NSMakeSize(CGFloat(cgImage!.width), CGFloat(cgImage!.height))
                return NSImage.init(cgImage: cgImage!, size: size)
            }
            // 이외의 경우, NIL 반환
            return nil
        }

        /*
        guard 0 ..< self.frameCount ~= index else {
            /**
             # 주의사항:
             // 여기서 중지되는 경우, webp에서 문제가 생겼을 가능성 있음. imageSource에 정상적으로 값이 들어갔는지 확인 필요
             */
            assertionFailure("AnimationConvertible>subscript: \(index)가 프레임 범위를 초과!")
            return nil
        }
        
        guard let imageSource = self.imageSource,
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else {
            print("AnimationConvertible>subscript: \(index) >> cgImage 생성 실패!")
            return nil
        }
        let size = NSMakeSize(CGFloat(cgImage.width), CGFloat(cgImage.height))
        return NSImage.init(cgImage: cgImage, size: size)
         */
    }
}

// MARK: - Default Animation Image Class for Identification
public class DefaultAnimationImage {
    // Dummy Class로 선언됨
    
    /// type
    var type: AnimationImage.type = .unknown
    /// 크기: NSZeroSize로 초기화
    public var size: NSSize = NSZeroSize
    /// 반복 횟수 = 0으로 초기화
    public var loopCount: UInt = 0
}
