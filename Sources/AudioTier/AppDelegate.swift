import AppKit
import CoreAudio
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let switcher = AudioTier.shared
    private let audio = AudioManager.shared
    private var configFileMonitor: DispatchSourceFileSystemObject?
    private var configWindowController: ConfigWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)

        setupStatusBar()
        setupDeviceMonitoring()
        setupConfigFileMonitoring()

        // Apply priorities on launch
        switcher.applyPriorities()
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            if let icon = loadMenuBarIcon() {
                let aspect = icon.size.width / icon.size.height
                icon.size = NSSize(width: 18 * aspect, height: 18)
                icon.isTemplate = true
                button.image = icon
            } else {
                button.image = NSImage(
                    systemSymbolName: "speaker.wave.2.fill",
                    accessibilityDescription: "AudioTier"
                )
            }
        }

        rebuildMenu()
    }

    private func loadMenuBarIcon() -> NSImage? {
        let bundle = Bundle.main
        let dirs = [bundle.resourcePath, bundle.bundlePath + "/Contents/Resources"].compactMap { $0 }
        for dir in dirs {
            for name in ["MenuBarIcon.png", "MenuBarIcon.svg"] {
                if let img = NSImage(contentsOfFile: dir + "/" + name) {
                    return img
                }
            }
        }
        return nil
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let status = switcher.currentStatus()

        // Current devices
        let headerItem = NSMenuItem(title: "Active Devices", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        let inputLabel = "🎤 \(status.input?.name ?? "None")"
        let inputItem = NSMenuItem(title: inputLabel, action: nil, keyEquivalent: "")
        inputItem.isEnabled = false
        inputItem.indentationLevel = 1
        menu.addItem(inputItem)

        let outputLabel = "🔊 \(status.output?.name ?? "None")"
        let outputItem = NSMenuItem(title: outputLabel, action: nil, keyEquivalent: "")
        outputItem.isEnabled = false
        outputItem.indentationLevel = 1
        menu.addItem(outputItem)

        menu.addItem(NSMenuItem.separator())

        // Connected input devices
        let inputHeader = NSMenuItem(title: "Input Devices", action: nil, keyEquivalent: "")
        inputHeader.isEnabled = false
        menu.addItem(inputHeader)

        for device in audio.getInputDevices() {
            let item = NSMenuItem(
                title: "\(device.name) — \(device.transportName)",
                action: #selector(selectInputDevice(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = device.id
            item.indentationLevel = 1
            if device.id == status.input?.id {
                item.state = .on
            }
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        // Connected output devices
        let outputHeader = NSMenuItem(title: "Output Devices", action: nil, keyEquivalent: "")
        outputHeader.isEnabled = false
        menu.addItem(outputHeader)

        for device in audio.getOutputDevices() {
            let item = NSMenuItem(
                title: "\(device.name) — \(device.transportName)",
                action: #selector(selectOutputDevice(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = device.id
            item.indentationLevel = 1
            if device.id == status.output?.id {
                item.state = .on
            }
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        // Actions
        let editConfig = NSMenuItem(
            title: "Edit Config...",
            action: #selector(openConfig),
            keyEquivalent: ","
        )
        editConfig.target = self
        menu.addItem(editConfig)

        let reapply = NSMenuItem(
            title: "Re-apply Priorities",
            action: #selector(reapplyPriorities),
            keyEquivalent: "r"
        )
        reapply.target = self
        menu.addItem(reapply)

        menu.addItem(NSMenuItem.separator())

        let quit = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quit)

        statusItem.menu = menu
    }

    // MARK: - Menu Actions

    @objc private func selectInputDevice(_ sender: NSMenuItem) {
        guard let deviceID = sender.representedObject as? AudioDeviceID else { return }
        audio.setDefaultInputDevice(deviceID)
        rebuildMenu()
    }

    @objc private func selectOutputDevice(_ sender: NSMenuItem) {
        guard let deviceID = sender.representedObject as? AudioDeviceID else { return }
        audio.setDefaultOutputDevice(deviceID)
        rebuildMenu()
    }

    @objc private func openConfig() {
        // If window already open, bring it to front
        if let existing = configWindowController, existing.window?.isVisible == true {
            existing.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        configWindowController = ConfigWindowController { [weak self] in
            self?.switcher.reloadConfig()
            self?.switcher.applyPriorities()
            self?.rebuildMenu()
        }
        configWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func reapplyPriorities() {
        switcher.reloadConfig()
        switcher.applyPriorities()
        rebuildMenu()
    }

    // MARK: - Device Monitoring

    private func setupDeviceMonitoring() {
        audio.onDeviceListChanged { [weak self] in
            // Small delay to let the system settle after device connect/disconnect
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.switcher.applyPriorities()
                self?.rebuildMenu()
            }
        }
    }

    // MARK: - Config File Monitoring

    private func setupConfigFileMonitoring() {
        let path = DeviceConfig.configFile.path
        guard FileManager.default.fileExists(atPath: path) else { return }

        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: .main
        )

        source.setEventHandler { [weak self] in
            self?.switcher.reloadConfig()
            self?.switcher.applyPriorities()
            self?.rebuildMenu()
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        configFileMonitor = source
    }
}
