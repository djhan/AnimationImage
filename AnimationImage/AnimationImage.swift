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

}

// MARK: -AnimationImage Class
public class AnimationImage : NSObject, Collection {
    // MARK: AnimationImage Enumerations
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
    private var image: AnyObject?
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
    convenience init(from url: URL, type: AnimationImage.type, with delegate: AnimationImageDelegate) {
        self.init(with: delegate, type: type)
        // 종류별로 image를 초기화
        switch self.type {
        case .gif:
            self.image = GifImage.init(from: url)
        case .png:
            self.image = PngImage.init(from: url)
        case .webp:
            self.image = WebpExImage.init(from: url)
        default:
            // 초기화 중지
            return
        }
    }
    // Data + Delegate로 초기화 실행
    convenience init(from data: Data, type: AnimationImage.type,  with delegate: AnimationImageDelegate) {
        self.init(with: delegate, type: type)
        // 종류별로 image를 초기화
        switch self.type {
        case .gif:
            self.image = GifImage.init(from: data)
        case .png:
            self.image = PngImage.init(from: data)
        case .webp:
            self.image = WebpExImage.init(from: data)
        default:
            // 초기화 중지
            return
        }
    }

    // MARK: Method
    // 특정 인덱스의 이미지를 반환 : Collection 프로토콜 사용시에도 중요
    public subscript(index: Int)-> NSImage? {

        return nil
    }
}
