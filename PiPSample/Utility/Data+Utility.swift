//
//  Data+Utility.swift
//  PiPSample
//
//  Created by 山口賢登 on 2022/01/19.
//

import Foundation
import AVFoundation

extension Data {
    
    // CMBlockBufferにする
    // CMBlockBuffer：処理システムを介してメモリのブロックを移動するために使用されるObject
    func toCMBlockBuffer() -> CMBlockBuffer? {
        let data = NSMutableData(data: self)
        var source = CMBlockBufferCustomBlockSource()
        source.refCon = Unmanaged.passRetained(data).toOpaque()
        source.FreeBlock = freeBlock
        
        var blockBuffer: CMBlockBuffer?
        // メモリブロックに支えられた新しいCMBlockBufferを作成する
        let result = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: data.mutableBytes,
            blockLength: data.length,
            blockAllocator: kCFAllocatorNull,
            customBlockSource: &source,
            offsetToData: 0,
            dataLength: data.length,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        
        if OSStatus(result) != kCMBlockBufferNoErr {
            return nil
        }
        
        guard let buffer = blockBuffer else {
            return nil
        }
        
        assert(CMBlockBufferGetDataLength(buffer) == data.length)
        return buffer
    }
    
}

fileprivate func freeBlock(_ refCon: UnsafeMutableRawPointer?, doomedMemoryBlock: UnsafeMutableRawPointer, sizeInBytes: Int) {
    let unmanagedData = Unmanaged<NSData>.fromOpaque(refCon!)
    unmanagedData.release()
}
