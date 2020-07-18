/*
 DriveTrackView.swift -- Disk Drive Track View
 Copyright (C) 2019 Dieter Baron
 
 This file is part of Ready, a home computer emulator for iPad.
 The authors can be contacted at <ready@tpau.group>.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 2. The names of the authors may not be used to endorse or promote
 products derived from this software without specific prior
 written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS
 OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit

@IBDesignable public class DriveTrackView: UIView {
    @IBInspectable public var tracks: Int = 35 {
        didSet {
            updateDiskLayout()
            setNeedsDisplay()
        }
    }
    
    @IBInspectable public var isDoubleSided: Bool = false {
        didSet {
            updateDiskLayout()
            setNeedsDisplay()
        }
    }

    @IBInspectable public var currentTrack: Double = 1 {
        didSet {
            updatePosition()
            setNeedsDisplay()
        }
    }
    
    @IBInspectable public var color: UIColor = UIColor.black {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var headWidth: CGFloat = 8.0
    
    private var effectiveTracks: CGFloat = 0.0
    private var currentPosition: CGFloat = 0.0
    private var onSide1: Bool = false
    
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        isOpaque = false
        updateDiskLayout()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        updateDiskLayout()
    }
    
    override public func draw(_ rectXXX: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setStrokeColor(color.cgColor)
        context.setFillColor(color.cgColor)
        context.setLineWidth(1.0)
        
        context.move(to: CGPoint(x: bounds.minX, y: bounds.height / 2.0))
        context.addLine(to: CGPoint(x: bounds.maxX, y: bounds.height / 2.0))
        context.strokePath()
        
        let headPosition = bounds.minX + headWidth / 2 + currentPosition * (bounds.width - headWidth)
        
        if isDoubleSided {
            addHeadPath(at: headPosition, y: bounds.height / 2.0, above: true, in: context)
            if onSide1 {
                context.strokePath()
            }
            else {
                context.fillPath()
            }
        }
        addHeadPath(at: headPosition, y: bounds.height / 2.0, above: false, in: context)
        if onSide1 {
            context.fillPath()
        }
        else {
            context.strokePath()
        }
    }
    
    private func addHeadPath(at x: CGFloat, y: CGFloat, above: Bool, in context: CGContext) {
        let ySign: CGFloat = above ? -1.0 : 1.0
        
        let height = sqrt(3.0) / 2.0 * headWidth
        
        context.move(to: CGPoint(x: x, y: y + 2.0 * ySign))
        context.addLine(to: CGPoint(x: x - headWidth / 2.0, y: y + (2.0 + height) * ySign))
        context.addLine(to: CGPoint(x: x + headWidth / 2.0, y: y + (2.0 + height) * ySign))
        context.closePath()
    }
    
    private func updateDiskLayout() {
        if isDoubleSided {
            effectiveTracks = CGFloat(tracks) / 2.0
        }
        else {
            effectiveTracks = CGFloat(tracks)
        }
        updatePosition()
    }
    
    private func updatePosition() {
        guard effectiveTracks > 0 else { return }
        
        var effectiveCurrentTrack = max(0, min(CGFloat(currentTrack - 1), CGFloat(tracks - 1)))
        
        onSide1 = effectiveCurrentTrack < effectiveTracks
        
        if isDoubleSided {
            effectiveCurrentTrack = remainder(effectiveCurrentTrack, effectiveTracks)
            if (effectiveCurrentTrack < 0) {
                effectiveCurrentTrack += effectiveTracks
            }
        }
        
        if (effectiveTracks == 1 || effectiveCurrentTrack < 0) {
            currentPosition = 0
        }
        else {
            currentPosition = effectiveCurrentTrack / (effectiveTracks - 1)
        }
    }
}
