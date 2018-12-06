//
//  Utility.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/6/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func alert(title: String, msg: String? = nil, dismissAfter interval: TimeInterval = 2) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue(label: "alert delay queue").async {
            Thread.sleep(forTimeInterval: interval)
            DispatchQueue.main.async {
                alert.dismiss(animated: true)
            }
        }
    }
}
