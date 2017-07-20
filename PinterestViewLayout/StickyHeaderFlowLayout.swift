//
//  StickyHeaderFlowLayout.swift
//  Buyer
//
//  Created by DavidYang on 2017/7/20.
//  Copyright © 2017年 ymatou. All rights reserved.
//

import UIKit

class StickyHeaderFlowLayout: UICollectionViewFlowLayout {

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let layoutAttributes = super.layoutAttributesForElements(in: rect), let collectionView = self.collectionView else {
            return nil
        }
        var newAttributes: [UICollectionViewLayoutAttributes] = []
        let noneHeaderSections = NSMutableIndexSet()
        newAttributes.append(contentsOf: layoutAttributes)
        for attributes in layoutAttributes {
            if attributes.representedElementCategory == .cell {
                noneHeaderSections.add(attributes.indexPath.section)
            }
        }
        
        for attributes in layoutAttributes {
            if attributes.representedElementKind == UICollectionElementKindSectionHeader {
                noneHeaderSections.remove(attributes.indexPath.section)
            }
        }
        
        for section in noneHeaderSections {
            if let headerAttributes = self.layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: IndexPath.init(row: 0, section: section)) {
                if headerAttributes.frame.width > 0 && headerAttributes.frame.height > 0 {
                    newAttributes.append(headerAttributes)
                }
            }
        }
        
        for attributes in newAttributes {
            if attributes.representedElementKind == UICollectionElementKindSectionHeader {
                let conntentOffset = collectionView.contentOffset
                var originInCollectionView = CGPoint.init(x: attributes.frame.origin.x - conntentOffset.x, y: attributes.frame.origin.y - conntentOffset.y)
                originInCollectionView.y -= collectionView.contentInset.top
                var frame = attributes.frame
                if originInCollectionView.y < 0 {
                    frame.origin.y -= originInCollectionView.y
                }
                let numberOfSections = collectionView.numberOfSections
                if numberOfSections > attributes.indexPath.section + 1 {
                    if let nextHeaderAttributes = self.layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: IndexPath.init(row: 0, section: attributes.indexPath.section + 1)) {
                        if frame.maxY > nextHeaderAttributes.frame.origin.y {
                            frame.origin.y = nextHeaderAttributes.frame.origin.y - frame.height
                        }
                    }
                }
                attributes.frame = frame
                attributes.zIndex = 1024
            }
        }
        return newAttributes
    }
}
