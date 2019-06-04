//
//  GifImage.swift
//  AnimationImage
//
//  Created by DJ.HAN on 04/06/2019.
//  Copyright © 2019 DJ.HAN. All rights reserved.
//

import Cocoa

class GifImage: NSObject, Collection {
    // MARK: Collection Protocol Related
    // collection 프로토콜용 메쏘드 및 프로퍼티
    func index(after i: Int) -> Int {
        return i+1
    }
    var startIndex: Int {
        get { return 0 }
    }
    var endIndex: Int {
        get {
            let _endIndex = self.frameCount - 1
            return _endIndex >= 0 ? _endIndex : 0
        }
    }
    
    // 격납용 CGImageSource
    var gifSource: CGImageSource? {
        // 세팅 완료시
        didSet {
            autoreleasepool {
                // imageSource가 제대로 설정되지 않은 경우 중지
                guard let gifSource = self.gifSource else { return }
                // GIF Metadata Dictionaries 를 설정
                // imageProperties를 가져온다
                guard let imageProperties = CGImageSourceCopyProperties(gifSource, nil) else { return }
                // 검색 키값을 설정
                let key = kCGImagePropertyGIFDictionary as NSString
                // 기본 Dictionary를 가져온다
                guard let rawDicts = CFDictionaryGetValue(imageProperties, Unmanaged.passUnretained(key).toOpaque()) else { return }
                let gifDefaultsDicts = Unmanaged<CFDictionary>.fromOpaque(rawDicts).takeUnretainedValue() as NSDictionary
                guard let loopCountNumber = gifDefaultsDicts[kCGImagePropertyGIFLoopCount as NSString] as? NSNumber else { return }
                self.loopCount = UInt(truncating: loopCountNumber)
            }
        }
    }

    // 애니메이션 여부
    var isAnimation: Bool {
        get {
            // 프레임 갯수가 1개 이상일 때, True 반환
            if self.frameCount > 1 { return true }
            return false
        }
    }
    // 프레임 갯수
    var frameCount: Int {
        get {
            // gifSource가 없을 떄는 0 반환
            guard let gifSource = self.gifSource else {
                return 0
            }
            return CGImageSourceGetCount(gifSource)
        }
    }
    // 루프 횟수 = 0으로 초기화
    var loopCount: UInt = 0
    
    // MARK: Initialization
    // URL로 초기화
    init(from url:URL) {
        super.init()
        
        self.gifSource = CGImageSourceCreateWithURL(url as CFURL, nil)
    }
    
    // Data로 초기화
    init(from data:Data) {
        super.init()
        
        self.gifSource = CGImageSourceCreateWithData(data as CFData, nil)
    }

    // MARK: Method
    // 특정 인덱스의 이미지를 반환 : Collection 프로토콜 사용시에도 중요
    public subscript(index: Int)-> NSImage? {
        if index < self.frameCount {
            guard let gifSource = self.gifSource else { return nil }
            guard let gifCGImage = CGImageSourceCreateImageAtIndex(gifSource, index, nil) else { return nil }
            let size = NSMakeSize(CGFloat(gifCGImage.width), CGFloat(gifCGImage.height))
            return NSImage.init(cgImage: gifCGImage, size: size)
        }
        // 이외의 경우, NIL 반환
        return nil
    }
}
