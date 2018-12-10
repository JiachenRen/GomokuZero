//
//  BrowseCVC.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/9/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import UIKit

private let reuseIdentifier = "browse-cell"

class BrowseCVC: UICollectionViewController {

    lazy var games: [Game] = {Game.retrieve()}()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return games.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let gCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if let cell = gCell as? BrowseCell {
            cell.configure(games[indexPath.row])
            return cell
        }
        
        return gCell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let game = self.games[indexPath.row]
        
        let alert = UIAlertController(title: "\(game.name ?? "Untitled")", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Load", style: .default) { _ in
            sharedBoard.load(game.data!)
            ContainerVC.sharedInstance?.closeLeft()
        })
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) {[unowned self] _ in
            Game.ctx.delete(game)
            self.games.remove(at: indexPath.row)
            collectionView.reloadData()
            ContainerVC.sharedInstance?.alert(title: "Deleted \"\(game.name ?? "Untitled")\"")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default))
        
        present(alert, animated: true)
    }

}

extension BrowseCVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var itemSize = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        let oldWidth = itemSize.width
        let width = collectionView.bounds.width - 15 * 2
        itemSize.height *= width / oldWidth
        itemSize.width = width
        return itemSize
    }
}
