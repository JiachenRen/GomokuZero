//
//  AlgorithmVC.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/4/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

class AlgorithmVC: UIViewController, UIPickerViewDelegate {
    
    @IBOutlet weak var pickerView: UIPickerView!
    var segueConfig: SegueConfig!
    var completion: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
        pickerView.selectRow(segueConfig.selectedIdx, inComponent: 0, animated: false)
        
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        segueConfig.selectedIdx = row
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        completion?()
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

extension AlgorithmVC: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return segueConfig.subtitles.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return segueConfig.subtitles[row]
    }
    
}
