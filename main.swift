import AppKit
import ServiceManagement

final class CPUMonitor {
    private var previous: host_cpu_load_info?

    func usage() -> Double {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        defer { previous = info }
        guard let prev = previous else { return 0 }
        let user = Double(info.cpu_ticks.0 &- prev.cpu_ticks.0)
        let system = Double(info.cpu_ticks.1 &- prev.cpu_ticks.1)
        let idle = Double(info.cpu_ticks.2 &- prev.cpu_ticks.2)
        let nice = Double(info.cpu_ticks.3 &- prev.cpu_ticks.3)
        let total = user + system + idle + nice
        return total > 0 ? (user + system + nice) / total * 100 : 0
    }

    func memoryUsage() -> (used: Double, total: Double) {
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, total) }
        let page = Double(vm_kernel_page_size)
        let used = Double(stats.active_count + stats.wire_count + stats.compressor_page_count) * page
        return (used, total)
    }

    func swapUsage() -> (used: Double, total: Double) {
        var swap = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        guard sysctlbyname("vm.swapusage", &swap, &size, nil, 0) == 0 else { return (0, 0) }
        return (Double(swap.xsu_used), Double(swap.xsu_total))
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let monitor = CPUMonitor()
    private var frames: [NSImage] = []
    private var frameIndex = 0
    private var cpu = 0.0
    private var animationTimer: Timer?
    private var sampleTimer: Timer?
    private let cpuItem = NSMenuItem(title: "CPU: –", action: nil, keyEquivalent: "")
    private let memItem = NSMenuItem(title: "Memory: –", action: nil, keyEquivalent: "")
    private let swapItem = NSMenuItem(title: "Swap: –", action: nil, keyEquivalent: "")
    private let showTextItem = NSMenuItem(title: "Show CPU % in Menu Bar", action: #selector(toggleText), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")
    private var showText: Bool {
        get { UserDefaults.standard.bool(forKey: "showText") }
        set { UserDefaults.standard.set(newValue, forKey: "showText") }
    }
    private var character: String {
        get { UserDefaults.standard.string(forKey: "character") ?? Self.characters[0].name }
        set { UserDefaults.standard.set(newValue, forKey: "character") }
    }

    private static let characters: [(name: String, prefix: String, template: Bool)] = [
        ("Cat", "cat-frame-", true), ("Fat Bongo Cat", "bongo-frame-", true),
        ("Megumin", "megumin-", false), ("Frieren", "frieren-", false),
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem.button?.imagePosition = .imageLeading
        loadFrames()
        buildMenu()
        _ = monitor.usage()
        sampleTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.sample() }
        scheduleAnimation()
    }

    private func loadFrames() {
        let selected = Self.characters.first { $0.name == character } ?? Self.characters[0]
        frames = (Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: nil) ?? [])
            .filter { $0.lastPathComponent.hasPrefix(selected.prefix) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { url in
                guard let image = NSImage(contentsOf: url) else { return nil }
                image.size = NSSize(width: image.size.width / 2, height: image.size.height / 2)
                image.isTemplate = selected.template
                return image
            }
        frameIndex = 0
        statusItem.button?.image = frames.first
    }

    private func buildMenu() {
        let menu = NSMenu()
        menu.addItem(cpuItem)
        menu.addItem(memItem)
        menu.addItem(swapItem)
        menu.addItem(.separator())
        let characterMenu = NSMenu()
        for c in Self.characters {
            let item = NSMenuItem(title: c.name, action: #selector(selectCharacter), keyEquivalent: "")
            item.target = self
            item.state = c.name == character ? .on : .off
            characterMenu.addItem(item)
        }
        let characterItem = NSMenuItem(title: "Character", action: nil, keyEquivalent: "")
        characterItem.submenu = characterMenu
        menu.addItem(characterItem)
        showTextItem.target = self
        showTextItem.state = showText ? .on : .off
        menu.addItem(showTextItem)
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit MiniCat", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func sample() {
        cpu = monitor.usage()
        let mem = monitor.memoryUsage()
        let swap = monitor.swapUsage()
        let gb = 1_073_741_824.0
        cpuItem.title = String(format: "CPU: %.1f%%", cpu)
        memItem.title = String(format: "Memory: %.1f / %.0f GB (%.0f%%)", mem.used / gb, mem.total / gb, mem.used / mem.total * 100)
        swapItem.title = swap.total > 0
            ? String(format: "Swap: %.2f / %.2f GB", swap.used / gb, swap.total / gb)
            : "Swap: not in use"
        statusItem.button?.title = showText ? String(format: " %.0f%%", cpu) : ""
        scheduleAnimation()
    }

    private func scheduleAnimation() {
        let interval = Self.interval(for: cpu)
        if let timer = animationTimer, abs(timer.timeInterval - interval) < 0.001 { return }
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in self?.nextFrame() }
        RunLoop.main.add(animationTimer!, forMode: .common)
    }

    private static let speedCurve: [(cpu: Double, interval: Double)] = [
        (0, 0.2), (25, 0.115), (50, 0.075), (100, 0.02),
    ]

    private static func interval(for cpu: Double) -> Double {
        let load = min(100, max(0, cpu))
        for (a, b) in zip(speedCurve, speedCurve.dropFirst()) where load <= b.cpu {
            return a.interval + (load - a.cpu) / (b.cpu - a.cpu) * (b.interval - a.interval)
        }
        return speedCurve.last!.interval
    }

    private func nextFrame() {
        guard !frames.isEmpty else { return }
        frameIndex = (frameIndex + 1) % frames.count
        statusItem.button?.image = frames[frameIndex]
    }

    @objc private func toggleText() {
        showText.toggle()
        showTextItem.state = showText ? .on : .off
        statusItem.button?.title = showText ? String(format: " %.0f%%", cpu) : ""
    }

    @objc private func selectCharacter(_ sender: NSMenuItem) {
        character = sender.title
        sender.menu?.items.forEach { $0.state = $0 === sender ? .on : .off }
        loadFrames()
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSAlert(error: error).runModal()
        }
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
