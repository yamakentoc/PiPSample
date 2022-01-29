//
//  UIView+Utility.swift
//  PiPSample
//
//  Created by 山口賢登 on 2022/01/17.
//

import UIKit

extension UIView {
    
    // 画像に変換する
    func convertToUIImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        // クロージャ内の描画処理に従って画像を作成する
        let image = renderer.image { context in
            // View内の描画をcontextに複写する
            layer.render(in: context.cgContext)
        }
        return image
    }
    
}
