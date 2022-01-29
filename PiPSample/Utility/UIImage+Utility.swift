//
//  UIImage+Utility.swift
//  PiPSample
//
//  Created by 山口賢登 on 2022/01/18.
//

import AVFoundation
import Foundation
import UIKit

extension UIImage {
    
    func cmSampleBuffer() -> CMSampleBuffer? {
        // JPEG（Data型）に変換、UIImageからcgImageを取得
        guard let jpegData = jpegData(compressionQuality: 0.1), let cgImage = cgImage else { return nil }
        let rawPixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        // SampleBuffer内のSampleを説明するメディアフォーマット記述
        var format: CMFormatDescription?
        
        // CMVideoMediaStreamのフォーマットの説明を作成する
        CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCMVideoCodecType_JPEG,
            width: Int32(rawPixelSize.width),
            height: Int32(rawPixelSize.height),
            extensions: nil,
            formatDescriptionOut: &format
        )
        
        guard let cmBlockBuffer = jpegData.toCMBlockBuffer() else {
            return nil
        }
        
        var size = jpegData.count
        var sampleBuffer: CMSampleBuffer?
        // 画面がレンダリングできる1秒当たりの最大フレーム数
        let preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
        let presentationTimeStamp = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: CMTimeScale(preferredFramesPerSecond))
        let duration = CMTime(value: 1, timescale: CMTimeScale(preferredFramesPerSecond))
        
        var timingInfo = CMSampleTimingInfo(
            duration: duration,
            presentationTimeStamp: presentationTimeStamp,
            decodeTimeStamp: .invalid
        )
        
        CMSampleBufferCreateReady(
            allocator: kCFAllocatorDefault,
            dataBuffer: cmBlockBuffer,
            formatDescription: format,
            sampleCount: 1,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timingInfo,
            sampleSizeEntryCount: 1,
            sampleSizeArray: &size,
            sampleBufferOut: &sampleBuffer)
        
        guard let sampleBuffer = sampleBuffer else {
            assertionFailure("SampleBuffer is null")
            return nil
        }

        return sampleBuffer
    }
    
}
