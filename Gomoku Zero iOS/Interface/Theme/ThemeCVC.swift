//
//  ThemeCVC.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/6/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

private let reuseIdentifier = "theme-cell"

class ThemeCVC: UICollectionViewController {
    
    let themes: [UIImage] = "abcdef".map {"board_\($0)"}
        .map {UIImage(named: $0)!}

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themes.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let gCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let cell = gCell as? ThemeCell else {
            return gCell
        }
        cell.imageView.image = themes[indexPath.row]
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let vc = BoardViewController.sharedInstance {
            vc.boardImgView.image = themes[indexPath.row]
        }
        ContainerVC.sharedInstance?.closeLeft()
        collectionView.deselectItem(at: indexPath, animated: true)
        alert(title: "Theme Updated", dismissAfter: 1)
    }
    
}

extension ThemeCVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 15 * 2
        let size = CGSize(width: width, height: width)
        return size
    }
}
