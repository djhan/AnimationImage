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
    var isEffect: Bool { get }
    // 애니메이션 이미지의 Last Frame Index
    var animationLastIndex: Int? { get set }
}

// MARK: - AnimationImage Class
//==============================================================//
//
// Animation Image Class
//
//==============================================================//
public class AnimationImage {
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
        // effect
        case effect
    }

    // 기본 캐쉬
    private lazy var originalCache  = NSCache<NSNumber, NSImage>()
    // 변형 전용 캐쉬
    private lazy var effectCache    = NSCache<NSNumber, NSImage>()
    // 각 프레임 별 지연 시간(duration) 저장 딕셔너리
    private lazy var delays                 = [Int: Float]()

    // 현재 인덱스
    public var currentIndex = 0 {
        didSet {
            guard let delegate = self.delegate else { return }
            // delegate의 마지막 애니메이션 프레임 인덱스 값을 currentIndex로 변경한다
            delegate.animationLastIndex = self.currentIndex
        }
    }
    // 총 이미지 개수
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
    // 총 루프 횟수
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

    // 이미지 소스
    private var image: DefaultAnimationImage?
    // 이미지 종류
    private var type: AnimationImage.type = .unknown
    // 종류별로 다운캐스팅된 이미지 소스
    private var gifImage: GifImage? {
        return image as? GifImage
    }
    private var pngImage: PngImage? {
        return image as? PngImage
    }
    private var webpImage: WebpExImage? {
        return image as? WebpExImage
    }
    
    // 특수효과 이미지 존재 여부
    public var hasEffectImages: Bool = false
    
    // 애니메이션 이미지 여부
    public var isAnimation: Bool {
        // 이미지 개수가 1개 이상인 경우 true 반환
        if self.numberOfItems > 1 { return true }
            // 아닌 경우, false 반환
        else { return false }
    }
    // 현재 이미지 - 현재 인덱스의 이미지 반환: Original / Effect 여부는 자동 판별
    public var currentImage: NSImage? {
        return self[self.currentIndex]
    }
    // 현재 오리지날 이미지 - 현재 인덱스의 오리지날 이미지 반환
    public var currentOriginalImage: NSImage? {
        return self.originalImage(at: self.currentIndex)
    }
    // 현재 특수효과 이미지 - 현재 인덱스의 특수효과 이미지 반환
    public var currentEffectImage: NSImage? {
        return self.effectImage(at: self.currentIndex)
    }
    // 최초 오리지날 이미지 반환: 여백 제거 등에 사용
    public var firstOriginalImage: NSImage? {
        return self.image(at: 0, from: .original)
    }
    // Pixel Size
    public var pixelSize: NSSize {
        guard let firstImage = self.firstOriginalImage else { return NSZeroSize }
        return firstImage.size
    }

    // delegate
    weak var delegate: AnimationImageDelegate?
    
    //===================================================//
    // 실제 이미지
    //===================================================//

    // MARK: Initialization
    init(with delegate: AnimationImageDelegate, type: AnimationImage.type) {
        // delegate 대입
        self.delegate = delegate
        // 종류 대입
        self.type = type
        
        // delegate에 마지막 인덱스가 있는 경우, currentIndex를 lastIndex로 변경
        if let lastIndex = self.delegate?.animationLastIndex {
            self.currentIndex = lastIndex
        }
    }
    // URL + Delegate로 초기화 실행
    // 마지막 frame의 index도 설정 가능
    public convenience init?(from url: URL, type: AnimationImage.type, with delegate: AnimationImageDelegate) {
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
    public convenience init?(from data: Data, type: AnimationImage.type, with delegate: AnimationImageDelegate) {
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
    // 특정 인덱스의 오리지날 이미지를 반환
    public func originalImage(at index: Int) -> NSImage? {
        return self.image(at: index, from: .original)
    }
    // 특정 인덱스의 특수효과 이미지를 반환
    public func effectImage(at index: Int) -> NSImage? {
        return self.image(at: index, from: .effect)
    }

    // 특정 인덱스의 특정 캐쉬의 이미지를 반환
    private func image(at index: Int, from target: AnimationImage.cache) -> NSImage? {
        // 반환용 이미지
        var image: NSImage?
        
        // 캐쉬에서 이미지를 가져온다
        switch target {
        case .original:
            image = self.originalCache.object(forKey: NSNumber.init(value: index))
        case .effect:
            image = self.effectCache.object(forKey: NSNumber.init(value: index))
        }
        // 캐쉬에서 이미지를 가져왔는지 여부를 확인
        if image != nil {
            // 성공시 반환
            return image
        }
            // 캐쉬 미작성시, 오리지날 캐쉬를 생성한 다음 반환
        else {
            return self.makeImage(from: index)
        }
    }
    
    // 오리지날 이미지 생성후 캐쉬에 저장
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
        // 이미지를 가져오는 데 성공한 경우
        if image != nil {
            // 캐쉬에 저장
            self.originalCache.setObject(image!, forKey: NSNumber.init(value: index))
            
            // 반환
            return image
        }
        // 그 외의 경우 NIL 반환
        return nil
    }
    
    // 특정 이미지 배열을 특수효과 이미지 캐쉬에 추가
    public func addEffecImages(from images: [NSImage]) -> Bool {
        if images.count != self.numberOfItems {
            print("AnimationImage>setEffecImages: \(images.count) 와 \(self.numberOfItems) 개수가 불일치, 실패!")
            return false
        }
        // 동기화 처리
        return synchronized(self) { [unowned self] in
            for index in 0 ..< images.count {
                let image = images[index]
                // 특수효과 캐쉬에 저장
                self.effectCache.setObject(image, forKey: NSNumber.init(value: index))
            }
            // 특수효과 존재 여부 = YES
            self.hasEffectImages = true
            return true
        }
    }
    
    // MARK: Manage Cache
    // 전체 제거
    public func clearAllCaches()-> Void {
        self.clearCache(at: .original)
        self.clearCache(at: .effect)
    }
    // 특정 캐쉬 제거
    public func clearCache(at cache: AnimationImage.cache)-> Void {
        // 동기화 처리
        synchronized(self) { [unowned self] in
            switch cache {
            case .original:
                self.originalCache.removeAllObjects()
            case .effect:
                self.effectCache.removeAllObjects()
                // 특수효과 존재 여부 = NO
                self.hasEffectImages = false
            }
        }
    }
    
    // MARK: Methods

    // 특정 index의 delay : 외부 접근 메쏘드
    // delay가 delay 딕셔너리에 없을 땐 가져온 뒤 딕셔너리에 반환
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
    
    // 특정 index의 delay를 가져온다
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
    
    // Landscape 여부 판단 : landscapeRatio에 의거하여 판단
    func isLandscape(landscapeRatio: CGFloat) -> Bool {
        // 폭/ 높이 ratio 가 landscapeRatio 를 능가하는 경우, true 반환
        if self.pixelSize.width / self.pixelSize.height > landscapeRatio { return true }
        // 이외의 경우
        return false
    }
}


// MARK: - AnimationImage Extension for Collection
// Collection 프로토콜에 대응하기 위한 확장
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
        return synchronized(self) { [unowned self] () -> NSImage? in
            // 델리게이트로부터 변형 여부를 가져온다
            // 델리게이트가 nil인 경우, nil 반환
            guard let isEffect = delegate?.isEffect else { return nil }
            // 검색용 Cache 종류
            let target: AnimationImage.cache = isEffect == false ? .original : .effect
            // 해당 Cache의 해당 index 이미지를 반환
            return self.image(at: index, from: target)
        }
    }
    // collection 프로토콜용 메쏘드 및 프로퍼티 종료
}
