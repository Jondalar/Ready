/*
 TouchInputDevice.swift -- Touch on iPad Screen Input Device
 Copyright (C) 2019 Dieter Baron
 
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
import C64UIComponents
import Emulator

class TouchInputDevice: InputDevice {
    var controllerView: VirtualControlsView
    
    init(view: VirtualControlsView) {
        controllerView = view
        
        super.init(identifier: "Touch", name: "Touch", iconName: "Touch", priority: MachinePartLowPriority, supportedModes: [ .joystick, .lightGun, .lightPen, .mouse, .paddle ])
        
        controllerView.mouseView.delegate = self
        controllerView.mouseView.sensitivity = 1.25
        controllerView.joystickView.delegate = self
        controllerView.lightPenView.delegate = self
        controllerView.paddleView.delegate = self
    }
    
    override var currentMode: Controller.InputType {
        get { return controllerView.currentMode }
        set { controllerView.currentMode = newValue }
    }
}

extension TouchInputDevice: MouseViewDelegate {
    func mouseView(_ sender: MouseView, pressed button: Int) {
        delegate?.inputDevice(self, mouseButtonPressed: button)
    }
    
    func mouseView(_ sender: MouseView, released button: Int) {
        delegate?.inputDevice(self, mouseButtonReleased: button)
    }
    
    func mouseView(_ sender: MouseView, moved distance: CGPoint) {
        delegate?.inputDevice(self, mouseMoved: distance)
    }
}

extension TouchInputDevice: JoystickViewDelegate {
    func joystickView(_ sender: JoystickView, changed buttons: JoystickButtons) {
        delegate?.inputDevice(self, joystickChanged: buttons)
    }
}

extension TouchInputDevice: LightPenViewDelegate {
    func lightPenView(_ sender: LightPenView, changed position: CGPoint?, size: CGSize, button1: Bool, button2: Bool) {
        delegate?.inputDevice(self, lightPenMoved: position, size: size, button1: button1, button2: button2)
    }
}

extension TouchInputDevice: PaddleViewDelegate {
    func paddleView(_ sender: PaddleView, changedPosition: Double) {
        let adjustedPosition = max(0, min((changedPosition - 0.5) * max(1.05, deviceConfig.sensitivity) + 0.5, 1))

        delegate?.inputDevice(self, paddleMoved: adjustedPosition)
    }
    
    func paddleView(_ sender: PaddleView, changedButton: Bool) {
        delegate?.inputDevice(self, paddleChangedButton: changedButton)
    }
}
