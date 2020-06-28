/*
 GridView.swift -- arrange subviews in fixed grid
 Copyright (C) 2020 Dieter Baron
 
 This file is part of C64, a Commodore 64 emulator for iOS, based on VICE.
 The authors can be contacted at <c64@spiderlab.at>
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
 02111-1307  USA.
 */

import UIKit

@IBDesignable class GridView: UIView {
    private struct SubViewInfo {
        var view: UIView
        var position: CGRect
    }
    @IBInspectable var margin: CGFloat = 8 { didSet { updateLayout() } }
    @IBInspectable var horizontalGap: CGFloat = 8 { didSet { updateLayout() } }
    @IBInspectable var verticalGap: CGFloat = 8 { didSet { updateLayout() } }
    @IBInspectable var cellWidth: CGFloat = 72 { didSet { updateLayout() } }
    @IBInspectable var cellHeight: CGFloat = 72 { didSet { updateLayout() } }

    private var subviewInfos = [SubViewInfo]()
    
    func add(subview: UIView, at position: CGRect) {
        
    }
    
    func remove(subview: UIView) {
        
    }
    
    private func updateLayout() {
        
    }
}
