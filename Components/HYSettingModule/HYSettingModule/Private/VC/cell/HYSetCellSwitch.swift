//
//  HYSetCellSwitch.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/3/12.
//

import UIKit
import HYAllBase
import HYBaseUI

extension HYSetCellSwitch: HYBaseCellInterface {
    static var cellIdentifier: String {
        return "HYSetCellSwitch"
    }
    
    func configCell(cellModel: HYBaseCellModelInterface) {
        guard let cellModel = cellModel as? HYSetCellModelSwitch else { return }
    }
}

class HYSetCellSwitch: UITableViewCell {
}
