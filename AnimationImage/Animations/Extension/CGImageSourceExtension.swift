//
//  CGImageSourceExtension.swift
//  AnimationImage
//
//  Created by DJ.HAN on 2021/07/02.
//  Copyright © 2021 DJ.HAN. All rights reserved.
//

import Foundation
import Cocoa

/**
 # 참고 사항:
 EdgeView 3 의 코드 일부를 그대로 복사해 가져옴.
 - CommonLibrary에 넣고 싶으나, CommonLibrary가 먼저 AnimationImage를 참고하기 때문에, 어쩔 수 없이 여기에 복사해서 사용한다
 */
extension NSDictionary {
    /// NSDictionary -> Dictionary 로 변환
    /// - 키값은 String, 값은 Any 형태로 반환
    var swiftDictionary: Dictionary<String, Any> {
        var swiftDictionary = Dictionary<String, Any>()
        
        for key : Any in self.allKeys {
            // 키값은 String으로 간주, 아닌 경우 다음 키값으로 넘어간다
            guard let stringKey = key as? String else { continue }
            if let keyValue = self.value(forKey: stringKey){
                swiftDictionary[stringKey] = keyValue
            }
        }
        
        return swiftDictionary
    }
}

extension CGImageSource {
    
    /**
     `CGImagePropertiesData`를 `Dictionary` 로 변환하는 확장
     - EXIF 외에 TIFF, GPS, 기타 다양한 정보를 가져올 수 있다
     - Returns: `Dictionary<String, Any>` 타입으로, String 키값에 대응하는 Exif 정보를 딕셔너리로 반환
     */
    func propertiesData() -> Dictionary<String, Any>? {
        guard let imageCFMetadata = CGImageSourceCopyPropertiesAtIndex(self, 0, .none) else { return nil }
        // swift Dictionary로 반환
        return (imageCFMetadata as NSDictionary).swiftDictionary
    }

    /**
     `CGImageSource`에 속한 개별 이미지의 `ExifProperties`를 배열로 반환
     - 복수 이미지가 있는 경우, 각각의 `ExifProperties`를 배열로 저장한다
     */
    var exifData: AnimationExifData? {
        // cgImageSource 의 이미지 개수를 구한다
        let count = CGImageSourceGetCount(self)
        
        // print("CGImageSource>exifs: 이미지 개수 = \(count)")
        // 이미지 개수가 0개이면 nil 반환
        if count == 0 { return nil }
        
        var exifs = Array<AnimationExifProperties>()
        for index in 0 ..< count {
            guard let exifProperties = CGImageSourceCopyPropertiesAtIndex(self, index, nil) as? AnimationExifProperties else { continue }
            exifs.append(exifProperties)
        }
        return exifs
    }

    /**
     현재 메타 데이터에서 orientation 값만 변경해 반환
     - Parameter orientation: 변경될 Orientation 값. `UInt32` 로 지정
     - Returns: 변경된 `ExifData`. 현재 ExifData가 없는 경우에는 nil 반환
     */
    func changingOrientation(_ orientation: CGImagePropertyOrientation) -> AnimationExifData? {
        // Mutable 이미지 메타데이터 선언
        let newMetaData: CGMutableImageMetadata
        // 기존 메타데이터가 있는 경우 복사
        if let currentMetadata = CGImageSourceCopyMetadataAtIndex(self, 0, nil),
           let tempMetaDataCopy = CGImageMetadataCreateMutableCopy(currentMetadata) {
            newMetaData = tempMetaDataCopy
        }
        // 없는 경우 새로 생성
        else {
            newMetaData = CGImageMetadataCreateMutable()
        }
        
        // 방향 태그 생성
        guard let orientationTag = CGImageMetadataTagCreate(kCGImageMetadataNamespaceTIFF,
                                                            kCGImageMetadataPrefixTIFF,
                                                            kCGImagePropertyOrientation,
                                                            CGImageMetadataType.default,
                                                            NSNumber.init(value: orientation.rawValue)) else {
            return nil
        }
        let orientationTagPath = "\(kCGImageMetadataPrefixTIFF):\(kCGImagePropertyTIFFOrientation)"
        guard CGImageMetadataSetTagWithPath(newMetaData, nil, orientationTagPath as CFString, orientationTag) == true else {
            assertionFailure("CGImageSoure>changingOrientation(_:): MetaData 생성 실패!")
            return nil
        }
        
        // 현재의 exifData 배열
        let currentExifData = self.exifData
        // 반환될 exifData 배열
        var newExifData = [AnimationExifProperties]()
        
        //============================================================//
        /// 신규 exifProperties에 회전값 추가후 newExifData에 추가하는 내부 메쏘드
        func append(newExifProperties: inout AnimationExifProperties) {
            // 회전값
            newExifProperties[kCGImagePropertyOrientation as String] = orientation
            // 메타데이터
            newExifProperties[kCGImageDestinationMetadata as String] = newMetaData
            // 병합 여부 = false
            newExifProperties[kCGImageDestinationMergeMetadata as String] = false
            // newExifData에 추가
            newExifData.append(newExifProperties)
        }
        //============================================================//

        // 기존 exif 데이터가 있는 경우
        if let exifData = currentExifData {
            for exifProperties in exifData {
                var newExifProperties = exifProperties
                append(newExifProperties: &newExifProperties)
            }
        }
        // 없는 경우
        else {
            var newExifProperties = AnimationExifProperties()
            append(newExifProperties: &newExifProperties)
        }
        
        return newExifData
    }
}

