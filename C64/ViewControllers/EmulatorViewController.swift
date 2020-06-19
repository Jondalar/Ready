/*
 EmulatorViewController.swift
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
import AVFoundation
import GameController
import MobileCoreServices

import C64UIComponents
import Emulator
import Vice_C64
import ViceVIC20

class EmulatorViewController: FullScreenViewController, KeyboardViewDelegate, SeguePreparer, UIGestureRecognizerDelegate {
    enum SegueType: String {
        case borderMode
        case diskDrive8Control
        case diskDrive9Control
        case diskDrive10Control
        case diskDrive11Control
        case inputMapping
        case machineParts
        case singularAdapterMode
        
        var unit: Int? {
            switch self {
            case .diskDrive8Control:
                return 8
            case .diskDrive9Control:
                return 9
            case .diskDrive10Control:
                return 10
            case .diskDrive11Control:
                return 11
            default:
                return nil
            }
        }
    }
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var keyboardView: KeyboardView!
    @IBOutlet weak var keyboardButton: UIBarButtonItem!
    @IBOutlet weak var freezeButton: UIBarButtonItem!
    @IBOutlet weak var tapeStatus: TapeStatusView!
    @IBOutlet var drive8Status: DriveStatusView!
    @IBOutlet var drive9Status: DriveStatusView!
    @IBOutlet var drive10Status: DriveStatusView!
    @IBOutlet var drive11Status: DriveStatusView!
    @IBOutlet var singularStatus: SingularAdapterStatusView!
    @IBOutlet weak var statusBarView: UIView!
    @IBOutlet weak var safeInsetView: UIView!
    @IBOutlet weak var screenshotFlashView: UIView!
    @IBOutlet weak var safeInsetHeight: NSLayoutConstraint!
    @IBOutlet weak var mouseJoystickButton: UIBarButtonItem!
    @IBOutlet weak var controllerView: VirtualControlsView!
    @IBOutlet weak var saveTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var fullscreenTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var controllerViewTopConstraint: NSLayoutConstraint!
    
    private var driveStatus = [DriveStatusView]()
    
    var gameViewItem: GameViewItem?
    var toolsMode = false
    var selectedMedia: MediaItem?
    var emulator: Emulator?
    var running = false
    var machine = Machine()
    
    private var controllers = [GCController : MfiInputDevice]()
    
    private var keyPressTranslator: KeyPressTranslator?

    struct Binding {
        var key: Key
        var shift: Bool
        var control: Bool
        var commodore: Bool
        
        init(key: Key, shift: Bool = false, control: Bool = false, commodore: Bool = false) {
            self.key = key
            self.shift = shift
            self.control = control
            self.commodore = commodore
        }
    }

    struct KeyBinding {
        var input: String
        var modifierFlags: UIKeyModifierFlags
        var title: String?
        var binding: Binding
        
        init(input: String, modifierFlags: UIKeyModifierFlags = [], title: String? = nil, binding: Binding? = nil) {
            self.input = input
            self.modifierFlags = modifierFlags
            self.title = title
            if let binding = binding {
                self.binding = binding
            }
            else {
                self.binding = Binding(key: .Char(input.first!))
            }
        }
    }

    let bindings: [KeyBinding] = [
        KeyBinding(input: "1", modifierFlags: [.command], title: "F1", binding: Binding(key: .F1)),
        KeyBinding(input: "2", modifierFlags: [.command], title: "F2", binding: Binding(key: .F1, shift: true)),
        KeyBinding(input: "3", modifierFlags: [.command], title: "F3", binding: Binding(key: .F3)),
        KeyBinding(input: "4", modifierFlags: [.command], title: "F4", binding: Binding(key: .F3, shift: true)),
        KeyBinding(input: "5", modifierFlags: [.command], title: "F5", binding: Binding(key: .F5)),
        KeyBinding(input: "6", modifierFlags: [.command], title: "F6", binding: Binding(key: .F5, shift: true)),
        KeyBinding(input: "7", modifierFlags: [.command], title: "F7", binding: Binding(key: .F7)),
        KeyBinding(input: "8", modifierFlags: [.command], title: "F8", binding: Binding(key: .F7, shift: true)),
        
        KeyBinding(input: "\t", title: "Run/Stop", binding: Binding(key: .RunStop)),
        KeyBinding(input: "\t", modifierFlags: [.shift], binding: Binding(key: .RunStop, shift: true)),
        KeyBinding(input: "\\", title: "Restore", binding: Binding(key: .Restore)),
        KeyBinding(input: "`", title: "←", binding: Binding(key: .ArrowLeft)),
        KeyBinding(input: "~", binding: Binding(key: .ArrowLeft, shift: true)),

//        KeyBinding(input: "\u{f704}", binding: Binding(key: .F1)), // doesn't work
//        KeyBinding(input: "7", modifierFlags: [.numericPad], binding: Binding(key: .F7)),

        KeyBinding(input: "1"),
        KeyBinding(input: "2"),
        KeyBinding(input: "3"),
        KeyBinding(input: "4"),
        KeyBinding(input: "5"),
        KeyBinding(input: "6"),
        KeyBinding(input: "7"),
        KeyBinding(input: "8"),
        KeyBinding(input: "9"),
        KeyBinding(input: "0"),
        KeyBinding(input: "+"),
        KeyBinding(input: "-"),
        KeyBinding(input: "3", modifierFlags: [.alternate], title: "£", binding: Binding(key: .Char("£"))),
        KeyBinding(input: "\u{8}", binding: Binding(key: .InsertDelete)),
        
        KeyBinding(input: "!", binding: Binding(key: .Char("1"), shift: true)),
        KeyBinding(input: "\"", binding: Binding(key: .Char("2"), shift: true)),
        KeyBinding(input: "#", binding: Binding(key: .Char("3"), shift: true)),
        KeyBinding(input: "$", binding: Binding(key: .Char("4"), shift: true)),
        KeyBinding(input: "%", binding: Binding(key: .Char("5"), shift: true)),
        KeyBinding(input: "&", binding: Binding(key: .Char("6"), shift: true)),
        KeyBinding(input: "'", binding: Binding(key: .Char("7"), shift: true)),
        KeyBinding(input: "(", binding: Binding(key: .Char("8"), shift: true)),
        KeyBinding(input: ")", binding: Binding(key: .Char("9"), shift: true)),

        KeyBinding(input: "1", modifierFlags: [.control], binding: Binding(key: .Char("1"), control: true)),
        KeyBinding(input: "2", modifierFlags: [.control], binding: Binding(key: .Char("2"), control: true)),
        KeyBinding(input: "3", modifierFlags: [.control], binding: Binding(key: .Char("3"), control: true)),
        KeyBinding(input: "4", modifierFlags: [.control], binding: Binding(key: .Char("4"), control: true)),
        KeyBinding(input: "5", modifierFlags: [.control], binding: Binding(key: .Char("5"), control: true)),
        KeyBinding(input: "6", modifierFlags: [.control], binding: Binding(key: .Char("6"), control: true)),
        KeyBinding(input: "7", modifierFlags: [.control], binding: Binding(key: .Char("7"), control: true)),
        KeyBinding(input: "8", modifierFlags: [.control], binding: Binding(key: .Char("8"), control: true)),
        KeyBinding(input: "9", modifierFlags: [.control], binding: Binding(key: .Char("9"), control: true)),
        KeyBinding(input: "0", modifierFlags: [.control], binding: Binding(key: .Char("0"), control: true)),

        KeyBinding(input: "1", modifierFlags: [.alphaShift], binding: Binding(key: .Char("1"), commodore: true)),
        KeyBinding(input: "2", modifierFlags: [.alphaShift], binding: Binding(key: .Char("2"), commodore: true)),
        KeyBinding(input: "3", modifierFlags: [.alphaShift], binding: Binding(key: .Char("3"), commodore: true)),
        KeyBinding(input: "4", modifierFlags: [.alphaShift], binding: Binding(key: .Char("4"), commodore: true)),
        KeyBinding(input: "5", modifierFlags: [.alphaShift], binding: Binding(key: .Char("5"), commodore: true)),
        KeyBinding(input: "6", modifierFlags: [.alphaShift], binding: Binding(key: .Char("6"), commodore: true)),
        KeyBinding(input: "7", modifierFlags: [.alphaShift], binding: Binding(key: .Char("7"), commodore: true)),
        KeyBinding(input: "8", modifierFlags: [.alphaShift], binding: Binding(key: .Char("8"), commodore: true)),

        KeyBinding(input: "@"),
        KeyBinding(input: "*"),
        KeyBinding(input: "p", modifierFlags: [.alternate], title: "π", binding: Binding(key: .ArrowUp, shift: true)),
        
        KeyBinding(input: ":"),
        KeyBinding(input: ";"),
        KeyBinding(input: "="),
        KeyBinding(input: "\r", binding: Binding(key: .Return)),

        KeyBinding(input: "[", binding: Binding(key: .Char(":"), shift: true)),
        KeyBinding(input: "]", binding: Binding(key: .Char(";"), shift: true)),

        KeyBinding(input: ","),
        KeyBinding(input: "."),
        KeyBinding(input: "/"),
        KeyBinding(input: UIKeyCommand.inputDownArrow, binding: Binding(key: .CursorUpDown)),
        KeyBinding(input: UIKeyCommand.inputRightArrow, binding: Binding(key: .CursorLeftRight)),

        KeyBinding(input: "<", binding: Binding(key: .Char(","), shift: true)),
        KeyBinding(input: ">", binding: Binding(key: .Char("."), shift: true)),
        KeyBinding(input: "?", binding: Binding(key: .Char("/"), shift: true)),
        KeyBinding(input: UIKeyCommand.inputUpArrow, binding: Binding(key: .CursorUpDown, shift: true)),
        KeyBinding(input: UIKeyCommand.inputLeftArrow, binding: Binding(key: .CursorLeftRight, shift: true)),
        
        KeyBinding(input: "", modifierFlags: [.alphaShift], title: "Commodore", binding: Binding(key: .Commodore)),
        KeyBinding(input: "", modifierFlags: [.shift, .alphaShift], binding: Binding(key: .Commodore, shift: true)),
        
        KeyBinding(input: " ")
    ]
    
    var boundKeyCommands = [UIKeyCommand : Binding]()
    
    var capsLockPressed = false
    
    override func viewSafeAreaInsetsDidChange() {
        safeInsetHeight.constant = view.safeAreaInsets.bottom
    }
    
    override func viewDidLoad() {
        driveStatus = [ drive8Status, drive9Status, drive10Status, drive11Status ]
        controllerView.topOffset = controllerViewTopConstraint.constant
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = gameViewItem?.title
        
        keyboardView.delegate = self

        guard !running else { return }
        
        if let gameViewItem = gameViewItem {
            machine = gameViewItem.machine
            machine.directoryURL = gameViewItem.directoryURL
            
            if let mediaItem = selectedMedia {
                switch mediaItem.mediaType {
                case .cartridge:
                    machine.cartridgeImage = mediaItem as? CartridgeImage
                case .disk:
                    if let index = machine.diskImages.firstIndex(where: { $0.url == mediaItem.url }) {
                        machine.diskImages.remove(at: index)
                    }
                    machine.diskImages.insert(mediaItem as! DiskImage, at: 0)

                case .ideDisk:
                    if let index = machine.ideDiskImages.firstIndex(where: { $0.url == mediaItem.url }) {
                        machine.ideDiskImages.remove(at: index)
                    }
                    machine.ideDiskImages.insert(mediaItem as! IdeDiskImage, at: 0)

                case .programFile:
                    machine.programFile = mediaItem as? ProgramFile
                case .ramExpansionUnit:
                    machine.ramExpansionUnit = mediaItem as? RamExpansionUnit
                case .tape:
                    if let index = machine.tapeImages.firstIndex(where: { $0.url == mediaItem.url }) {
                        machine.tapeImages.remove(at: index)
                    }
                    machine.tapeImages.insert(mediaItem as! TapeImage, at: 0)
                }
            }
        }
        else {
            machine = Machine()
        }
        
        if toolsMode {
            machine.cartridgeImage = Tools.standard.selectedCartridge
            machine.autostart = false
        }
        
        switch machine.specification.computer.viceMachineModel.viceMachine {
        case .c64:
            emulator = Vice_C64.Vice()
        case .vic:
            emulator = ViceVIC20.Vice()
        }
        machine.vice = emulator
        
        _keyboardCommands.removeAll()
        preapareKeyPressTranslator()
        
        let computer = machine.specification.computer
        statusBarView.backgroundColor = computer.caseColor
        keyboardView.backgroundColor = computer.caseColor
        keyboardView.keyboard = computer.keyboard
        safeInsetView.backgroundColor = computer.caseColor
        
        if view.frame.width > view.frame.height || computer.keyboard == nil {
            keyboardView.isHidden = true
        }

        if gameViewItem?.type != .tools && toolsMode {
            machine.diskImages.append(contentsOf: Tools.standard.disks)
        }
        
        machine.mountDisks()
        
        for index in (0 ..< driveStatus.count) {
            if machine.diskDrives.count > index && machine.diskDrives[index].hasStatus {
                driveStatus[index].configureFrom(drive: machine.diskDrives[index])
                driveStatus[index].isHidden = false
            }
            else {
                driveStatus[index].isHidden = true
            }
        }
        
        if machine.userPortModule?.moduleType == .singularAdapter {
            singularStatus.isHidden = false
            singularStatus.mode = machine.specification.singularAdapterMode
        }
        else {
            singularStatus.isHidden = true
        }
        
        if let tapeFile = (machine.tapeImages.isEmpty ? nil : machine.tapeImages[0])?.url, machine.cassetteDrive.hasStatus {
            tapeStatus.ledView?.isRound = true
            tapeStatus.ledView?.darkColor = UIColor(named: "LED 1530 Off")!
            tapeStatus.ledView?.lightColor = UIColor(named: "LED 1530 On")!
            tapeStatus.controlView?.image = UIImage(named: "Tape Stop")
            tapeStatus.showCounter = tapeFile.pathExtension.lowercased() != "t64"
            tapeStatus.backgroundColor = machine.cassetteDrive.caseColor
        }
        else {
            tapeStatus.isHidden = true
        }
    
        if !haveStatusBar {
            statusBarView.isHidden = true
            if keyboardView.isHidden {
                safeInsetView.isHidden = true
            }
        }
        
        let biosURL = Defaults.biosURL

        if !toolsMode && machine.tapeImages.isEmpty && Defaults.standard.enableJiffyDOS {
            if let romC64 = Defaults.standard.biosJiffyDosC64 {
                if machine.specification.computer.viceMachineModel.viceMachine == .c64 {
                    machine.resources[.KernalName] = .String(biosURL.appendingPathComponent(romC64).path)
                }
                if let rom1541 = Defaults.standard.biosJiffyDos1541 {
                    machine.resources[.DosName1541] = .String(biosURL.appendingPathComponent(rom1541).path)
                }
                if let rom1541II = Defaults.standard.biosJiffyDos1541II {
                    machine.resources[.DosName1541II] = .String(biosURL.appendingPathComponent(rom1541II).path)
                }
                if let rom1581 = Defaults.standard.biosJiffyDos1581 {
                    machine.resources[.DosName1581] = .String(biosURL.appendingPathComponent(rom1581).path)
                }
            }
        }
        
        if let rom2000 = Defaults.standard.biosFD2000 {
            machine.resources[.DosName2000] = .String(biosURL.appendingPathComponent(rom2000).path)
        }
        if let rom4000 = Defaults.standard.biosFD4000 {
            machine.resources[.DosName4000] = .String(biosURL.appendingPathComponent(rom4000).path)
        }
        
        machine.resources[.DriveSoundEmulation] = .Bool(Defaults.standard.emulateDriveSounds)

        emulator?.machine = machine
        emulator?.imageView = imageView
        emulator?.delegate = self
       
        if Defaults.standard.videoFilter == "None" {
            imageView.layer.magnificationFilter = .nearest
        }
    
        if machine.cartridgeImage?.type.hasFreeze ?? false != true {
            navigationItem.rightBarButtonItems?.removeAll(where: { $0 == freezeButton })
        }
        if computer.keyboard == nil {
            navigationItem.rightBarButtonItems?.removeAll(where: { $0 == keyboardButton })
        }
        
        if let game = gameViewItem as? Game {
            game.lastOpened = Date()
        }
        
        do {
            try (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext.save()
        }
        catch {
            
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(controllerWasConnected(_:)), name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(controllerWasDisconnected(_:)), name: .GCControllerDidDisconnect, object: nil)

        machine.connect(inputDevice: TouchInputDevice(view: controllerView))
        
        for controller in GCController.controllers() {
            connect(controller: controller)
        }
        
        running = true
        emulator?.start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        emulator?.quit()
        running = false
    }
    
    var _keyboardCommands = [UIKeyCommand]()
    
    override var keyCommands: [UIKeyCommand]? {
        if (_keyboardCommands.count == 0) {
            _keyboardCommands = [
                UIKeyCommand(title: "Reset", action: #selector(resetMachine(_:)), input: "r", modifierFlags: .command, discoverabilityTitle: "Reset")
            ]
            
            if machine.cartridgeImage?.type.hasFreeze ?? false {
                _keyboardCommands.append(UIKeyCommand(title: "Freeze", action: #selector(freezeMachine(_:)), input: "z", modifierFlags: .command, discoverabilityTitle: "Freeze"))
            }

#if false
            if machine.specification.computer.keyboard != nil {
                let capsLockAsCommodore = Defaults.standard.capsLockAsCommodore

                var modifiers: [UIKeyModifierFlags] = [[], [.shift]]
                
                if capsLockAsCommodore {
                    modifiers.append([.alphaShift])
                }
                for key in [ "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" ] {
                    for modifier in modifiers {
                        _keyboardCommands.append(UIKeyCommand(input: key, modifierFlags: modifier, action: #selector(handleKeyCommand(_:))))
                    }
                }
                
                
                for keyBinding in bindings {
                    if !capsLockAsCommodore && keyBinding.modifierFlags.contains(.alphaShift) {
                        continue
                    }
                    
                    let command: UIKeyCommand
                    if let title = keyBinding.title {
                        command = UIKeyCommand(input: keyBinding.input, modifierFlags: keyBinding.modifierFlags, action: #selector(handleKeyCommand(_:)), discoverabilityTitle: title)
                    }
                    else {
                        command = UIKeyCommand(input: keyBinding.input, modifierFlags: keyBinding.modifierFlags, action: #selector(handleKeyCommand(_:)))
                    }
                    boundKeyCommands[command] = keyBinding.binding
                    _keyboardCommands.append(command)
                }
                
                if !capsLockAsCommodore {
                    _keyboardCommands.append(UIKeyCommand(input: "", modifierFlags: [.alphaShift], action: #selector(handleCapsLock(_:))))
                }
            }
#endif
        }
        return _keyboardCommands
    }
        

    @IBAction func toggleKeyboard(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.keyboardView.isHidden = !self.keyboardView.isHidden
            if self.keyboardView.isHidden {
                if self.haveStatusBar && self.autoHideStatusBar && self.statusBarIsIdle {
                    self.statusBarView.isHidden = true
                }
                if !self.haveStatusBar || self.statusBarView.isHidden {
                    self.safeInsetView.isHidden = true
                }
            }
            else {
                self.safeInsetView.isHidden = false
            }
            self.stackView.layoutIfNeeded()
        }
    }
    
    @IBAction func takeScreenshot(_ sender: Any) {
        guard let gameViewItem = gameViewItem else { return }
        guard let ciImage = imageView.image?.ciImage else { return }
        let tempURL = gameViewItem.directoryURL.appendingPathComponent(UUID().uuidString + ".png")
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        guard let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, kUTTypePNG, 1, nil) else { return }
        CGImageDestinationAddImage(destination, cgImage, nil)
        CGImageDestinationFinalize(destination)
        gameViewItem.addScreenshot(url: tempURL)
        UIView.animate(withDuration: 0.1, animations: {
            self.screenshotFlashView.alpha = 1.0
        }, completion: { finished in
            if finished {
                UIView.animate(withDuration: 0.3) {
                    self.screenshotFlashView.alpha = 0.0
                }
            }
        })
    }

    @IBAction func freezeMachine(_ sender: Any) {
        emulator?.freeze()
    }

    @IBAction func resetMachine(_ sender: Any) {
        emulator?.reset()
    }
    
    @objc func handleCapsLock(_ command: UIKeyCommand) {
        capsLockPressed = !capsLockPressed
    }
    
    @objc func handleKeyCommand(_ command: UIKeyCommand) {
        // key commands repeat first after 401ms, then every 101ms
        
        if let binding = bindingFor(command: command) {
            emulator?.press(key: binding.key)
            if (binding.control) {
                emulator?.press(key: .Control)
            }
            if (binding.shift) {
                emulator?.press(key: .ShiftLeft)
            }
            if (binding.commodore) {
                emulator?.press(key: .Commodore)
            }

            Timer.scheduledTimer(withTimeInterval: 0.08, repeats: false) { timer in
                self.emulator?.release(key: binding.key)
                if (binding.control) {
                    self.emulator?.release(key: .Control)
                }
                if (binding.shift) {
                    self.emulator?.release(key: .ShiftLeft)
                }
                if (binding.commodore) {
                    self.emulator?.release(key: .Commodore)
                }
            }
        }
    }
    
    func bindingFor(command: UIKeyCommand) -> Binding? {
        if let binding = boundKeyCommands[command] {
            return binding
        }
        
        guard let input = command.input else { return nil }
        
        if input >= "a" && input <= "z" && input.count == 1 {
            if let char = input.first {
                return Binding(key: .Char(char), shift: capsLockPressed || command.modifierFlags.contains(.shift), control: command.modifierFlags.contains(.control), commodore: command.modifierFlags.contains(.alphaShift))
            }
        }
        
        return nil
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueType = segueType(from: segue) else { return }
        
        switch segueType {
        case .borderMode:
            guard let destination = segue.destination as? SingleSelectionTableViewController else { return }
            // TODO: add row to revert to default
            destination.items = MachineConfig.BorderMode.allCases
            destination.dismissOnSelection = true
            destination.selectedRow = MachineConfig.BorderMode.allCases.firstIndex(where: { $0 == machine.specification.borderMode })
            destination.selected = { value in
                guard let mode = value as? MachineConfig.BorderMode else { return }
                self.machine.change(borderMode: mode)
            }

        case .diskDrive8Control, .diskDrive9Control, .diskDrive10Control, .diskDrive11Control:
            guard let destination = segue.destination as? SelectDiskViewController, let emulator = emulator,
                let unit = segueType.unit else { return }

            let drive = emulator.machine.diskDrives[unit - 8]
            destination.drive = drive
            destination.unit = unit
            destination.diskImages = emulator.machine.diskImages.filter({ drive.supports(image: $0) })
            destination.currentDiskImage = drive.image
            //destination.status = String(cString: drive_get_status(Int32(unit)))

            destination.changeCallback = { diskImage in
                self.driveStatus[unit - 8].configureFrom(image: diskImage)
                self.emulator?.attach(drive: unit, image: diskImage)
            }
            
        case .inputMapping:
            guard let navigationController = segue.destination as? UINavigationController,
                let destination = navigationController.topViewController as? InputMappingTableViewController else { return }
            destination.inputMapping = machine.inputMapping

        case .machineParts:
            guard let navigationController = segue.destination as? UINavigationController, let destination = navigationController.topViewController as? MachinePartsViewController else { return }
            destination.machineSpecification = machine.specification
            destination.machine = machine
            destination.isMachineRunning = true
            destination.changeHandler = { machineSpecification in
                self.machine.update(specification: machineSpecification)
            }
            
        case .singularAdapterMode:
            guard let destination = segue.destination as? SingularAdapterStatusViewController else { return }
            destination.selectedValue = machine.specification.singularAdapterMode
            destination.singularAdapter = machine.userPortModule
            destination.changeCallback = { mode in
                var newSpecification = self.machine.specification
                newSpecification.singularAdapterMode = mode
                self.machine.update(specification: newSpecification)
                self.singularStatus.mode = mode
            }
        }
    }
    
    // MARK: - KeyboardViewDelegate
    
    func pressed(key: Key) {
        if key == .ShiftLock {
            let lockKey = keyboardView.keyboard?.lockIsShift ?? true ? Key.ShiftLeft : Key.Commodore
            if keyboardView.isShiftLockPressed {
                emulator?.release(key: lockKey)
            }
            else {
                emulator?.press(key: lockKey)
            }
            keyboardView.isShiftLockPressed = !keyboardView.isShiftLockPressed
        }
        else {
            emulator?.press(key: key)
        }
    }
    
    func released(key: Key) {
        if key == .ShiftLock {
            return
        }
        emulator?.release(key: key)
    }
    
    // MARK: - Status Bar Handling
    
    var haveStatusBar: Bool {
        return !tapeStatus.isHidden || driveStatus.contains(where: { !$0.isHidden })
    }
    
    var statusBarIsIdle: Bool {
        return activeStatusBarItems.isEmpty
    }
    
    private var activeStatusBarItems = Set<UIView>()
    
    override func statusBarShown() {
        fullscreenTopConstraint.isActive = false
        saveTopConstraint.isActive = true
        DebugLog.shared.log("show navigation bar")
        updateStatusBarAutoHide()
    }
    
    override func statusBarHidden() {
        saveTopConstraint.isActive = false
        fullscreenTopConstraint.isActive = true
        DebugLog.shared.log("hide navigation bar")
        updateStatusBarAutoHide()
    }
    
    var autoHideStatusBar: Bool {
        return keyboardView.isHidden && isBarHidden
    }
    
    func updateStatusBarAutoHide() {
        guard haveStatusBar else { return }
        
        if autoHideStatusBar {
            DebugLog.shared.log("status bar autohides")
            if statusBarIsIdle {
                DebugLog.shared.log("status bar is idle, hide")
                hideStatusBar()
            }
        }
        else {
            DebugLog.shared.log("status bar doesn't autohide, show")
            showStatusBar()
        }
    }
    
    var autoHideStatusBarTimer: Timer?
    
    func startStatusBarTimer() {
        guard haveStatusBar && autoHideStatusBar else { return }
        let timer = Timer(fire: Date().addingTimeInterval(3.0), interval: 0.0, repeats: false) { _ in
            self.autoHideStatusBarTimer = nil
            self.hideStatusBar()
        }
        autoHideStatusBarTimer = timer
        RunLoop.main.add(timer, forMode: .default)
    }
    
    func cancelStatusBarTimer() {
        guard let timer = autoHideStatusBarTimer else { return }
        timer.invalidate()
        autoHideStatusBarTimer = nil
    }
    
    func hideStatusBar() {
        UIView.animate(withDuration: TimeInterval(UINavigationController.hideShowBarDuration)) {
            self.statusBarView.isHidden = true
            if self.keyboardView.isHidden {
                self.safeInsetView.isHidden = true
            }
            self.stackView.layoutIfNeeded()
        }
    }
    
    func showStatusBar() {
        autoHideStatusBarTimer?.invalidate()
        UIView.animate(withDuration: TimeInterval(UINavigationController.hideShowBarDuration)) {
            self.statusBarView.isHidden = false
            self.safeInsetView.isHidden = false
            self.stackView.layoutIfNeeded()
        }
    }
    
    func statusBar(item: UIView, isActive: Bool) {
        DebugLog.shared.log("status bar item \(item) is " + (isActive ? "active" : "idle"))
        if isActive {
            if statusBarIsIdle && autoHideStatusBar {
                DebugLog.shared.log("status bar was hidden, show")
                cancelStatusBarTimer()
                showStatusBar()
            }
            activeStatusBarItems.insert(item)
        }
        else {
            activeStatusBarItems.remove(item)
            if statusBarIsIdle && autoHideStatusBar {
                DebugLog.shared.log("status bar autohides and is idle, hide")
                startStatusBarTimer()
            }
        }
    }
    
    func connect(controller: GCController) {
        let inputDevice = MfiInputDevice(controller: controller)
        controllers[controller] = inputDevice
        machine.connect(inputDevice: inputDevice)
    }
    
    func disconnect(controller: GCController) {
        guard let inputDevice = controllers[controller] else { return }
        inputDevice.disconnect()
        controllers[controller] = nil
    }
}

extension EmulatorViewController: EmulatorDelegate {
    func updateDriveStatus(unit: Int, track: Double, led1Intensity: Double, led2Intensity: Double) {
        guard haveStatusBar else { return }
        
        let statusView = driveStatus[unit - 8]
        
        statusView.trackView.currentTrack = track
        statusView.ledViews[0].intensity = led1Intensity
        statusView.ledViews[1].intensity = led2Intensity

        statusBar(item: statusView, isActive: led1Intensity != 0 || led2Intensity != 0)
    }
    
func updateTapeStatus(controlStatus: DatasetteControlStatus, isMotorOn: Bool, counter: Double) {
        guard haveStatusBar else { return }

        tapeStatus.counterView?.counter = counter
        tapeStatus.ledView?.intensity = controlStatus == .record ? 1 : 0

        let imageName: String
        switch controlStatus {
        case .forward:
            imageName = "Tape Forward"

        case .rewind:
            imageName = "Tape Rewind"
            
        case .record, .start:
            imageName = "Tape Play"
            
        default:
            imageName = "Tape Stop"
        }
        tapeStatus.controlView?.image = UIImage(named: imageName)
        tapeStatus.isMotorOn = isMotorOn

        statusBar(item: tapeStatus, isActive: isMotorOn)
    }
}


extension EmulatorViewController {
    @objc
    func controllerWasConnected(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        
        connect(controller: controller)
    }
    
    @objc
    func controllerWasDisconnected(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        
        disconnect(controller: controller)
    }
}

extension EmulatorViewController: KeyPressTranslatorDelegate {
    func preapareKeyPressTranslator() {
        if machine.specification.computer.keyboard == nil {
            keyPressTranslator = nil
        }
        else {
            // TODO: move elsewhere (allow different keyboards)
            var modifierMap: [UIKeyboardHIDUsage: Key] = [
                .keyboardLeftShift: .ShiftLeft,
                .keyboardRightShift: .ShiftRight,
                .keyboardLeftControl: .Control,
                .keyboardRightControl: .Control,
                UIKeyboardHIDUsage(rawValue: 669)!: .Commodore
            ]
            
            if Defaults.standard.capsLockAsCommodore {
                modifierMap[.keyboardCapsLock] = .ShiftLock
            }
            else {
                modifierMap[.keyboardCapsLock] = .Commodore
            }
            
            let symbolRemap = [
                ModifiedSymbol(symbol: .char("1"), modifiers: .command): ModifiedSymbol(symbol: .key(.keyboardF1)),
                ModifiedSymbol(symbol: .char("2"), modifiers: .command): ModifiedSymbol(symbol: .key(.keyboardF2)),
                ModifiedSymbol(symbol: .char("3"), modifiers: .command): ModifiedSymbol(symbol: .key(.keyboardF3)),
                ModifiedSymbol(symbol: .char("4"), modifiers: .command): ModifiedSymbol(symbol: .key(.keyboardF4)),
                ModifiedSymbol(symbol: .char("5"), modifiers: .command): ModifiedSymbol(symbol: .key(.keyboardF5)),
                ModifiedSymbol(symbol: .char("6"), modifiers: .command): ModifiedSymbol(symbol: .key(.keyboardF6)),
                ModifiedSymbol(symbol: .char("7"), modifiers: .command): ModifiedSymbol(symbol: .key(.keyboardF7)),
                ModifiedSymbol(symbol: .char("8"), modifiers: .command): ModifiedSymbol(symbol: .key(.keyboardF8)),
                ModifiedSymbol(symbol: .key(.keyboardDeleteOrBackspace), modifiers: .command): ModifiedSymbol(symbol: .key(.keyboardHome)),
                ModifiedSymbol(symbol: .key(.keyboardDeleteOrBackspace), modifiers: [.shift, .command]): ModifiedSymbol(symbol: .key(.keyboardHome), modifiers: .shift)
            ]
            
            let keyMap: [Key: KeySymbols] = [
                .ArrowLeft: KeySymbols(normal: .char("`"), shifted: .char("~")),
                .Char("1"): KeySymbols(normal: .char("1"), shifted: .char("!")),
                .Char("2"): KeySymbols(normal: .char("2"), shifted: .char("\"")),
                .Char("3"): KeySymbols(normal: .char("3"), shifted: .char("#")),
                .Char("4"): KeySymbols(normal: .char("4"), shifted: .char("$")),
                .Char("5"): KeySymbols(normal: .char("5"), shifted: .char("%")),
                .Char("6"): KeySymbols(normal: .char("6"), shifted: .char("&")),
                .Char("7"): KeySymbols(normal: .char("7"), shifted: .char("'")),
                .Char("8"): KeySymbols(normal: .char("8"), shifted: .char("(")),
                .Char("9"): KeySymbols(normal: .char("9"), shifted: .char(")")),
                .Char("0"): KeySymbols(normal: .char("0"), shifted: .char("0")),
                .Char("+"): KeySymbols(normal: .char("+")),
                .Char("-"): KeySymbols(normal: .char("-")),
                .Char("£"): KeySymbols(normal: .char("£")),
                .ClearHome: KeySymbols(both: .key(.keyboardHome)),
                .InsertDelete: KeySymbols(both: .key(.keyboardDeleteOrBackspace)),
                
                .Char("q"): KeySymbols(normal: .char("q"), shifted: .char("Q")),
                .Char("w"): KeySymbols(normal: .char("w"), shifted: .char("W")),
                .Char("e"): KeySymbols(normal: .char("e"), shifted: .char("E")),
                .Char("r"): KeySymbols(normal: .char("r"), shifted: .char("R")),
                .Char("t"): KeySymbols(normal: .char("t"), shifted: .char("T")),
                .Char("y"): KeySymbols(normal: .char("y"), shifted: .char("Y")),
                .Char("u"): KeySymbols(normal: .char("u"), shifted: .char("U")),
                .Char("i"): KeySymbols(normal: .char("i"), shifted: .char("I")),
                .Char("o"): KeySymbols(normal: .char("o"), shifted: .char("O")),
                .Char("p"): KeySymbols(normal: .char("p"), shifted: .char("P")),
                .Char("@"): KeySymbols(normal: .char("@")),
                .Char("*"): KeySymbols(normal: .char("*")),
                .ArrowUp: KeySymbols(normal: .char("^"), shifted: .char("π")),
                .Restore: KeySymbols(normal: .char("\\"), shifted: .char("|")),

                .RunStop: KeySymbols(both: .key(.keyboardTab)),
                .Char("a"): KeySymbols(normal: .char("a"), shifted: .char("A")),
                .Char("s"): KeySymbols(normal: .char("s"), shifted: .char("S")),
                .Char("d"): KeySymbols(normal: .char("d"), shifted: .char("D")),
                .Char("f"): KeySymbols(normal: .char("f"), shifted: .char("F")),
                .Char("g"): KeySymbols(normal: .char("g"), shifted: .char("G")),
                .Char("h"): KeySymbols(normal: .char("h"), shifted: .char("H")),
                .Char("j"): KeySymbols(normal: .char("j"), shifted: .char("J")),
                .Char("k"): KeySymbols(normal: .char("k"), shifted: .char("K")),
                .Char("l"): KeySymbols(normal: .char("l"), shifted: .char("L")),
                .Char(":"): KeySymbols(normal: .char(":"), shifted: .char("[")),
                .Char(";"): KeySymbols(normal: .char(";"), shifted: .char("]")),
                .Char("="): KeySymbols(normal: .char("="), shifted: .char("=")),
                .Return: KeySymbols(both: .key(.keyboardReturnOrEnter)),
                
                .Char("z"): KeySymbols(normal: .char("z"), shifted: .char("Z")),
                .Char("x"): KeySymbols(normal: .char("x"), shifted: .char("X")),
                .Char("c"): KeySymbols(normal: .char("c"), shifted: .char("C")),
                .Char("v"): KeySymbols(normal: .char("v"), shifted: .char("V")),
                .Char("b"): KeySymbols(normal: .char("b"), shifted: .char("B")),
                .Char("n"): KeySymbols(normal: .char("n"), shifted: .char("N")),
                .Char("m"): KeySymbols(normal: .char("m"), shifted: .char("M")),
                .Char(","): KeySymbols(normal: .char(","), shifted: .char("<")),
                .Char("."): KeySymbols(normal: .char("."), shifted: .char(">")),
                .Char("/"): KeySymbols(normal: .char("/"), shifted: .char("?")),
                .CursorLeftRight: KeySymbols(normal: .key(.keyboardRightArrow), shifted: .key(.keyboardLeftArrow)),
                .CursorUpDown: KeySymbols(normal: .key(.keyboardDownArrow), shifted: .key(.keyboardUpArrow)),
                
                .Char(" "): KeySymbols(both: .char(" ")),
                
                .F1: KeySymbols(normal: .key(.keyboardF1), shifted: .key(.keyboardF2)),
                .F3: KeySymbols(normal: .key(.keyboardF3), shifted: .key(.keyboardF4)),
                .F5: KeySymbols(normal: .key(.keyboardF5), shifted: .key(.keyboardF6)),
                .F7: KeySymbols(normal: .key(.keyboardF7), shifted: .key(.keyboardF8)),
            ]
            
            keyPressTranslator = KeyPressTranslator(modifierMap: modifierMap, keyMap: keyMap, symbolRemap: symbolRemap)
            keyPressTranslator?.delegate = self
            
        }
    }
    
    func press(key: Key, delayed: Int) {
        emulator?.press(key: key, delayed: delayed)
    }
    
    func release(key: Key, delayed: Int) {
        emulator?.release(key: key, delayed: delayed)
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(keyPressTranslator?.pressesBegan(presses, with: event) ?? presses, with: event)
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(keyPressTranslator?.pressesEnded(presses, with: event) ?? presses, with: event)
    }
    
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesCancelled(keyPressTranslator?.pressesEnded(presses, with: event) ?? presses, with: event)
    }
}
