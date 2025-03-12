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
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
