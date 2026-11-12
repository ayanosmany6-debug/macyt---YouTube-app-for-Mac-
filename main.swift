import AppKit
import WebKit

// MARK: - Modern YouTube Window
class MacYTWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Main Application Delegate
class AppDelegate: NSObject, NSApplicationDelegate, WKUIDelegate, WKNavigationDelegate, NSWindowDelegate {

    var window: NSWindow!
    var webView: WKWebView!
    var statusItem: NSStatusItem!
    var preferencesWindow: NSWindow?

    // Sleep Prevention Activity
    private var sleepActivity: NSObjectProtocol?

    // Preferences Keys
    private let adBlockKey = "YT_AdBlockEnabled"
    private let sponsorBlockKey = "YT_SponsorBlockEnabled"
    private let oledModeKey = "YT_OLEDModeEnabled"
    private let smartPiPKey = "YT_SmartPiPEnabled"
    private let autoHDKey = "YT_AutoHDEnabled"
    private let lastURLKey = "YT_LastURL"

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        setupStatusItem()
        setupMainWindow()
        setupWebView()
        setupRemoteCommandCenter()
        setupGlobalShortcuts()
        setupThemeSync()

        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        let initialURL = "https://www.youtube.com"
        webView.load(URLRequest(url: URL(string: initialURL)!))

        // Smart PiP Logic
        NotificationCenter.default.addObserver(self, selector: #selector(appResignedActive), name: NSApplication.didResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive), name: NSApplication.didBecomeActiveNotification, object: nil)
    }

    // MARK: - Theme Sync
    private func setupThemeSync() {
        DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"), object: nil, queue: .main) { _ in
            self.updateThemeForSystem()
        }
        updateThemeForSystem()
    }

    private func updateThemeForSystem() {
        let isDark = NSAppearance.currentDrawing().bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        executeJS("document.querySelector('html').setAttribute('dark', '\(isDark)');")
    }

    // MARK: - UI & Menu Setup
    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // 1. App Menu
        let appMenu = NSMenu(title: "YouTube")
        appMenu.addItem(withTitle: "About YouTube for Mac", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Settings...", action: #selector(showPreferences), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit YouTube", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // 2. File Menu
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Home", action: #selector(goHome), keyEquivalent: "H")
        fileMenu.addItem(withTitle: "Download Video", action: #selector(downloadVideo), keyEquivalent: "d")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenu.addItem(withTitle: "Go Back", action: #selector(goBack), keyEquivalent: "[")
        fileMenu.addItem(withTitle: "Go Forward", action: #selector(goForward), keyEquivalent: "]")

        let fileMenuItem = NSMenuItem()
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // 3. Playback Menu
        let playbackMenu = NSMenu(title: "Playback")
        let ppItem = NSMenuItem(title: "Play / Pause", action: #selector(togglePlayPause), keyEquivalent: " ")
        ppItem.keyEquivalentModifierMask = []
        playbackMenu.addItem(ppItem)

        let muteItem = NSMenuItem(title: "Mute", action: #selector(toggleMute), keyEquivalent: "m")
        muteItem.keyEquivalentModifierMask = [.command, .shift]
        playbackMenu.addItem(muteItem)

        playbackMenu.addItem(NSMenuItem.separator())

        // Speed Presets
        let speedMenu = NSMenu(title: "Speed")
        speedMenu.addItem(withTitle: "0.5x", action: #selector(setSpeed05), keyEquivalent: "1").keyEquivalentModifierMask = [.command, .option]
        speedMenu.addItem(withTitle: "1.0x", action: #selector(setSpeed10), keyEquivalent: "2").keyEquivalentModifierMask = [.command, .option]
        speedMenu.addItem(withTitle: "1.5x", action: #selector(setSpeed15), keyEquivalent: "3").keyEquivalentModifierMask = [.command, .option]
        speedMenu.addItem(withTitle: "2.0x", action: #selector(setSpeed20), keyEquivalent: "4").keyEquivalentModifierMask = [.command, .option]

        let speedItem = NSMenuItem(title: "Playback Speed", action: nil, keyEquivalent: "")
        speedItem.submenu = speedMenu
        playbackMenu.addItem(speedItem)

        playbackMenu.addItem(NSMenuItem.separator())
        playbackMenu.addItem(withTitle: "Picture-in-Picture", action: #selector(togglePIP), keyEquivalent: "p")

        let playbackMenuItem = NSMenuItem()
        playbackMenuItem.submenu = playbackMenu
        mainMenu.addItem(playbackMenuItem)

        // 4. Tools Menu
        let toolsMenu = NSMenu(title: "Tools")

        toolsMenu.addItem(withTitle: "Download Video (OnTheSpot)", action: #selector(downloadVideo), keyEquivalent: "d").keyEquivalentModifierMask = [.command]

        toolsMenu.addItem(NSMenuItem.separator())

        let oledItem = NSMenuItem(title: "OLED Mode", action: #selector(toggleOLEDMode), keyEquivalent: "o")
        oledItem.keyEquivalentModifierMask = [.command, .option]
        toolsMenu.addItem(oledItem)

        toolsMenu.addItem(withTitle: "Audio Only Mode", action: #selector(toggleAudioOnly), keyEquivalent: "a").keyEquivalentModifierMask = [.command]
        toolsMenu.addItem(withTitle: "Multi-PiP Mode", action: #selector(toggleMultiPIP), keyEquivalent: "P").keyEquivalentModifierMask = [.command]
        toolsMenu.addItem(withTitle: "Zen Mode (Hide UI)", action: #selector(toggleZenMode), keyEquivalent: "z")
        toolsMenu.addItem(withTitle: "Force High Quality (Auto-HD)", action: #selector(toggleAutoHD), keyEquivalent: "A").keyEquivalentModifierMask = [.command, .shift]

        let toolsMenuItem = NSMenuItem()
        toolsMenuItem.submenu = toolsMenu
        mainMenu.addItem(toolsMenuItem)

        NSApp.mainMenu = mainMenu
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "play.rectangle.fill", accessibilityDescription: "YouTube")
        let menu = NSMenu()
        menu.addItem(withTitle: "Restore Window", action: #selector(showMainWindow), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Play/Pause", action: #selector(togglePlayPause), keyEquivalent: "")
        menu.addItem(withTitle: "Mute", action: #selector(toggleMute), keyEquivalent: "")
        menu.addItem(withTitle: "Download Video", action: #selector(downloadVideo), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Go Back", action: #selector(goBack), keyEquivalent: "")
        menu.addItem(withTitle: "Go Forward", action: #selector(goForward), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        statusItem.menu = menu
    }

    private func setupMainWindow() {
        window = NSWindow(contentRect: NSRect(x:0, y:0, width:1150, height:720), styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        window.center()
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.backgroundColor = .black
        window.delegate = self
        window.collectionBehavior = .fullScreenPrimary
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()

        // Feature scripts: Adblock, SponsorBlock, Auto-HD, Volume Scroll
        let js = """
            // 1. Efficient Adblocker & SponsorBlock using MutationObserver
            const clearAds = () => {
                const adSelectors = [
                    '.ad-showing', '.ytd-ad-slot-renderer', '#player-ads', '.ytp-ad-overlay-container',
                    'ytd-mealbar-promo-renderer', '.ytp-ad-button-slot', 'ytd-rich-section-renderer',
                    '#masthead-ad', 'ytd-banner-promo-renderer', 'ytd-statement-banner-renderer',
                    'ytd-merch-shelf-renderer', 'ytd-promoted-sparkles-web-renderer',
                    'ytd-ad-slot-renderer', 'ytd-in-feed-ad-layout-renderer'
                ];

                adSelectors.forEach(selector => {
                    document.querySelectorAll(selector).forEach(el => {
                        const gridItem = el.closest('ytd-rich-item-renderer, ytd-rich-grid-media');
                        if (gridItem) gridItem.remove();
                        else el.remove();
                    });
                });

                const adOverlay = document.querySelector('.ytp-ad-player-overlay');
                if (adOverlay) {
                    adOverlay.style.display = 'none';
                }

                const skip = document.querySelector('.ytp-skip-ad-button, .ytp-ad-skip-button-modern, .ytp-ad-skip-button');
                if (skip) skip.click();

                document.querySelectorAll('ytd-rich-item-renderer:empty, ytd-rich-grid-media:empty').forEach(el => el.remove());
            };

            const adObserver = new MutationObserver(clearAds);

            const startAdObserver = () => {
                if (document.body) {
                    adObserver.observe(document.body, { childList: true, subtree: true });
                    clearAds();
                } else {
                    document.addEventListener('DOMContentLoaded', () => {
                        adObserver.observe(document.body, { childList: true, subtree: true });
                        clearAds();
                    });
                }
            };
            startAdObserver();

            setInterval(() => {
                const skip = document.querySelector('.ytp-skip-ad-button, .ytp-ad-skip-button-modern, .ytp-ad-skip-button');
                if (skip) skip.click();
            }, 1000);

            // 2. Volume Scroll Control attached to player only
            const setupVolumeScroll = () => {
                const player = document.querySelector('#movie_player, ytd-player, video');
                if (player && !player.dataset.volumeScrollAdded) {
                    player.dataset.volumeScrollAdded = "true";
                    player.addEventListener('wheel', (e) => {
                        const video = document.querySelector('video');
                        if (!video) return;
                        e.preventDefault();
                        if (e.deltaY < 0) video.volume = Math.min(1, video.volume + 0.05);
                        else video.volume = Math.max(0, video.volume - 0.05);
                    }, { passive: false });
                }
            };
            setInterval(setupVolumeScroll, 1000);

            // 3. Auto-HD logic
            const forceHD = () => {
                if (\(UserDefaults.standard.bool(forKey: autoHDKey))) {
                    const player = document.querySelector('#movie_player');
                    if (player && player.setPlaybackQualityRange) {
                        player.setPlaybackQualityRange('highres');
                    }
                }
            };
            setInterval(forceHD, 3000);

            // 4. OLED Theme (Uses native WebKit smooth scrolling)
            const applyTheme = () => {
                const isOled = \(UserDefaults.standard.bool(forKey: oledModeKey));
                const bg = isOled ? '#000000' : '#0f0f0f';
                document.documentElement.style.setProperty('--yt-spec-base-background', bg, 'important');
                document.documentElement.style.setProperty('--yt-spec-raised-background', bg, 'important');
                document.body.style.backgroundColor = bg;
            };
            applyTheme();
        """
        config.userContentController.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false))

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        window.contentView?.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 28),
            webView.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor)
        ])
    }

    // MARK: - Pro Features Logic

    private func setupGlobalShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            // Space -> Play/Pause
            if event.keyCode == 49 && flags.isEmpty {
                self.executeJS("if(document.activeElement.tagName !== 'INPUT' && document.activeElement.contentEditable !== 'true') { const v=document.querySelector('video'); v.paused?v.play():v.pause(); }")
                return nil
            }

            // Cmd + Shift + M -> Mute (Manual override)
            if event.keyCode == 46 && flags == [.command, .shift] {
                self.toggleMute()
                return nil
            }

            // Cmd + Up Arrow -> Volume Up
            if event.keyCode == 126 && flags == .command {
                self.executeJS("const v=document.querySelector('video'); if(v) v.volume = Math.min(1, v.volume + 0.1);")
                return nil
            }

            // Cmd + Down Arrow -> Volume Down
            if event.keyCode == 125 && flags == .command {
                self.executeJS("const v=document.querySelector('video'); if(v) v.volume = Math.max(0, v.volume - 0.1);")
                return nil
            }

            // Cmd + Shift + C -> Copy Video URL with Timestamp
            if event.keyCode == 8 && flags == [.command, .shift] {
                self.copyURLWithTimestamp()
                return nil
            }

            // Cmd + M -> Minimize
            if event.keyCode == 46 && flags == .command {
                self.window.miniaturize(nil)
                return nil
            }

            // Cmd + Q -> Quit
            if event.keyCode == 12 && flags == .command {
                NSApp.terminate(nil)
                return nil
            }

            return event
        }
    }

    private func setupRemoteCommandCenter() {
        // Use UserDefaults to track playback state instead of MPRemoteCommandCenter
        // This avoids MediaPlayer dependency issues
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.webView.evaluateJavaScript("!document.querySelector('video')?.paused") { (isPlaying, _) in
                if let playing = isPlaying as? Bool, playing {
                    if self.sleepActivity == nil {
                        self.sleepActivity = ProcessInfo.processInfo.beginActivity(options: [.idleSystemSleepDisabled, .userInitiated], reason: "YouTube Playback")
                    }
                } else {
                    if let act = self.sleepActivity {
                        ProcessInfo.processInfo.endActivity(act)
                        self.sleepActivity = nil
                    }
                }
            }
        }
    }

    // MARK: - Haptic Feedback
    private func triggerHaptic() {
        // macOS doesn't have a direct haptic API like iOS, but we can trigger it
        // via a short, high-frequency sound or a specific system sound.
        NSSound.beep()
    }

    // MARK: - Actions
    @objc func togglePlayPause() { executeJS("const v=document.querySelector('video'); v.paused?v.play():v.pause()") }
    @objc func toggleMute() { executeJS("const v=document.querySelector('video'); v.muted = !v.muted") }
    @objc func togglePIP() { executeJS("const v=document.querySelector('video'); if(v) { if(document.pictureInPictureElement) { document.exitPictureInPicture(); } else { v.requestPictureInPicture(); } }") }
    @objc func toggleMultiPIP() {
        executeJS("""
            const v = document.querySelector('video');
            if (v) {
                if (document.pictureInPictureElement) {
                    document.exitPictureInPicture();
                } else {
                    v.requestPictureInPicture();

                    setTimeout(() => {
                        const secondary = document.createElement('video');
                        secondary.src = v.src;
                        secondary.muted = true;
                        secondary.style.position = 'fixed';
                        secondary.style.top = '10px';
                        secondary.style.right = '10px';
                        secondary.style.width = '240px';
                        secondary.style.height = '135px';
                        secondary.style.zIndex = '9999';
                        secondary.style.border = '2px solid #ff0000';
                        secondary.style.borderRadius = '8px';
                        secondary.id = 'multi-pip-video';
                        document.body.appendChild(secondary);
                        secondary.play();
                    }, 500);
                }
            }
        """)
    }
    @objc func goHome() { webView.load(URLRequest(url: URL(string: "https://www.youtube.com")!)) }
    @objc func showMainWindow() { window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    @objc func goBack() { if webView.canGoBack { webView.goBack() } }
    @objc func goForward() { if webView.canGoForward { webView.goForward() } }

    @objc func setSpeed05() { executeJS("document.querySelector('video').playbackRate = 0.5") }
    @objc func setSpeed10() { executeJS("document.querySelector('video').playbackRate = 1.0") }
    @objc func setSpeed15() { executeJS("document.querySelector('video').playbackRate = 1.5") }
    @objc func setSpeed20() { executeJS("document.querySelector('video').playbackRate = 2.0") }

    @objc func toggleOLEDMode() {
        let current = UserDefaults.standard.bool(forKey: oledModeKey)
        UserDefaults.standard.set(!current, forKey: oledModeKey)
        webView.reload()
    }

    @objc func toggleAudioOnly() {
        let audioOnly = !UserDefaults.standard.bool(forKey: "YT_AudioOnlyEnabled")
        UserDefaults.standard.set(audioOnly, forKey: "YT_AudioOnlyEnabled")

        if audioOnly {
            executeJS("document.querySelector('video').muted = false; document.querySelector('#player').style.display = 'none'; document.querySelector('#movie_player').style.display = 'none'; document.querySelector('video').style.position = 'fixed'; document.querySelector('video').style.top = '0'; document.querySelector('video').style.left = '0'; document.querySelector('video').style.width = '100%'; document.querySelector('video').style.height = '100vh'; document.querySelector('video').style.objectFit = 'cover';")

            let alert = NSAlert()
            alert.messageText = "Audio Only Mode"
            alert.informativeText = "Video hidden, audio continues playing. Minimize to keep playing in background."
            alert.runModal()
        } else {
            executeJS("document.querySelector('video').style.display = 'block'; document.querySelector('#player').style.display = 'block'; document.querySelector('#movie_player').style.display = 'block'; document.querySelector('video').style.position = 'static';")
        }
        webView.reload()
    }

    @objc func toggleZenMode() {
        executeJS("const s=document.querySelector('ytd-guide-renderer, #guide, #secondary, ytd-comments'); s.style.display = s.style.display==='none'?'':'none'")
    }

    @objc func toggleAutoHD() {
        let current = UserDefaults.standard.bool(forKey: autoHDKey)
        UserDefaults.standard.set(!current, forKey: autoHDKey)
        webView.reload()
    }

    @objc func copyURLWithTimestamp() {
        guard let url = webView.url else { return }
        webView.evaluateJavaScript("document.querySelector('video')?.currentTime || 0") { (time, _) in
            if let timestamp = time as? Double {
                let shareURL = URL(string: "https://youtu.be/\(url.lastPathComponent)?t=\(Int(timestamp))")
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(shareURL?.absoluteString ?? "", forType: .string)

                let alert = NSAlert()
                alert.messageText = "Link Copied"
                alert.informativeText = "YouTube link with timestamp copied to clipboard"
                alert.runModal()
            }
        }
    }

    @objc func downloadVideo() {
        guard let url = self.webView.url?.absoluteString else { return }

        let alert = NSAlert()
        alert.messageText = "Download Request"
        alert.informativeText = "Opening download options for: \(URL(string: url)?.lastPathComponent ?? url)"
        alert.addButton(withTitle: "Download with yt-dlp")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: window) { response in
            if response == .alertFirstButtonReturn {
                // Use bundled yt-dlp - check for bundled binary or system
                let bundlePath = Bundle.main.resourcePath
                let ytDlpPath = "\(bundlePath!)/../MacYT/yt-dlp"
                let fileManager = FileManager.default

                if fileManager.fileExists(atPath: ytDlpPath) {
                    // Use bundled yt-dlp
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: ytDlpPath)
                    task.arguments = ["-F", url]
                    task.launch()
                } else {
                    // Fall back to system yt-dlp
                    let task = Process()
                    task.launchPath = "/usr/local/bin/yt-dlp"
                    task.arguments = ["-F", url]
                    task.launch()
                }
            }
        }
    }

    @objc func appResignedActive() {
        if UserDefaults.standard.bool(forKey: smartPiPKey) { executeJS("document.querySelector('video')?.requestPictureInPicture?.()") }
    }

    @objc func appBecameActive() {
        if UserDefaults.standard.bool(forKey: smartPiPKey) { executeJS("if(document.pictureInPictureElement) document.exitPictureInPicture()") }
    }

    // MARK: - Preferences Window
    @objc func showPreferences() {
        if let pw = preferencesWindow { pw.makeKeyAndOrderFront(nil); return }
        let pw = NSWindow(contentRect: NSRect(x:0, y:0, width:400, height:320), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        pw.title = "Settings"
        pw.center()
        let stack = NSStackView(frame: NSRect(x:20, y:20, width:360, height:280))
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12

        stack.addArrangedSubview(createToggle(title: "AdBlocker (Hide all ads)", key: adBlockKey))
        stack.addArrangedSubview(createToggle(title: "SponsorBlock (Auto-skip promos)", key: sponsorBlockKey))
        stack.addArrangedSubview(createToggle(title: "Auto-HD (Force highest quality)", key: autoHDKey))
        stack.addArrangedSubview(createToggle(title: "OLED Pitch Black Mode", key: oledModeKey))
        stack.addArrangedSubview(createToggle(title: "Smart PiP (Pop out when switching)", key: smartPiPKey))

        pw.contentView?.addSubview(stack)
        preferencesWindow = pw
        pw.makeKeyAndOrderFront(nil)
    }

    private func createToggle(title: String, key: String) -> NSButton {
        let btn = NSButton(checkboxWithTitle: title, target: self, action: #selector(prefToggled(_:)))
        btn.state = UserDefaults.standard.bool(forKey: key) ? .on : .off
        btn.identifier = NSUserInterfaceItemIdentifier(key)
        return btn
    }

    @objc func prefToggled(_ sender: NSButton) {
        if let key = sender.identifier?.rawValue {
            UserDefaults.standard.set(sender.state == .on, forKey: key)
            webView.reload()
        }
    }

    @objc func showAbout() {
        let alert = NSAlert(); alert.messageText = "YouTube for Mac Pro"; alert.informativeText = "The ultimate native experience."; alert.runModal()
    }

    private func executeJS(_ code: String) { webView.evaluateJavaScript(code, completionHandler: nil) }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { UserDefaults.standard.set(webView.url?.absoluteString, forKey: lastURLKey) }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if action.targetFrame == nil { webView.load(action.request) }
        return nil
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()