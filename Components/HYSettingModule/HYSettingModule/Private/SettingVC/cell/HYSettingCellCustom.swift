//
//  HYSettingCellCustom.swift
//  HYSettingModule
//
//  Created by stephen Li on 2025/3/9.
//

import UIKit
import HYAllBase
import STRxInOutPutProtocol

extension HYSettingCellCustom {
    static var cellIdentifier: String {
        return "HYSettingCellCustom"
    }
    
    func configCell(cellModel: HYBaseCellModelInterface) {
        guard let dataModel = cellModel as? HYSettingCellModelCustom else { return }
        
        self.dataModel = dataModel
        labTitle.text = dataModel.title
        labSubTitle.text = dataModel.subTitle
        labSubTitle.isHidden = dataModel.subTitle?.isEmpty ?? true
        imgArrow.isHidden = dataModel.hideArrow
        labDes.text = dataModel.desText
        labDesBack.isHidden = dataModel.desText?.isEmpty ?? true
        
        bindData()
    }
}

class HYSettingCellCustom: UITableViewCell, HYBaseCellInterface, STMvvmProtocol  {
    func bindData() {
        disposeBag = DisposeBag()
        let input = HYSettingCellModelCustom.Input()
        let outPut = vm.transformInput(input)
    }
    
    var disposeBag = DisposeBag()
    var vm = HYSettingCellModelCustom()
    var dataModel: HYSettingCellModelCustom?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpUI()
    }
    
    private func setUpUI() {
        selectionStyle = .none
        let back = UIView()
        contentView.addSubview(back)
        let stackH = UIStackView()
        stackH.spacing = 5
        stackH.axis = .horizontal
        back.addSubview(stackH)
        
        let stackV = UIStackView(arrangedSubviews: [labTitle, labSubTitle])
        stackV.axis = .vertical
        stackV.spacing = 5
        
        stackH.addArrangedSubview(stackV)
        
        let labDesBack = UIView()
        labDesBack.addSubview(labDes)
        stackH.addArrangedSubview(labDesBack)
        
        let arrowBack = UIView()
        stackH.addArrangedSubview(arrowBack)
        arrowBack.addSubview(imgArrow)
        
        back.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15))
            make.height.greaterThanOrEqualTo(40)
        }
        
        stackH.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stackV.snp.makeConstraints { make in
            make.width.greaterThanOrEqualToSuperview().multipliedBy(0.5)
        }
        
        labDes.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        imgArrow.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.size.equalTo(CGSize(width: 10, height: 15))
            make.centerY.equalToSuperview()
        }
        
        let line = UIView()
        contentView.addSubview(line)
        line.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().offset(-30)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        line.backgroundColor = .c_1F2937.withAlphaComponent(0.5)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been impemented")
    }
    
    private lazy var labTitle: UILabel = {
        UILabel().then {
            $0.textColor = .c_text
            $0.numberOfLines = 0
            $0.font = UIFont.systemFont(ofSize: 18)
        }
    }()
    
    private lazy var labSubTitle: UILabel = {
        UILabel().then {
            $0.textColor = .c_333333
            $0.numberOfLines = 0
            $0.font = UIFont.systemFont(ofSize: 14)
        }
    }()
    
    private lazy var labDesBack: UIView = { UIView() }()
    private lazy var labDes: UILabel = {
        UILabel().then {
            $0.textColor = .c_text_warning
            $0.numberOfLines = 0
            $0.font = UIFont.systemFont(ofSize: 14)
        }
    }()
    
    private lazy var imgArrow: UIImageView = {
        UIImageView().then {
            $0.image = UIImage.hyImage(name: "ico_arrow_right")
        }
    }()
}
