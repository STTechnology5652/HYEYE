//
//  HYBaseCellType.swift
//  HYBaseUI
//
//  Created by stephen Li on 2025/3/12.
//

import Foundation

public protocol HYBaseCellModelInterface {
    var cellIdentifier: String { get }
}

public extension HYBaseCellModelInterface {
    func cellForIndexpath<T>(listView: T, indexPath: IndexPath) -> (UITableViewCell & HYBaseCellInterface)? where T: UITableView {
        let cellIdentifier = self.cellIdentifier
        let cell = listView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? (UITableViewCell & HYBaseCellInterface)
        cell?.configCell(cellModel: self)
        return cell
    }
}

public protocol HYBaseCellInterface {
    static var cellIdentifier: String { get }
    
    func configCell(cellModel: HYBaseCellModelInterface)
}

extension HYBaseCellInterface where Self: UITableViewCell {
    static var cellType: UITableViewCell.Type {
       return self
    }
}

public protocol HYBaseListViewInterface {}

public extension HYBaseListViewInterface {
    func registerCell<B, T>(_ registerView: B, cellType: T.Type) where B: UITableView, T: UITableViewCell & HYBaseCellInterface {
        registerView.register(cellType, forCellReuseIdentifier: String(describing: cellType.cellIdentifier))
    }
    
    func registerCell<B, T>(_ registerView: B, cellType: T.Type) where B: UICollectionView, T: UICollectionViewCell & HYBaseCellInterface {
        registerView.register(cellType, forCellWithReuseIdentifier: cellType.cellIdentifier)
    }
}
