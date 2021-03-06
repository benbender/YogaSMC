//
//  YogaSMCPane.swift
//  YogaSMCPane
//
//  Created by Zhen on 9/17/20.
//  Copyright © 2020 Zhen. All rights reserved.
//

import AppKit
import Foundation
import IOKit
import PreferencePanes

let thinkLEDCommand = [0, 0x80, 0xA0, 0xC0]

// from https://ffried.codes/2018/01/20/the-internals-of-the-macos-hud/
@objc enum OSDImage: CLongLong {
    case kBrightness = 1
    case brightness2 = 2
    case kVolume = 3
    case kMute = 4
    case volume5 = 5
    case kEject = 6
    case brightness7 = 7
    case brightness8 = 8
    case kAirportRange = 9
    case wireless2Forbid = 10
    case kBright = 11
    case kBrightOff = 12
    case kBright13 = 13
    case kBrightOff14 = 14
    case Ajar = 15
    case mute16 = 16
    case volume17 = 17
    case empty18 = 18
    case kRemoteLinkedGeneric = 19
    case kRemoteSleepGeneric = 20 // will put into sleep
    case muteForbid = 21
    case volumeForbid = 22
    case volume23 = 23
    case empty24 = 24
    case kBright25 = 25
    case kBrightOff26 = 26
    case backlightonForbid = 27
    case backlightoffForbid = 28
    /* and more cases from 1 to 28 (except 18 and 24) */
}

// from https://github.com/w0lfschild/macOS_headers/blob/master/macOS/CoreServices/OSDUIHelper/1/OSDUIHelperProtocol-Protocol.h

@objc protocol OSDUIHelperProtocol {

    @objc func showFullScreenImage(_ img: OSDImage, onDisplayID: CGDirectDisplayID, priority: CUnsignedInt, msecToAnimate: CUnsignedInt)

    @objc func fadeClassicImageOnDisplay(_ img: CUnsignedInt)

    @objc func showImageAtPath(_ img: NSString, onDisplayID: CGDirectDisplayID, priority: CUnsignedInt, msecUntilFade: CUnsignedInt, withText: NSString)

    @objc func showImage(_ img: OSDImage, onDisplayID: CGDirectDisplayID, priority: CUnsignedInt, msecUntilFade: CUnsignedInt, filledChiclets: CUnsignedInt, totalChiclets: CUnsignedInt, locked: CBool)

    @objc func showImage(_ img: OSDImage, onDisplayID: CGDirectDisplayID, priority: CUnsignedInt, msecUntilFade: CUnsignedInt, withText: NSString)

    @objc func showImage(_ img: OSDImage, onDisplayID: CGDirectDisplayID, priority: CUnsignedInt, msecUntilFade: CUnsignedInt)
}

func getBoolean(_ key: String, _ io_service: io_service_t) -> Bool {
    guard let rvalue = IORegistryEntryCreateCFProperty(io_service, key as CFString, kCFAllocatorDefault, 0) else {
        return false
    }

    return rvalue.takeRetainedValue() as! Bool
}

func getNumber(_ key: String, _ io_service: io_service_t) -> Int {
    guard let rvalue = IORegistryEntryCreateCFProperty(io_service, key as CFString, kCFAllocatorDefault, 0) else {
        return -1
    }

    return rvalue.takeRetainedValue() as! Int
}

func getString(_ key: String, _ io_service: io_service_t) -> String? {
    guard let rvalue = IORegistryEntryCreateCFProperty(io_service, key as CFString, kCFAllocatorDefault, 0) else {
        return nil
    }

    return rvalue.takeRetainedValue() as! NSString as String
}

func sendBoolean(_ key: String, _ value: Bool, _ io_service: io_service_t) -> Bool {
    return (kIOReturnSuccess == IORegistryEntrySetCFProperty(io_service, key as CFString, value as CFBoolean))
}

func sendNumber(_ key: String, _ value: Int, _ io_service: io_service_t) -> Bool {
    return (kIOReturnSuccess == IORegistryEntrySetCFProperty(io_service, key as CFString, value as CFNumber))
}

func sendString(_ key: String, _ value: String, _ io_service: io_service_t) -> Bool {
    return (kIOReturnSuccess == IORegistryEntrySetCFProperty(io_service, key as CFString, value as CFString))
}

class YogaSMCPane : NSPreferencePane {
    var io_service : io_service_t = 0

    @IBOutlet weak var vVersion: NSTextField!
    @IBOutlet weak var vBuild: NSTextField!
    @IBOutlet weak var vClass: NSTextField!
    @IBOutlet weak var vECRead: NSTextField!

    // Idea
    @IBOutlet weak var vFnKeyRadio: NSButton!
    @IBOutlet weak var vFxKeyRadio: NSButton!
    @IBAction func vFnKeySet(_ sender: NSButton) {
        if !sendBoolean("FnlockMode", vFnKeyRadio.state == .on, io_service) {
            vFnKeyRadio.state = getBoolean("FnlockMode", io_service) ? .on : .off
        }
    }
    @IBOutlet weak var vConservationMode: NSButton!
    @IBOutlet weak var vRapidChargeMode: NSButton!
    @IBOutlet weak var vBatteryID: NSTextField!
    @IBOutlet weak var vBatteryTemperature: NSTextField!
    @IBOutlet weak var vCycleCount: NSTextField!
    @IBOutlet weak var vMfgDate: NSTextField!

    @IBAction func vConservationModeSet(_ sender: NSButton) {
        if !sendBoolean("ConservationMode", vConservationMode.state == .on, io_service) {
            vConservationMode.state = getBoolean("ConservationMode", io_service) ? .on : .off
        }
    }
    
    @IBOutlet weak var vCamera: NSTextField!
    @IBOutlet weak var vBluetooth: NSTextField!
    @IBOutlet weak var vWireless: NSTextField!
    @IBOutlet weak var vWWAN: NSTextField!
    @IBOutlet weak var vGraphics: NSTextField!

    // Think

    @IBOutlet weak var vPowerLEDSlider: NSSlider!
    @IBOutlet weak var vStandbyLEDSlider: NSSlider!
    @IBOutlet weak var vThinkDotSlider: NSSliderCell!
    @IBOutlet weak var vCustomLEDSlider: NSSlider!
    @IBOutlet weak var vCustomLEDList: NSPopUpButton!
    @IBAction func vPowerLEDSet(_ sender: NSSlider) {
        if (!sendNumber("LED", thinkLEDCommand[vPowerLEDSlider.integerValue] + 0x00, io_service)) {
            return
        }
    }
    @IBAction func vStandbyLEDSet(_ sender: NSSlider) {
        if (!sendNumber("LED", thinkLEDCommand[vStandbyLEDSlider.integerValue] + 0x07, io_service)) {
            return
        }
    }
    @IBAction func vThinkDotSet(_ sender: NSSlider) {
        if (!sendNumber("LED", thinkLEDCommand[vThinkDotSlider.integerValue] + 0x0A, io_service)) {
            return
        }
    }
    @IBAction func vCustomLEDSet(_ sender: NSSlider) {
        let value = thinkLEDCommand[vCustomLEDSlider.integerValue] + vCustomLEDList.indexOfSelectedItem
        let prompt = String(format:"LED 0x%02X", value)
        OSD(prompt)
        if (!sendNumber("LED", value, io_service)) {
            return
        }
    }
    @IBOutlet weak var TabView: NSTabView!
    @IBOutlet weak var IdeaViewItem: NSTabViewItem!
    @IBOutlet weak var ThinkViewItem: NSTabViewItem!

    @IBOutlet weak var backlightSlider: NSSlider!
    @IBAction func backlightSet(_ sender: NSSlider) {
        if !sendNumber("BacklightLevel", backlightSlider.integerValue, io_service) {
            let backlightLevel = getNumber("BacklightLevel", io_service)
            if (backlightLevel != -1) {
                backlightSlider.integerValue = backlightLevel
            } else {
                backlightSlider.isEnabled = false
            }
        }
    }

    @IBOutlet weak var autoSleepCheck: NSButton!
    @IBOutlet weak var yogaModeCheck: NSButton!
    @IBOutlet weak var indicatorCheck: NSButton!
    @IBOutlet weak var muteCheck: NSButton!
    @IBOutlet weak var micMuteCheck: NSButton!

    @IBAction func autoBacklightSet(_ sender: NSButton) {
        let val = ((autoSleepCheck.state == .on) ? 1 << 0 : 0) +
                ((yogaModeCheck.state == .on) ? 1 << 1 : 0) +
                ((indicatorCheck.state == .on) ? 1 << 2 : 0) +
                ((muteCheck.state == .on) ? 1 << 3 : 0) +
                ((micMuteCheck.state == .on) ? 1 << 3 : 0)
        if (!sendNumber("AutoBacklight", val, io_service)) {
            let autoBacklight = getNumber("AutoBacklight", io_service)
            if (autoBacklight != -1) {
                autoSleepCheck.state = ((autoBacklight & (1 << 0)) != 0) ? .on : .off
                yogaModeCheck.state =  ((autoBacklight & (1 << 1)) != 0) ? .on : .off
                indicatorCheck.state =  ((autoBacklight & (1 << 2)) != 0) ? .on : .off
                muteCheck.state =  ((autoBacklight & (1 << 3)) != 0) ? .on : .off
                micMuteCheck.state =  ((autoBacklight & (1 << 4)) != 0) ? .on : .off
            } else {
                autoSleepCheck.isEnabled = false
                yogaModeCheck.isEnabled = false
                indicatorCheck.isEnabled = false
                muteCheck.isEnabled = false
                micMuteCheck.isEnabled = false
            }
        }
    }

    override func mainViewDidLoad() {
//        UserDefaults.standard.set("value", forKey: "testKey")
//        let rvalue = UserDefaults.standard.string(forKey: "testKey")

        super.mainViewDidLoad()
        // nothing
    }

    func awakeIdea(_ props: NSDictionary) {
        if let val = props["PrimeKeyType"] as? NSString {
            vFnKeyRadio.title = val as String
            if let val = props["FnlockMode"] as? Bool {
                vFnKeyRadio.state = val ? .on : .off
            }
        } else {
            vFnKeyRadio.title = "Unknown"
            vFnKeyRadio.isEnabled = false
            vFxKeyRadio.isEnabled = false
            vFxKeyRadio.state = .on
        }

        if let val = props["ConservationMode"] as? Bool {
            vConservationMode.state = val ? .on : .off
        } else {
            vConservationMode.isEnabled = false
        }

        if let val = props["RapidChargeMode"] as? Bool {
            vRapidChargeMode.state = val ? .on : .off
        } else {
            vRapidChargeMode.isEnabled = false
        }

        if let dict = props["Battery 0"]  as? NSDictionary {
            if let ID = dict.value(forKey: "ID") as? String {
                vBatteryID.stringValue = ID
            } else {
                vBatteryID.stringValue = "Unknown"
            }
            if let count = dict.value(forKey: "Cycle count") as? String {
                vCycleCount.stringValue = count
            } else {
                vCycleCount.stringValue = "Unknown"
            }
            if let temp = dict.value(forKey: "Temperature") as? String {
                vBatteryTemperature.stringValue = temp
            } else {
                vBatteryTemperature.stringValue = "Unknown"
            }
            if let mfgDate = dict.value(forKey: "Manufacture date") as? String {
                vMfgDate.stringValue = mfgDate
            } else {
                vMfgDate.stringValue = "Unknown"
            }
        }

        if let dict = props["Capability"]  as? NSDictionary {
            if let val = dict.value(forKey: "Camera") as? Bool {
                vCamera.stringValue = val ? "Yes" : "No"
            } else {
                vCamera.stringValue = "?"
            }
            if let val = dict.value(forKey: "Bluetooth") as? Bool {
                vBluetooth.stringValue = val ? "Yes" : "No"
            } else {
                vBluetooth.stringValue = "?"
            }
            if let val = dict.value(forKey: "Wireless") as? Bool {
                vWireless.stringValue = val ? "Yes" : "No"
            } else {
                vWireless.stringValue = "?"
            }
            if let val = dict.value(forKey: "3G") as? Bool {
                vWWAN.stringValue = val ? "Yes" : "No"
            } else {
                vWWAN.stringValue = "?"
            }
            if let val = dict.value(forKey: "Graphics") as? NSString {
                vGraphics.stringValue = val as String
            } else {
                vGraphics.stringValue = "?"
            }
        }
    }

    func OSD(_ prompt: String) {
        // from https://ffried.codes/2018/01/20/the-internals-of-the-macos-hud/
        let conn = NSXPCConnection(machServiceName: "com.apple.OSDUIHelper", options: [])
        conn.remoteObjectInterface = NSXPCInterface(with: OSDUIHelperProtocol.self)
        conn.interruptionHandler = { print("Interrupted!") }
        conn.invalidationHandler = { print("Invalidated!") }
        conn.resume()

        let target = conn.remoteObjectProxyWithErrorHandler { print("Failed: \($0)") }
        guard let helper = target as? OSDUIHelperProtocol else { return } //fatalError("Wrong type: \(target)") }

        helper.showImageAtPath("/System/Library/CoreServices/OSDUIHelper.app/Contents/Resources/kBright.pdf", onDisplayID: CGMainDisplayID(), priority: 0x1f4, msecUntilFade: 2000, withText: prompt as NSString)
    }

    func awakeThink(_ props: NSDictionary) {
        return
    }

    override func awakeFromNib() {
        io_service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("YogaVPC"))

        if (io_service == 0) {
            return
        }

        var CFProps : Unmanaged<CFMutableDictionary>? = nil
        guard (kIOReturnSuccess == IORegistryEntryCreateCFProperties(io_service, &CFProps, kCFAllocatorDefault, 0) && CFProps != nil) else {
            return
        }

        guard let props = CFProps?.takeRetainedValue() as NSDictionary? else {
            return
        }

        if let val = props["YogaSMC,Build"] as? NSString {
            vBuild.stringValue = val as String
        } else {
            vBuild.stringValue = "Unknown"
            return
        }

        if let val = props["YogaSMC,Version"] as? NSString {
            vVersion.stringValue = val as String
        } else {
            vVersion.stringValue = "Unknown"
            return
        }

        if let val = props["EC Capability"] as? NSString {
            vECRead.stringValue = val as String
        } else {
            vECRead.stringValue = "Unknown"
            return
        }

        if let val = props["AutoBacklight"] as? NSNumber {
            let autoBacklight = val as! Int
            autoSleepCheck.state = ((autoBacklight & (1 << 0)) != 0) ? .on : .off
            yogaModeCheck.state =  ((autoBacklight & (1 << 1)) != 0) ? .on : .off
            indicatorCheck.state =  ((autoBacklight & (1 << 2)) != 0) ? .on : .off
            muteCheck.state =  ((autoBacklight & (1 << 3)) != 0) ? .on : .off
            micMuteCheck.state =  ((autoBacklight & (1 << 4)) != 0) ? .on : .off
        } else {
            autoSleepCheck.isEnabled = false
            yogaModeCheck.isEnabled = false
            indicatorCheck.isEnabled = false
            muteCheck.isEnabled = false
            micMuteCheck.isEnabled = false
        }

        if let val = props["BacklightLevel"] as? NSNumber {
            backlightSlider.integerValue = val as! Int
        } else {
            backlightSlider.isEnabled = false
        }

        switch props["IOClass"] as? NSString {
        case "IdeaVPC":
            vClass.stringValue = "Idea"
            TabView.removeTabViewItem(ThinkViewItem)
            indicatorCheck.isHidden = true
            muteCheck.isHidden = true
            micMuteCheck.isHidden = true
            awakeIdea(props)
        case "ThinkVPC":
            vClass.stringValue = "Think"
            TabView.removeTabViewItem(IdeaViewItem)
            awakeThink(props)
        case "YogaVPC":
            vClass.stringValue = "Generic"
            TabView.removeTabViewItem(IdeaViewItem)
            TabView.removeTabViewItem(ThinkViewItem)
        default:
            vClass.stringValue = "Unsupported"
            TabView.removeTabViewItem(IdeaViewItem)
            TabView.removeTabViewItem(ThinkViewItem)
        }
    }
}
