//
//  LeftNavController.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

class LeftNavController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Remove the 1 pixel separator at bottom of nav bar.
        navigationBar.shadowImage = UIImage()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
