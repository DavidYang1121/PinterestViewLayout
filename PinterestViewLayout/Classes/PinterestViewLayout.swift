//
//  PinterestViewLayout.swift
//  Character Collector
//
//  Created by DavidYang on 2017/7/18.
//  Copyright © 2017年 DavidYang, LLC. All rights reserved.
//

import UIKit

class PinterestViewLayoutAttributes {
    var header: UICollectionViewLayoutAttributes?
    var footer: UICollectionViewLayoutAttributes?
    var items: [UICollectionViewLayoutAttributes] = []
    var headerIsSticky: Bool = false
}

@objc protocol  PinterestViewLayoutDelegate: UICollectionViewDelegate {
    
    /// return numberOfColoums
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, numberOfColumnsAt section: Int) -> Int
    
    /// return custom cell size, item's width should be equal in the same row
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    
    /// return minimumLineSpacing
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    
    /// return minimumInteritemSpacing
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
    
    /// return insetForSection
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    
    /// return referenceSizeForFooter
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize
    
    /// return referenceSizeForHeader
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize
    
    // return iSStickyHeader
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, headerIsStickyInSection section: Int) -> Bool
}


class PinterestViewLayout: UICollectionViewLayout {
    
    weak var delegate: PinterestViewLayoutDelegate?
    fileprivate var layoutAttributes: [PinterestViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0
    private var contentWidth: CGFloat {
        get {
            guard let collectionView = self.collectionView else {
                return 0
            }
            let contentInset = collectionView.contentInset
            return collectionView.frame.width - contentInset.left - contentInset.right
        }
    }
    
    override func prepare() {
        super.prepare()
        guard let delegate = self.delegate, let collectionView = self.collectionView else {
            return
        }
        
        //0.reset data
        layoutAttributes.removeAll()
        contentHeight = 0
        
        //1. setup Y offset
        var offsetY: CGFloat = 0
        
        //2.add layoutAttributes
        for section in 0..<collectionView.numberOfSections {
            
            //get custom layout info
            let lineSpacing = delegate.collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAt: section) ?? 0
            let interitemSpacing = delegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: section) ?? 0
            let inset = delegate.collectionView?(collectionView, layout: self, insetForSectionAt: section) ?? .zero
            let isSticky = delegate.collectionView?(collectionView, layout: self, headerIsStickyInSection: section) ?? false
            
            // init custom attributes
            let sectionAttributes = PinterestViewLayoutAttributes()
            
            //setup headerAttributes
            let headerSize = delegate.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section) ?? .zero
            let header = UICollectionViewLayoutAttributes.init(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, with: IndexPath.init(row: 0, section: section))
            if headerSize != .zero {
                let headerFrame = CGRect.init(x: 0, y: offsetY, width: headerSize.width, height: headerSize.height)
                header.frame = headerFrame
                sectionAttributes.header = header
            }
            
            sectionAttributes.headerIsSticky = isSticky
            
            //update offsetY
            offsetY += headerSize.height + inset.top
            
            //setup section x and y offset array
            let numberOfColumns = delegate.collectionView(collectionView, layout: self, numberOfColumnsAt: section)
            var yOffsets = [CGFloat](repeating: offsetY , count: numberOfColumns)
            var xOffset: CGFloat = inset.left
            
            for item in 0..<collectionView.numberOfItems(inSection: section) where numberOfColumns > 0 {
                
                let indexPath = IndexPath.init(row: item, section: section)
                let itemSize = delegate.collectionView(collectionView, layout: self, sizeForItemAt: indexPath)
                
                var renderColumn = 0
                var shortestOffset: CGFloat = 0
                if let first = yOffsets.first {
                    shortestOffset = first
                }
                for index in 1 ..< yOffsets.count {
                    if yOffsets[index] < shortestOffset {
                        shortestOffset = yOffsets[index]
                        renderColumn = index
                    }
                }
                
                xOffset = inset.left + (itemSize.width + interitemSpacing) * CGFloat(renderColumn)
                
                //init frame with padding
                let itemFrame = CGRect.init(x: xOffset, y: yOffsets[renderColumn], width: itemSize.width , height: itemSize.height)
                
                //add item attributes
                let attributes = UICollectionViewLayoutAttributes.init(forCellWith: indexPath)
                attributes.frame = itemFrame
                sectionAttributes.items.append(attributes)
                
                // update column
                yOffsets[renderColumn] = yOffsets[renderColumn] + itemSize.height + lineSpacing
                
                for offsets in yOffsets {
                    offsetY = max(offsetY, offsets)
                }
            }
            
            var tempLineSpacing: CGFloat = lineSpacing
            if collectionView.numberOfItems(inSection: section) == 0 {
                tempLineSpacing = 0
            }
            offsetY -= tempLineSpacing
            
            //setup footerAttributes
            let footerSize = delegate.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section) ?? .zero
            let footer = UICollectionViewLayoutAttributes.init(forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, with: IndexPath.init(row: 0, section: section))
            if footerSize == .zero {
                footer.frame = .zero
            } else {
                let footerFrame = CGRect.init(x: 0, y: offsetY + inset.bottom, width: footerSize.width, height: footerSize.height)
                footer.frame = footerFrame
            }
            sectionAttributes.footer = footer
            
            //update offsetY
            offsetY += footerSize.height + inset.bottom
            
            // append attributes
            layoutAttributes.append(sectionAttributes)
            
            // update contntHeight
            contentHeight = max(contentHeight, offsetY)
        }
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize.init(width: contentWidth, height: contentHeight)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributesInRect: [UICollectionViewLayoutAttributes] = []
        for layout in layoutAttributes {
            //append headerAttributes
            if let attributes = layout.header, attributes.frame.intersects(rect) {
                layoutAttributesInRect.append(attributes)
            }
            
            //append itemAttributes
            for attributes in layout.items {
                if attributes.frame.intersects(rect) {
                    layoutAttributesInRect.append(attributes)
                }
            }
            
            //append footerAttributes
            if let attributes = layout.footer, attributes.frame.intersects(rect) {
                layoutAttributesInRect.append(attributes)
            }
        }
        return layoutAttributesInRect
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if indexPath.section < layoutAttributes.count {
            if elementKind == UICollectionElementKindSectionHeader {
                return layoutAttributes[indexPath.section].header
            } else {
                return layoutAttributes[indexPath.section].footer
            }
        }
        return nil
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if indexPath.section < layoutAttributes.count {
            let attributes = layoutAttributes[indexPath.section]
            if indexPath.item < attributes.items.count {
                return attributes.items[indexPath.item]
            }
        }
        return nil
    }
}

class StickyHeaderPinterestViewLayout: PinterestViewLayout {
    var navbarHeight: CGFloat {
        get {
            if #available(iOS 11.0, *) {
                if let delegate = UIApplication.shared.delegate, let window = delegate.window, let bottom = window?.safeAreaInsets.bottom, bottom > 0 {
                    return 88
                }
            }
            return 64
        }
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let oldLayoutAttributes = super.layoutAttributesForElements(in: rect), let collectionView = self.collectionView else {
            return nil
        }
        var newAttributes: [UICollectionViewLayoutAttributes] = []
        let noneHeaderSections = NSMutableIndexSet()
        newAttributes.append(contentsOf: oldLayoutAttributes)
        for attributes in oldLayoutAttributes {
            if attributes.representedElementCategory == .cell {
                noneHeaderSections.add(attributes.indexPath.section)
            }
        }
        
        for attributes in oldLayoutAttributes {
            if attributes.representedElementKind == UICollectionElementKindSectionHeader {
                noneHeaderSections.remove(attributes.indexPath.section)
            }
        }
        
        for section in noneHeaderSections {
            if let headerAttributes = self.layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: IndexPath.init(row: 0, section: section)) {
                var isSticky = false
                if section < self.layoutAttributes.count {
                    isSticky = self.layoutAttributes[section].headerIsSticky
                }
                if headerAttributes.frame.width > 0 && headerAttributes.frame.height > 0 && isSticky {
                    newAttributes.append(headerAttributes)
                }
            }
        }
        
        for attributes in newAttributes {
            var isSticky = false
            if attributes.indexPath.section < self.layoutAttributes.count {
                isSticky = self.layoutAttributes[attributes.indexPath.section].headerIsSticky
            }
            if attributes.representedElementKind == UICollectionElementKindSectionHeader && isSticky {
                let conntentOffset = collectionView.contentOffset
                var originInCollectionView = CGPoint.init(x: attributes.frame.origin.x - conntentOffset.x, y: attributes.frame.origin.y - conntentOffset.y - navbarHeight)
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
