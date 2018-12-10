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
        
        if UserDefaults.retrieve(key: "completed-tutorial") == nil {
            DispatchQueue(label: "tutorial").async {[unowned self] in
                Thread.sleep(forTimeInterval: 2)
                DispatchQueue.main.sync {
                    self.runTutorial()
                }
            }
            
        }
        
        ContainerVC.sharedInstance = self
    }
    
    private func runTutorial() {
        self.tutorialAlert("Swipe from the left edge of the screen to reveal menu.") {
            self.tutorialAlert("Tap with two fingers to undo; tap with three fingers to redo.") {
                self.tutorialAlert("Pinch & pan to resize and move the board.") {
                    self.alert(title: "Enjoy!", msg: "Developed w/ love by Jiachen Ren")
                    UserDefaults.save(obj: true, key: "completed-tutorial")
                }
            }
        }
    }
    
    private func tutorialAlert(_ msg: String, handler: @escaping () -> Void) {
        let alert = UIAlertController(title: "Tutorial", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) {_ in
            handler()
        })
        present(alert, animated: true)
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
