//
//  WebpExImage.swift
//  AnimationImage
//
//  Created by DJ.HAN on 05/06/2019.
//  Copyright © 2019 DJ.HAN. All rights reserved.
//
/*
import Cocoa
import AnimationImagePrivate

//================================================================================//
//
// Webp Extended Image Class - Objective C 코드의 Wrapper로 작동
// AnimationConvertible 프로토콜 상속 (자동으로 collection 프로토콜도 상속)
//
//================================================================================//
class WebpExImage: DefaultAnimationImage, AnimationConvertible {
    // 소스 타입 연관값
    typealias SourceType = WebpImage
    
    // 종류
    // type: DefaultAnimationImage에서 선언됨
    // webp 이미지 소스
    internal var imageSource: SourceType? {
        didSet {
            // 첫 번째 이미지를 가져온다
            if let firstImage = self[0] {
                // 크기 설정
                self.size = firstImage.size
            }
            // loopCount 값을 받아온다
            // 값을 받아오지 못한 경우는 실패 처리
            guard let webpImage = self.imageSource else { return }
            self.loopCount = webpImage.loopCount
        }
    }
    // 사용하지 않음
    internal var source: CGImageSource?
    
    // 동기화 큐
    lazy var syncQueue = DispatchQueue(label: "djhan.EdgeView.WebpExImage", attributes: .concurrent)

    // MARK: Initialization
    // 초기화
    init(from imageSource: WebpImage) {
        super.init()
        // 이미지 소스 대입
        self.imageSource = imageSource
        // 소스 설정시 webp 로 설정
        self.type = .webp
    }
    // URL로 초기화
    convenience init?(from url:URL) {
        // 이미지 소스 생성 실패시 nil 반환
        guard let imageSource = WebpImage.init(url: url) else { return nil }
        // 정상적으로 초기화
        self.init(from: imageSource)
    }
    
    // Data로 초기화
    convenience init?(from data:Data) {
        // 이미지 소스 생성 실패시 nil 반환
        guard let imageSource = WebpImage.init(data: data) else { return nil }
        // 정상적으로 초기화
        self.init(from: imageSource)
    }
    
    // MARK: Method
    // 특정 인덱스의 Delay를 반환
    func delayTime(at index: Int) -> Float {
        // delayTime을 NSNumber로 가져온다. 실패시 0.1초 반환
        guard let delayTime = self.imageSource?.duration(at: index) else { return 0.1 }
        return delayTime
    }
}
*/
