//
//  ContainerVC.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/4/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

class ContainerVC: SlideMenuController {

    static var sharedInstance: ContainerVC?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ContainerVC.sharedInstance = self
    }
    
    override func awakeFromNib() {
        let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let boardVC = storyBoard.instantiateViewController(withIdentifier: "board")
        let configVC = storyBoard.instantiateViewController(withIdentifier: "configuration")
        SlideMenuOptions.leftViewWidth = 300
        mainViewController = boardVC
        leftViewController = configVC
        
        observe(UIDevice.orientationDidChangeNotification, #selector(deviceOrientationDidChange))
        super.awakeFromNib()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @objc func deviceOrientationDidChange() {
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            changeLeftViewWidth(400)
        case .portrait:
            changeLeftViewWidth(300)
        default: return
        }
    }

}
