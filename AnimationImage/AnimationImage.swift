//
//  AnimationImage.swift
//  AnimationImage
//
//  Created by DJ.HAN on 02/06/2019.
//  Copyright © 2019 DJ.HAN. All rights reserved.
//

import Cocoa
import AnimationImagePrivate

// MARK: -AnimationImage Delegate Protocol
//==============================================================//
// Animation Image Delegate Protocol
//==============================================================//
public protocol AnimationImageDelegate: class {
    // 변형 적용 여부
    var isTransformation: Bool { get }
}

// MARK: -AnimationImage Class
//==============================================================//
//
// Animation Image Class
// 미완성 부분: subscript에서 이미지 반환시 additinoalImage를 생성하는 부분
//
//
//==============================================================//
public class AnimationImage : NSObject, Collection {
    // MARK: AnimationImage Enumerations
    // 종류
    public enum type {
        // GIF
        case gif
        // PNG
        case png
        // WEBP
        case webp
        // Unknown
        case unknown
    }
    // 캐쉬 종류
    public enum cache {
        // original
        case original
        // additional
        case additional
    }

    // MARK: Collection Protocol Related
    // collection 프로토콜용 메쏘드 및 프로퍼티
    public func index(after i: Int) -> Int {
        return i + 1
    }
    public var startIndex: Int {
        get { return 0 }
    }
    public var endIndex: Int {
        get {
            let _endIndex = self.numberOfItems - 1
            return _endIndex >= 0 ? _endIndex : 0
        }
    }
    // collection 프로토콜용 메쏘드 및 프로퍼티 종료

    // 기본 캐쉬
    private lazy var originalCache = NSCache<NSNumber, NSImage>()
    // 변형 전용 캐쉬
    private lazy var additionalCache = NSCache<NSNumber, NSImage>()

    // 현재 인덱스
    public var currentIndex = 0
    // 총 이미지 개수
    public var numberOfItems: Int {
        get {
            return 0
        }
    }

    // 이미지 소스
    private var image: DefaultAnimationImage?
    // 이미지 종류
    private var type: AnimationImage.type = .unknown
    // 종류별로 다운캐스팅된 이미지 소스
    private var gifImage: GifImage? {
        get {
            guard let image = self.image else { return nil }
            return image as? GifImage
        }
    }
    private var pngImage: PngImage? {
        get {
            guard let image = self.image else { return nil }
            return image as? PngImage
        }
    }
    private var webpImage: WebpExImage? {
        get {
            guard let image = self.image else { return nil }
            return image as? WebpExImage
        }
    }
    
    // 애니메이션 이미지 여부
    public var isAnimation: Bool {
        get {
            // 이미지 개수가 1개 이상인 경우 true 반환
            if self.numberOfItems > 1 { return true }
                // 아닌 경우, false 반환
            else { return false }
        }
    }
    // 현재 이미지 - 현재 인덱스의 이미지 반환
    public var currentImage: NSImage? {
        get {
            return self[self.currentIndex]
        }
    }
    
    // delegate
    weak var delegate: AnimationImageDelegate?
    
    //===================================================//
    // 실제 이미지
    //===================================================//

    // MARK: Initialization
    init(with delegate: AnimationImageDelegate, type: AnimationImage.type) {
        super.init()
        // delegate 대입
        self.delegate = delegate
        // 종류 대입
        self.type = type
    }
    // URL + Delegate로 초기화 실행
    convenience init?(from url: URL, type: AnimationImage.type, with delegate: AnimationImageDelegate) {
        // 종류별로 image를 초기화
        switch type {
        case .gif:
            guard let image = GifImage.init(from: url) else { return nil }
            // 초기화 실행
            self.init(with: delegate, type: type)
            self.image = image
        case .png:
            guard let image = PngImage.init(from: url) else { return nil }
            // 초기화 실행
            self.init(with: delegate, type: type)
            self.image = image
        case .webp:
            guard let image = WebpExImage.init(from: url) else { return nil }
            // 초기화 실행
            self.init(with: delegate, type: type)
            self.image = image
        case .unknown:
            // 초기화 중지
            return nil
        }
    }
    // Data + Delegate로 초기화 실행
    convenience init?(from data: Data, type: AnimationImage.type,  with delegate: AnimationImageDelegate) {
        // 종류별로 image를 초기화
        switch type {
        case .gif:
            guard let image = GifImage.init(from: data) else { return nil }
            // 초기화 실행
            self.init(with: delegate, type: type)
            self.image = image
        case .png:
            guard let image = PngImage.init(from: data) else { return nil }
            // 초기화 실행
            self.init(with: delegate, type: type)
            self.image = image
        case .webp:
            guard let image = WebpExImage.init(from: data) else { return nil }
            // 초기화 실행
            self.init(with: delegate, type: type)
            self.image = image
        case .unknown:
            // 초기화 중지
            return nil
        }
    }

    // MARK: Method
    // 특정 인덱스의 이미지를 반환 : Collection 프로토콜 사용시에도 중요
    public subscript(index: Int)-> NSImage? {
        // 델리게이트로부터 변형 여부를 가져온다
        // 델리게이트가 nil인 경우, nil 반환
        guard let isTransformation = delegate?.isTransformation else { return nil }
        // 반환용 이미지
        var image: NSImage?
        // 검색용 Cache 종류
        let target: AnimationImage.cache = isTransformation == false ? .original : .additional
        
        // 캐쉬에서 이미지를 가져온다
        switch target {
        case .original:
            image = self.originalCache.object(forKey: NSNumber.init(value: index))
        case .additional:
            image = self.additionalCache.object(forKey: NSNumber.init(value: index))
        }
        // 캐쉬에서 이미지를 가져왔는지 여부를 확인
        if image != nil {
            // 성공시 반환
            return image
        }
            // 캐쉬 미작성시, 생성후 반환
        else {
            return self.makeImage(from: index, at: target)
        }
    }
    // 이미지 생성후 캐쉬에 저장
    private func makeImage(from index: Int, at cache: AnimationImage.cache)-> NSImage? {
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
        // 이미지를 가져오는 데 성공한 경우
        if image != nil {
            // 캐쉬에 저장
            switch cache {
            case .original:
                self.originalCache.setObject(image!, forKey: NSNumber.init(value: index))
            case .additional:
                //
                //
                //
                //
                // 가져온 원본 이미지 (image)를 기반으로
                // 이미지 변형 처리 필요
                //
                //
                //
                //
                self.additionalCache.setObject(image!, forKey: NSNumber.init(value: index))
            }
            
            // 반환
            return image
        }
        // 그 외의 경우 NIL 반환
        return nil
    }
    
    // MARK: Manage Cache
    // 전체 제거
    public func clearAllCaches()-> Void {
        self.clearCache(at: .original)
        self.clearCache(at: .additional)
    }
    // 특정 캐쉬 제거
    public func clearCache(at cache: AnimationImage.cache)-> Void {
        switch cache {
        case .original:
            self.originalCache.removeAllObjects()
        case .additional:
            self.additionalCache.removeAllObjects()
        }
    }
}
