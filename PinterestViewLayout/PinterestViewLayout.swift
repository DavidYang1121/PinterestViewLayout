//
//  PinterestViewLayout.swift
//  Character Collector
//
//  Created by DavidYang on 2017/7/18.
//  Copyright © 2017年 DavidYang, LLC. All rights reserved.
//

import UIKit
protocol  PinterestViewLayoutDelegate: NSObjectProtocol {
    /// return custom cell height
    func collectionView(_ collectionView: UICollectionView, heightForCellAt indexPath: IndexPath, with width: CGFloat) -> CGFloat
}


class PinterestViewLayout: UICollectionViewLayout {
    var numberOfColumns: Int = 0
    var cellPadding: CGFloat = 0
    weak var delegate: PinterestViewLayoutDelegate!
    private var layoutAttributes: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0
    private var contentWidth: CGFloat {
        get {
            let contentInset = collectionView!.contentInset
            return collectionView!.frame.width - contentInset.left - contentInset.right
        }
    }
    
    override func prepare() {
        
        layoutAttributes.removeAll()
        //1. setup X and Y offset array
        let columnWidth: CGFloat = contentWidth / CGFloat(numberOfColumns)
        var xOffsets: [CGFloat] = []
        for item in 0..<numberOfColumns {
            xOffsets.append(CGFloat(item) * columnWidth)
        }
        var yOffsets = [CGFloat](repeating: 0 , count: numberOfColumns)
        var column = 0
        
        //2.add layoutAttributes
        for item in 0..<collectionView!.numberOfItems(inSection: 0) {
            let indexPath = IndexPath.init(row: item, section: 0)
            let width = columnWidth - (cellPadding * 2)
            let height = delegate.collectionView(collectionView!, heightForCellAt: indexPath, with: width) + cellPadding * 2
            
            //init frame with padding
            let cellFrame = CGRect.init(x: xOffsets[column], y: yOffsets[column], width: columnWidth , height: height)
            
            //Remove the padding
            let insetFrame = cellFrame.insetBy(dx: cellPadding, dy: cellPadding)
            let attributes = UICollectionViewLayoutAttributes.init(forCellWith: indexPath)
            attributes.frame = insetFrame
            layoutAttributes.append(attributes)
            
            // update contntHeight
            contentHeight = max(contentHeight, cellFrame.maxY)
            
            // update column
            yOffsets[column] = yOffsets[column] + height
            column = column >= (numberOfColumns - 1) ? 0 : column + 1
        }
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize.init(width: contentWidth, height: contentHeight)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributesInRect: [UICollectionViewLayoutAttributes] = []
        for attributes in layoutAttributes {
            if attributes.frame.intersects(rect) {
                layoutAttributesInRect.append(attributes)
            }
        }
        return layoutAttributesInRect
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributes[indexPath.item]
    }
}
