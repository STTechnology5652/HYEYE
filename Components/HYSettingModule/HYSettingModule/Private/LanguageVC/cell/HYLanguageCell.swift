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
    
    func curLanguageStatus() -> Bool {
        let curLan = HYResource.curLanguage()
        return HYResource.curLanguage() == language
    }
}

class HYLanguageCell: UITableViewCell, HYBaseCellInterface {
    static var cellIdentifier: String = "HYLanguageCell"
    
    func configCell(cellModel: any HYBaseUI.HYBaseCellModelInterface) {
        guard let cellModel = cellModel as? HYLanguageCellModel else { return }
        
        let isCurLan = cellModel.curLanguageStatus()
        imgStatus.isHidden = (cellModel.curLanguageStatus() == false)
        labLanguage.text = cellModel.language.displayName()
        labLanguageOri.text = cellModel.language.lanName()
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
            $0.textColor = .c_text
            $0.numberOfLines = 0
            $0.font = UIFont.systemFont(ofSize: 18)
        }
    }()
    
    private lazy var labLanguageOri: UILabel = {
        UILabel().then {
            $0.textColor = .c_333333
            $0.numberOfLines = 0
            $0.font = UIFont.systemFont(ofSize: 14)
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
        backContainer.addSubview(labLanguageOri)
        backContainer.addSubview(imgStatus)
        
        backContainer.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15))
        }
        
        labLanguage.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview().offset(5)
            make.height.lessThanOrEqualToSuperview()
        }
        
        labLanguageOri.snp.makeConstraints { make in
            make.top.equalTo(labLanguage.snp_bottom).offset(2)
            make.left.equalToSuperview()
            make.bottom.equalToSuperview().offset(-5)
            make.height.equalTo(labLanguage).multipliedBy(0.8)
        }
        
        imgStatus.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 15, height: 15))
        }
        
        let line = UIView()
        line.backgroundColor = .c_333333.withAlphaComponent(0.5)
        contentView.addSubview(line)
        line.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
            make.width.centerX.equalTo(backContainer)
        }
    }
}
