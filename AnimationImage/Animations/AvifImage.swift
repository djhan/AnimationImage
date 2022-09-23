//
//  AvifImage.swift
//  AnimationImage
//
//  Created by DJ.HAN on 2022/09/23.
//  Copyright © 2022 DJ.HAN. All rights reserved.
//

import Foundation
import CommonLibrary
import AnimationImagePrivate
import SDWebImageAVIFCoder

// MARK: - AVIF Image Class -

class AvifImageClass: DefaultAnimationImage, AnimationConvertible {
    
    /// 소스 타입 연관값
    typealias SourceType = SDImageAVIFCoder

    /// 이미지 소스
    var imageSource: SourceType?
    
    /// 싱크 큐
    var syncQueue: DispatchQueue = DispatchQueue(label: "djhan.EdgeView.AvifImage", attributes: .concurrent)
    
    /// EXIF
    var exifData: AnimationExifData?
    
    /// 지연 시간
    func delayTime(at index: Int) -> Float {
        return Float(self.imageSource?.animatedImageDuration(at: UInt(index)) ?? 0)
    }
}
