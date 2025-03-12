//
//  HYLanguageCell.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/3/13.
//

import HYAllBase

struct HYLanguageCellModel: HYBaseCellModelInterface {
    var cellIdentifier: String = HYLanguageCell.cellIdentifier
    var language: HYResource.HYLanguage = .zh
    
    fileprivate func selectedStatus() -> Bool {
        HYResource.curLanguage() == language
    }
}

class HYLanguageCell: UITableViewCell, HYBaseCellInterface {
    static var cellIdentifier: String = "HYLanguageCell"
    
    func configCell(cellModel: any HYBaseUI.HYBaseCellModelInterface) {
        guard let cellModel = cellModel as? HYLanguageCellModel else { return }
        imgStatus.isHidden = cellModel.selectedStatus() == false
        labLanguage.text = cellModel.language.rawValue.lowercased()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var labLanguage: UILabel = {
        UILabel().then {
            $0.textColor = .black
            $0.font = .systemFont(ofSize: 17)
        }
    }()
    
    private lazy var imgStatus: UIImageView = {
        UIImageView().then {
            $0.contentMode = .scaleAspectFit
            $0.image = UIImage.hyImage(name: "ico_chosed")
        }
    }()
}

extension HYLanguageCell {
    private func setUpUI() {
        let backContainer: UIView = UIView()
        contentView.addSubview(backContainer)
        backContainer.addSubview(labLanguage)
        backContainer.addSubview(imgStatus)
        
        backContainer.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15))
        }
        
        labLanguage.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.lessThanOrEqualToSuperview()
        }
        
        imgStatus.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 15, height: 15))
        }
    }
}
