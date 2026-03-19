import AppKit
import CoreAudio

class ConfigWindowController: NSWindowController {
    private var inputList: [String] = []
    private var outputList: [String] = []
    private var inputTableView: NSTableView!
    private var outputTableView: NSTableView!
    private var onSave: (() -> Void)?
    private var pendingAddTag: Int = 0

    convenience init(onSave: @escaping () -> Void) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 480),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "AudioTier — Priorities"
        window.center()
        window.minSize = NSSize(width: 350, height: 400)

        self.init(window: window)
        self.onSave = onSave
        loadConfig()
        setupUI()
    }

    private func loadConfig() {
        let config = DeviceConfig.load()
        inputList = config.audioInput
        outputList = config.audioOutput
    }

    private func setupUI() {
        guard let window = self.window else { return }

        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = content

        let margin: CGFloat = 20
        let spacing: CGFloat = 8

        // Input label
        let inputLabel = makeLabel("Audio Input Priority")
        content.addSubview(inputLabel)

        // Input table
        let (inputScroll, inputTV) = makeTable(tag: 0)
        inputTableView = inputTV
        content.addSubview(inputScroll)

        // Input buttons
        let inputButtons = makeButtonBar(tag: 0)
        content.addSubview(inputButtons)

        // Output label
        let outputLabel = makeLabel("Audio Output Priority")
        content.addSubview(outputLabel)

        // Output table
        let (outputScroll, outputTV) = makeTable(tag: 1)
        outputTableView = outputTV
        content.addSubview(outputScroll)

        // Output buttons
        let outputButtons = makeButtonBar(tag: 1)
        content.addSubview(outputButtons)

        // Hint
        let hint = NSTextField(labelWithString: "Top device = highest priority. Only listed devices are considered.")
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor
        hint.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(hint)

        // Save / Cancel
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelAction))
        cancelButton.keyEquivalent = "\u{1b}"
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(cancelButton)

        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveAction))
        saveButton.keyEquivalent = "\r"
        saveButton.bezelStyle = .rounded
        if #available(macOS 14.0, *) {
            saveButton.bezelColor = .controlAccentColor
        }
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(saveButton)

        NSLayoutConstraint.activate([
            // Input label
            inputLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: margin),
            inputLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: margin),
            inputLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -margin),

            // Input table
            inputScroll.topAnchor.constraint(equalTo: inputLabel.bottomAnchor, constant: spacing),
            inputScroll.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: margin),
            inputScroll.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -margin),
            inputScroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),

            // Input buttons
            inputButtons.topAnchor.constraint(equalTo: inputScroll.bottomAnchor, constant: 4),
            inputButtons.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: margin),
            inputButtons.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -margin),

            // Output label
            outputLabel.topAnchor.constraint(equalTo: inputButtons.bottomAnchor, constant: 16),
            outputLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: margin),
            outputLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -margin),

            // Output table
            outputScroll.topAnchor.constraint(equalTo: outputLabel.bottomAnchor, constant: spacing),
            outputScroll.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: margin),
            outputScroll.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -margin),
            outputScroll.heightAnchor.constraint(equalTo: inputScroll.heightAnchor),

            // Output buttons
            outputButtons.topAnchor.constraint(equalTo: outputScroll.bottomAnchor, constant: 4),
            outputButtons.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: margin),
            outputButtons.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -margin),

            // Hint
            hint.topAnchor.constraint(equalTo: outputButtons.bottomAnchor, constant: 16),
            hint.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: margin),
            hint.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -margin),

            // Buttons row
            saveButton.topAnchor.constraint(equalTo: hint.bottomAnchor, constant: 12),
            saveButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -margin),
            saveButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -margin),

            cancelButton.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -8),
            cancelButton.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
        ])
    }

    // MARK: - UI Helpers

    private func makeLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func makeTable(tag: Int) -> (NSScrollView, NSTableView) {
        let tableView = NSTableView()
        tableView.tag = tag
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.rowHeight = 26
        tableView.gridStyleMask = []
        tableView.allowsMultipleSelection = false
        tableView.registerForDraggedTypes([.string])
        tableView.draggingDestinationFeedbackStyle = .gap
        tableView.style = .plain
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("device"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        return (scrollView, tableView)
    }

    private func makeButtonBar(tag: Int) -> NSView {
        let bar = NSView()
        bar.translatesAutoresizingMaskIntoConstraints = false

        let addBtn = makeSmallButton(systemSymbol: "plus", action: #selector(addDevice(_:)), tag: tag)
        let removeBtn = makeSmallButton(systemSymbol: "minus", action: #selector(removeDevice(_:)), tag: tag)
        let upBtn = makeSmallButton(systemSymbol: "chevron.up", action: #selector(moveItemUp(_:)), tag: tag)
        let downBtn = makeSmallButton(systemSymbol: "chevron.down", action: #selector(moveItemDown(_:)), tag: tag)

        bar.addSubview(addBtn)
        bar.addSubview(removeBtn)
        bar.addSubview(upBtn)
        bar.addSubview(downBtn)

        NSLayoutConstraint.activate([
            bar.heightAnchor.constraint(equalToConstant: 24),

            addBtn.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            addBtn.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            removeBtn.leadingAnchor.constraint(equalTo: addBtn.trailingAnchor, constant: 1),
            removeBtn.centerYAnchor.constraint(equalTo: bar.centerYAnchor),

            downBtn.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            downBtn.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            upBtn.trailingAnchor.constraint(equalTo: downBtn.leadingAnchor, constant: -1),
            upBtn.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
        ])

        return bar
    }

    private func makeSmallButton(systemSymbol: String, action: Selector, tag: Int) -> NSButton {
        let btn = NSButton()
        btn.image = NSImage(systemSymbolName: systemSymbol, accessibilityDescription: nil)
        btn.bezelStyle = .recessed
        btn.isBordered = true
        btn.target = self
        btn.action = action
        btn.tag = tag
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 36).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return btn
    }

    private func list(for tag: Int) -> [String] {
        tag == 0 ? inputList : outputList
    }

    private func setList(_ list: [String], for tag: Int) {
        if tag == 0 { inputList = list } else { outputList = list }
    }

    private func tableView(for tag: Int) -> NSTableView {
        tag == 0 ? inputTableView : outputTableView
    }

    // MARK: - Actions

    @objc private func moveItemUp(_ sender: NSButton) {
        let tv = tableView(for: sender.tag)
        let row = tv.selectedRow
        guard row > 0 else { return }
        var items = list(for: sender.tag)
        items.swapAt(row, row - 1)
        setList(items, for: sender.tag)
        tv.reloadData()
        tv.selectRowIndexes(IndexSet(integer: row - 1), byExtendingSelection: false)
    }

    @objc private func moveItemDown(_ sender: NSButton) {
        let tv = tableView(for: sender.tag)
        let row = tv.selectedRow
        let items = list(for: sender.tag)
        guard row >= 0, row < items.count - 1 else { return }
        var mutable = items
        mutable.swapAt(row, row + 1)
        setList(mutable, for: sender.tag)
        tv.reloadData()
        tv.selectRowIndexes(IndexSet(integer: row + 1), byExtendingSelection: false)
    }

    @objc private func addDevice(_ sender: NSButton) {
        let isInput = sender.tag == 0
        pendingAddTag = sender.tag
        let currentList = list(for: sender.tag)
        let connected = isInput
            ? AudioManager.shared.getInputDevices()
            : AudioManager.shared.getOutputDevices()

        let available = connected.filter { !currentList.contains($0.name) }

        if available.isEmpty {
            let alert = NSAlert()
            alert.messageText = "No additional devices"
            alert.informativeText = "All connected \(isInput ? "input" : "output") devices are already in the priority list."
            alert.beginSheetModal(for: self.window!)
            return
        }

        let menu = NSMenu()
        for device in available {
            let item = NSMenuItem(
                title: "\(device.name) — \(device.transportName)",
                action: #selector(addDeviceFromMenu(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = device.name
            menu.addItem(item)
        }

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
    }

    @objc private func addDeviceFromMenu(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        let tag = pendingAddTag
        var items = list(for: tag)
        items.append(name)
        setList(items, for: tag)
        tableView(for: tag).reloadData()
    }

    @objc private func removeDevice(_ sender: NSButton) {
        let tv = tableView(for: sender.tag)
        let row = tv.selectedRow
        guard row >= 0 else { return }
        var items = list(for: sender.tag)
        items.remove(at: row)
        setList(items, for: sender.tag)
        tv.reloadData()
    }

    @objc private func saveAction() {
        let config = DeviceConfig(audioInput: inputList, audioOutput: outputList)
        config.save()
        onSave?()
        close()
    }

    @objc private func cancelAction() {
        close()
    }
}

// MARK: - NSTableViewDataSource & Delegate

extension ConfigWindowController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        list(for: tableView.tag).count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let items = list(for: tableView.tag)

        let cell = NSTableCellView()
        let text = NSTextField(labelWithString: "\(row + 1).  \(items[row])")
        text.font = .systemFont(ofSize: 13)
        text.lineBreakMode = .byTruncatingTail
        text.translatesAutoresizingMaskIntoConstraints = false

        cell.addSubview(text)
        NSLayoutConstraint.activate([
            text.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
            text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
            text.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])

        return cell
    }

    // Drag & drop reordering
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        item.setString(String(row), forType: .string)
        return item
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if dropOperation == .above { return .move }
        return []
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let item = info.draggingPasteboard.pasteboardItems?.first,
              let rowStr = item.string(forType: .string),
              let sourceRow = Int(rowStr) else { return false }

        var items = list(for: tableView.tag)
        let moved = items.remove(at: sourceRow)
        let dest = sourceRow < row ? row - 1 : row
        items.insert(moved, at: dest)
        setList(items, for: tableView.tag)
        tableView.reloadData()
        tableView.selectRowIndexes(IndexSet(integer: dest), byExtendingSelection: false)
        return true
    }
}
