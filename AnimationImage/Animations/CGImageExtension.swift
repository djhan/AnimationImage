//
//  CGImageExtension.swift
//  AnimationImage
//
//  Created by DJ.HAN on 2021/07/02.
//  Copyright © 2021 DJ.HAN. All rights reserved.
//

import Foundation
import Cocoa

/// 회전 상태
enum RotationStatus {
    /// 원본
    case origin
    /// 시계방향 90도
    case clockwise
    /// 180도
    case reversal
    /// 반시계방향 90도 (우측 270도)
    case counterClockwise
    
    /// radians 값으로 반환
    var radians: CGFloat {
        get {
            switch self {
            // 원본
            case .origin:
                return 0
            // 90도 회전
            case .clockwise:
                return CGFloat(-90 * (Double.pi / 180))
            // 180도 회전
            case .reversal:
                return CGFloat(180 * (Double.pi / 180))
            // 270도 회전
            case .counterClockwise:
                return CGFloat(90 * (Double.pi / 180))
            }
        }
    }
}

/**
 # 참고 사항:
 EdgeView 3 의`CGImageExtenstion`의 코드를 그대로 복사해 가져옴.
 - CommonLibrary에 넣고 싶으나, CommonLibrary가 먼저 AnimationImage를 참고하기 때문에, 어쩔 수 없이 여기에 복사해서 사용한다
 */
extension CGImage {
    
    /**
     그레이스케일 이미지 여부를 판별
     - 전체 픽셀을 스캔하기 때문에 느리다
     */
    var isGrayscale: Bool {
        return autoreleasepool { [unowned self] () -> Bool in
            // 컬러 스페이스가 없을 때 판별 불가능, true 반환
            guard let colorSpace = self.colorSpace else { return false }
            
            #if DEBUG
            print("CGImage>isGrayscale: colorSpace = \(colorSpace.model)")
            #endif
            // 모노크롬은 즉시 true 반환
            if colorSpace.model == .monochrome {
                return true
            }
            // 그 외의 colorSpace인 경우
            let dataProvider = self.dataProvider
            guard let imageData = dataProvider?.data,
                  let rawData = CFDataGetBytePtr(imageData) else { return false }
            let width = self.width
            let height = self.height
            
            // print("CGImage>isGrayscale: 픽셀 포맷 = \(self.bitmapInfo.pixelFormat)")
            
            var byteIndex = 0
            var allPixelsGrayScale = true
            
            for _ in 0 ... width * height {
                let red = rawData[byteIndex]
                let green = rawData[byteIndex + 1]
                let blue = rawData[byteIndex + 2]
                if !((red == green) && (green == blue)) {
                    allPixelsGrayScale = false
                    
                    #if DEBUG
                    print("CGImage>isGrayscale: color space로 판별!")
                    #endif
                    
                    break
                }
                byteIndex += 4
            }
            return allPixelsGrayScale
        }
    }
    
    /// 회전/반전 적용 후 반환
    /// - Parameters:
    ///     - orientation: CGImage 기반 방향값
    /// - Returns: CGImage. 옵셔널
    func transfrom(orientation: CGImagePropertyOrientation) -> CGImage? {
        return autoreleasepool { [unowned self] () -> CGImage? in
            
            var transformImage: CGImage?
            
            let originalWidth       = self.width
            let originalHeight      = self.height
            
            //-------------------------------------------------------------------------------------------------------------//
            // 특정 이미지의 bitsPerComponent / colorSpace / bitmapInfo가 불일치하는 경우가 있다
            // 이러면 NIL 값이 반환되는 문제 발생!
            // 이런 경우에 대비해서, 이 parameter 들을 수동으로 직접 작성해서 처리하도록 한다
            //-------------------------------------------------------------------------------------------------------------//
            
            let bitsPerComponent    = 8
            var colorSpace: CGColorSpace?
            var bitmapInfo: UInt32?
            
            // 회색조 여부 : 연산을 줄이기 위해 한 번만 확인
            let isGrayscale = self.isGrayscale
            
            // 회색조일 때
            if isGrayscale {
                colorSpace = CGColorSpaceCreateDeviceGray()
                // 회색조일 때는 알파 채널이 없음
                bitmapInfo = CGImageAlphaInfo.none.rawValue
                print("CGImage>transfrom(orientation:): 회색조 colorspace")
            }
                // RGBA일 때
            else {
                colorSpace = CGColorSpaceCreateDeviceRGB()
                bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
                print("CGImage>transfrom(orientation:): RGBA colorspace")
            }

            var rotate: RotationStatus
            var swapWidthHeight: Bool
            var mirrored: Bool
            
            switch orientation {
            case .up:
                rotate = .origin
                swapWidthHeight = false
                mirrored = false
                break
            case .upMirrored:
                rotate = .origin
                swapWidthHeight = false
                mirrored = true
                break
            case .right:
                rotate = .clockwise
                swapWidthHeight = true
                mirrored = false
                break
            case .rightMirrored:
                rotate = .clockwise
                swapWidthHeight = true
                mirrored = true
                break
            case .down:
                rotate = .reversal
                swapWidthHeight = false
                mirrored = false
                break
            case .downMirrored:
                rotate = .reversal
                swapWidthHeight = false
                mirrored = true
                break
            case .left:
                rotate = .counterClockwise
                swapWidthHeight = true
                mirrored = false
                break
            case .leftMirrored:
                rotate = .counterClockwise
                swapWidthHeight = true
                mirrored = true
                break
            }
            let radians = rotate.radians
            
            var width: Int
            var height: Int
            var bytesPerRow: Int
            
            /**
             # 중요 사항
             - 반전시에는 bytesPerRow가 변하지 않을 거라고 생각했지만, 실제로는 현재 그레이스케일인 이미지가 컬러로 판별되거나 하는 문제로 인해 bytesPerRow 값이 변할 수 있다
             - bytesPerRow 값이 잘못되면 다음과 같은 에러를 발생시키며 context 생성에 실패한다.
             - 'CGBitmapContextCreate: invalid data bytes/row: should be at least 9760 for 8 integer bits/component, 3 components, kCGImageAlphaPremultipliedLast.'
             - 따라서 매번 계산하는 방식으로 변경
             */
            // bytesPerRow 값이 변함: 흑백 / 컬러 이미지에 따라 bytesPerRow 값을 계산
            if swapWidthHeight {
                width = originalHeight
                height = originalWidth
                bytesPerRow = isGrayscale ? width * 1 : width * 4
            }
            else {
                width = originalWidth
                height = originalHeight
                bytesPerRow = isGrayscale ? width * 1 : width * 4
            }

            if let cgcontext = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace!, bitmapInfo: bitmapInfo!) {
                
                cgcontext.translateBy(x: CGFloat(width) / 2.0, y: CGFloat(height) / 2.0)
                if mirrored {
                    cgcontext.scaleBy(x: -1.0, y: 1.0)
                }
                cgcontext.rotate(by: CGFloat(radians))
                if swapWidthHeight {
                    cgcontext.translateBy(x: -CGFloat(height) / 2.0, y: -CGFloat(width) / 2.0)
                }
                else {
                    cgcontext.translateBy(x: -CGFloat(width) / 2.0, y: -CGFloat(height) / 2.0)
                }
                cgcontext.draw(self, in: CGRect(x: 0, y: 0, width: originalWidth, height: originalHeight))
                
                transformImage = cgcontext.makeImage()
            }
            else {
                print("CGImage>transfrom(orientation:): CGContext 생성 실패!")
            }
            
            return transformImage
        }
    }
}
