//
//  ViewController.swift
//  PiPSample
//
//  Created by 山口賢登 on 2022/01/17.
//

import AVKit
import UIKit
import Combine

struct PipSize {
    var width = UIScreen.main.bounds.width
    var height = 70.0
}

// PiPの開始ボタンや、AVSampleBufferDisplayLayerをaddSubviewしているクラス
// 公式ドキュメントをほぼそのまま踏襲してPiPの実装している
// https://developer.apple.com/documentation/avkit/adopting_picture_in_picture_in_a_custom_player
final class ViewController: UIViewController {
    // PiP開始ボタン
    @IBOutlet weak var startButton: UIButton!
    // PiPに表示するコンテンツを提供するProvider
    private let pipContentProvider = PiPContentProvider()
    // pipを表示するためのController
    private var pipController: AVPictureInPictureController?
    // AVPictureInPictureControllerが有効になるのを受け付けるObserv
    private var pipPossibleObservation: NSKeyValueObservation?
    private var observer: NSObjectProtocol?
    // pipが現在再生しているのか
    private var isPaused = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        // PiPにしない状態で表示内容を更新する
        pipContentProvider.start()
        setupPiPController()
    }
    
    // 各Viewを生成する
    private func setupView() {
        let pipSize = PipSize()
        // PiP表示用の画面を作成
        let videoContainerView = UIView()
        videoContainerView.frame = CGRect(x: 0, y: 40, width: pipSize.width, height: pipSize.height)
        videoContainerView.center = view.center
        self.view.addSubview(videoContainerView)
        
        // PiP内に表示するコンテンツのレイヤーを生成
        let bufferDisplayLayer = pipContentProvider.sampleBufferDisplayLayer
        bufferDisplayLayer.frame = videoContainerView.bounds
        bufferDisplayLayer.videoGravity = .resizeAspect
        videoContainerView.layer.addSublayer(bufferDisplayLayer)
    }
    

    @IBAction func didTapStartButton(_ sender: UIButton) {
        guard let pipController = pipController else { return }
        // PiPのウィンドウが画面に表示されているかどうか
        if !pipController.isPictureInPictureActive {
            // 表示されている場合は開始
            print("startPiP")
            pipController.startPictureInPicture()
        } else {
            // 表示されてない場合は停止
            print("stopPiP")
            pipController.stopPictureInPicture()
        }

    }
    
    @IBAction func didTapStopButton(_ sender: Any) {
        pipController?.stopPictureInPicture()
    }
    
    private func setupPiPController() {
        // PiPをサポートしているデバイスかどうかを確認
        if AVPictureInPictureController.isPictureInPictureSupported() {
            // AVPictureInPictureController の生成
            let pipContentSource = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: pipContentProvider.sampleBufferDisplayLayer, playbackDelegate: self)
            pipController = AVPictureInPictureController(contentSource: pipContentSource)
            pipController?.delegate = self
            // AVPictureInPictureControllerを生成してから再生可能になるまで数秒程度遅延があるため利用可能になったかをPublisherで検知する
            var cancellables = Set<AnyCancellable>()
            pipController?
                .publisher(for: \.isPictureInPicturePossible, options: [.initial, .new])
                .sink { possible in
                    DispatchQueue.main.async {
                        self.startButton.isEnabled = possible
                        print("pip is \(possible)")
                    }
                }
                .store(in: &cancellables)
        }
    }
    
}

// AVPictureInPictureControllerDelegateのメソッドは全てOptional
extension ViewController: AVPictureInPictureControllerDelegate {
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        // optionalメソッド
        // PiPの再生に失敗した時に呼ばれる
        print("\(#function)")
        print("pip error: \(error)")
    }
    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // optionalメソッド
        // PiPが再生されるときに呼ばれる
        print("\(#function)")
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // optionalメソッド
        // PiPが再生された時に呼ばれる
    }
    
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // optionalメソッド
        // PiPが停止される時に呼ばれる
        print("\(#function)")
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // optionalメソッド
        // PiPが停止された時に呼ばれる
    }
    
}

extension ViewController: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
        // ユーザが再生の開始、または一時停止を要求したときに呼ばれる
        // playing: 再生しようとしているのか、止まろうとしているのか
        print("\(#function)")
        if playing {
            isPaused = false
            pipContentProvider.start()
        } else {
            isPaused = true
            pipContentProvider.stop()
        }
        //isPiPPlaying = playing
        print("playing: \(playing)")
    }
    
    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        // PiPに表示するコンテンツの再生時間を設定する（動画で使用する）
        print("\(#function)")
        return CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
        
        // 適当に時間を設定してみる
        // 時間を設定するとPiPのUIの15秒前、15秒後のボタンが使用できるようになる
        // かつ、停止マークが■ではなく⏸になる
        // let end = CMTime(seconds: 1005, preferredTimescale: 1)
        // let end = CMTimeMake(value: 200, timescale: 10)
        // return CMTimeRange(start: .zero, end: end)
    }
    
    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        // PiPのUIで停止マーク（■）を返すかどうか
        print("\(#function)")
        return isPaused
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {
        // PiPのウィンドウのサイズが変更された時に呼ばれる
        print("\(#function)")
        print(newRenderSize)
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) {
        // PiP内のボタンから前か後ろにスキップされた時に呼ばれる
        print("\(#function)")
    }
    
}
