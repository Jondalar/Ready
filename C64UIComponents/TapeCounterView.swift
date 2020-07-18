/*
 TapeCounterView.swift -- Tape Counter
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

@IBDesignable public class TapeCounterView: UIView {
    public var font: UIFont = UIFont.systemFont(ofSize: 17) {
        didSet { updateSize() }
    }
    @IBInspectable public var textColor: UIColor = UIColor.black {
        didSet { setNeedsDisplay() }
    }
    @IBInspectable public var counterColor: UIColor = UIColor.clear
    @IBInspectable public var counter: Double = 0 {
        didSet { updatePosition() }
    }
    @IBInspectable public var digits: Int = 3 {
        didSet {
            updateSize()
            updatePosition()
        }
    }
    @IBInspectable public var lineSpacing: CGFloat = 1 {
        didSet { updateSize() }
    }
    @IBInspectable public var charSpacing: CGFloat = 1 {
        didSet { updateSize() }
    }

    private var digitSize = CGSize(width: 0, height: 0)
    private var counterSize = CGSize(width: 0, height: 0)
    
    private struct Position {
        var digit: Int
        var fraction: CGFloat
    }
    
    private var positions = [Position]()
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        isOpaque = false
        updateSize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        updateSize()
    }
    
    override public var intrinsicContentSize: CGSize {
        return CGSize(width: counterSize.width + 2, height: counterSize.height + 2)
    }
    
    override public func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let counterRect = CGRect(x: bounds.midX - counterSize.width / 2, y: bounds.midY - counterSize.height / 2, width: counterSize.width, height: counterSize.height)
        
        context.setFillColor(counterColor.cgColor)
        context.fill(counterRect)
        
        context.clip(to: counterRect)

        var x = bounds.midX - (digitSize.width * (CGFloat(digits) - 1) * charSpacing + digitSize.width) / 2
        let y = bounds.midY - digitSize.height / 2
                
        for position in positions {
            let str = NSString(string: "\(position.digit)")
            var currentY = y - digitSize.height * position.fraction * lineSpacing
            str.draw(at: CGPoint(x: x, y: currentY), withAttributes: [.font: font, .foregroundColor: textColor])
            if (position.fraction != 0) {
                currentY += digitSize.height * lineSpacing
                let nextDigit = (position.digit + 1) % 10
                let str = NSString(string: "\(nextDigit)")
                str.draw(at: CGPoint(x: x, y: currentY), withAttributes: [.font: font, .foregroundColor: textColor])
            }
            x += digitSize.width * charSpacing
            
        }
        
        context.resetClip()
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(0.5)
        context.stroke(counterRect)
    }

    private func updatePosition() {
        var (_, fraction) = modf(counter)
        var integral = Int(counter)
        
        positions = [Position](repeating: Position(digit: 0, fraction: 0), count: digits)
        
        for place in (0 ..< digits).reversed() {
            let digit = integral % 10
            integral /= 10

            positions[place] = Position(digit: digit, fraction: CGFloat(fraction))

            if digit != 9 {
                fraction = 0
            }
        }
        
        setNeedsDisplay()
    }
    
    private func updateSize() {
        let str = NSString(stringLiteral: "0")
        
        digitSize = str.boundingRect(with: bounds.size, options: [], attributes: [.font: font], context: nil).size

        counterSize = CGSize(width: digitSize.width * CGFloat(digits) * charSpacing, height: digitSize.height * lineSpacing)
        invalidateIntrinsicContentSize()
        setNeedsDisplay()
    }
}
