//
//  VideoProvider.swift
//  PiPSample
//
//  Created by 山口賢登 on 2022/01/17.
//

import AVFoundation
import UIKit

// PiPに表示するコンテンツを提供するProvider
// このクラスでUILabelを動画ソースに変換している
class PiPContentProvider: NSObject {
    // timerを保持
    private var timer: Timer!
    // PiP内に表示するコンテンツのLayer
    // AVSampleBufferDisplayLayerは、CMSampleBufferを与えることで動画を再生する
    var sampleBufferDisplayLayer = AVSampleBufferDisplayLayer()
        
    // ラベルの後ろに表示するView
    private let backView: UIView = {
        let backView = UIView()
        backView.backgroundColor = .black
        let pipSize = PipSize()
        backView.frame = CGRect(x: 0, y: 0, width: pipSize.width, height: pipSize.height)
        return backView
    }()

    // PiPに表示するラベルを生成
    private let showLabel: UILabel = {
        let pipSize = PipSize()
        let showString = "🏃‍♂️💨PiPで文字列が流れるサンプルを作ってみた👨‍💻"
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 30)
        label.text = showString
        label.sizeToFit()
        label.frame = CGRect(x: pipSize.width, y: 0, width: label.intrinsicContentSize.width, height: pipSize.height)
        label.textAlignment = .center
        label.textColor = .systemMint
        return label
    }()
    
    override init() {
        backView.addSubview(showLabel)
    }
    
    // 新たにViewを画像化する
    func nextBuffer() -> UIImage {
        // labelの位置を動かす
        showLabel.frame.origin.x = showLabel.frame.origin.x - 1
        if (showLabel.frame.origin.x + showLabel.frame.width) <= 0 {
            showLabel.frame.origin.x = PipSize().width
        }
        return backView.convertToUIImage()
    }
    
    func start() {
        // 1秒ごとに更新
        timer = Timer(timeInterval: 0.01, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            if self.sampleBufferDisplayLayer.status == .failed {
                // エラーのせいでsampleBufferをレンダリングできない場合は、
                // 保留中のキューに入れられたsampleBufferを破棄する
                self.sampleBufferDisplayLayer.flush()
            }
            // CMSampleBufferはUIImageなどを材料にして生成することができる
            guard let buffer = self.nextBuffer().cmSampleBuffer() else { return }
            // 表示するフレームを追加する
            self.sampleBufferDisplayLayer.enqueue(buffer)
        }
        // timerが遅延したりずれないようにcommonスレッドを指定
        RunLoop.main.add(timer, forMode: .common)
    }
    
    func stop() {
        if timer != nil {
            timer.invalidate()
            timer = nil
        }
    }

    func isRunning() -> Bool {
        return timer != nil
    }
    
}
