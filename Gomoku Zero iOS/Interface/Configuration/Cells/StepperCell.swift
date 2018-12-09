//
//  StepperCell.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/4/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

class StepperCell: UITableViewCell, ConfigCellProtocol {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var textField: UITextField!
    var stepperConfig: StepperConfig!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func stepperValueChanged(_ sender: Any) {
        let val = Int(stepper.value)
        textField.text = "\(val)"
        stepperConfig.val = Double(val)
        stepperConfig.handler?(val)
    }
    
    @IBAction func textFieldEditingDidEnd(_ sender: Any) {
        if let value = Double(textField.text!) {
            stepper.value = Double(value)
            stepperConfig.val = value
        }
        textField.resignFirstResponder()
    }
    
    func configure(_ cellConfig: CellConfig) {
        stepperConfig = (cellConfig as! StepperConfig)
        title.text = stepperConfig.title
        stepper.minimumValue = stepperConfig.min
        stepper.maximumValue = stepperConfig.max
        stepper.value = stepperConfig.val
        textField.text = "\(Int(stepperConfig.val))"
    }
    
}
