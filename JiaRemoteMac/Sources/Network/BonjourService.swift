import Foundation

protocol BonjourServiceDelegate: AnyObject {
    func bonjourServiceDidPublish(_ service: BonjourService)
    func bonjourService(_ service: BonjourService, didFailToPublish error: Error)
    func bonjourService(_ service: BonjourService, didDiscoverService name: String, host: String, port: Int)
    func bonjourService(_ service: BonjourService, didRemoveService name: String)
}

extension BonjourServiceDelegate {
    func bonjourServiceDidPublish(_ service: BonjourService) {}
    func bonjourService(_ service: BonjourService, didFailToPublish error: Error) {}
    func bonjourService(_ service: BonjourService, didDiscoverService name: String, host: String, port: Int) {}
    func bonjourService(_ service: BonjourService, didRemoveService name: String) {}
}

final class BonjourService: NSObject {

    private static let serviceType = "_jiaremote._tcp."
    private static let serviceDomain = "local."
    private static let defaultPort: Int32 = 9527

    private let txtRecord: [String: Data] = [
        "ver": "1.0".data(using: .utf8)!,
        "platform": "macOS".data(using: .utf8)!
    ]

    weak var delegate: BonjourServiceDelegate?

    private var netService: NetService?
    private var serviceBrowser: NetServiceBrowser?
    private var discoveredServices: [NetService] = []

    private let serviceName: String
    private let stateQueue = DispatchQueue(label: "com.jiaremote.bonjour.state", qos: .userInitiated)

    private(set) var isPublished: Bool = false
    private(set) var isBrowsing: Bool = false

    var currentServiceName: String { serviceName }

    init(delegate: BonjourServiceDelegate? = nil) {
        self.serviceName = "JiaRemote-\(Host.current().localizedName ?? "Unknown")"
        self.delegate = delegate
        super.init()
    }

    func startPublish(port: Int32 = BonjourService.defaultPort) {
        stateQueue.async { [weak self] in
            guard let self else { return }

            if self.isPublished {
                self.stopPublish()
            }

            let service = NetService(
                domain: Self.serviceDomain,
                type: Self.serviceType,
                name: self.serviceName,
                port: port
            )

            let txtData = NetService.data(fromTXTRecord: self.txtRecord)
            service.setTXTRecord(txtData)

            service.includesPeerToPeer = true
            service.delegate = self

            self.netService = service
            service.publish()

            JiaLog("[BonjourService] Publishing \(self.serviceName) on port \(port)")
        }
    }

    func stopPublish() {
        stateQueue.async { [weak self] in
            guard let self else { return }

            self.netService?.delegate = nil
            self.netService?.stop()
            self.netService = nil
            self.isPublished = false

            JiaLog("[BonjourService] Stopped publishing")
        }
    }

    func startBrowse() {
        stateQueue.async { [weak self] in
            guard let self else { return }

            if self.isBrowsing {
                self.stopBrowse()
            }

            self.discoveredServices.removeAll()

            let browser = NetServiceBrowser()
            browser.includesPeerToPeer = true
            browser.delegate = self
            self.serviceBrowser = browser

            browser.searchForServices(ofType: Self.serviceType, inDomain: Self.serviceDomain)

            JiaLog("[BonjourService] Browsing for \(Self.serviceType) services")
        }
    }

    func stopBrowse() {
        stateQueue.async { [weak self] in
            guard let self else { return }

            self.serviceBrowser?.delegate = nil
            self.serviceBrowser?.stop()
            self.serviceBrowser = nil

            for service in self.discoveredServices {
                service.delegate = nil
                service.stop()
            }

            self.discoveredServices.removeAll()
            self.isBrowsing = false

            JiaLog("[BonjourService] Stopped browsing")
        }
    }

    deinit {
        stopPublish()
        stopBrowse()
    }
}

extension BonjourService: NetServiceDelegate {

    func netServiceDidPublish(_ sender: NetService) {
        stateQueue.async { [weak self] in
            self?.isPublished = true
        }

        JiaLog("[BonjourService] Successfully published \(sender.name)")

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.bonjourServiceDidPublish(self)
        }
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        let code = errorDict[NetService.errorCode]?.intValue ?? -1
        let domain = errorDict[NetService.errorDomain].map { "\($0)" } ?? "Unknown"
        let error = NSError(domain: "BonjourService", code: code, userInfo: [
            NSLocalizedDescriptionKey: "Failed to publish (code: \(code), domain: \(domain))"
        ])

        JiaLog("[BonjourService] Failed to publish: \(error)")

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.bonjourService(self, didFailToPublish: error)
        }
    }

    func netServiceDidStop(_ sender: NetService) {
        stateQueue.async { [weak self] in
            self?.isPublished = false
        }

        JiaLog("[BonjourService] Service stopped: \(sender.name)")
    }

    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        inputStream.close()
        outputStream.close()
    }
}

extension BonjourService: NetServiceBrowserDelegate {

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        stateQueue.async { [weak self] in
            guard let self else { return }

            if !self.discoveredServices.contains(service) {
                self.discoveredServices.append(service)
                service.delegate = self
                service.resolve(withTimeout: 5.0)
            }
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        stateQueue.async { [weak self] in
            guard let self else { return }

            if let index = self.discoveredServices.firstIndex(of: service) {
                self.discoveredServices.remove(at: index)
            }

            service.delegate = nil
            service.stop()

            let name = service.name

            JiaLog("[BonjourService] Service removed: \(name)")

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.delegate?.bonjourService(self, didRemoveService: name)
            }
        }
    }

    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        stateQueue.async { [weak self] in
            self?.isBrowsing = true
        }

        JiaLog("[BonjourService] Browser will search")
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        stateQueue.async { [weak self] in
            self?.isBrowsing = false
        }

        JiaLog("[BonjourService] Browser stopped search")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        let code = errorDict[NetService.errorCode]?.intValue ?? -1
        let domain = errorDict[NetService.errorDomain].map { "\($0)" } ?? "Unknown"

        JiaLog("[BonjourService] Browser did not search (code: \(code), domain: \(domain))")

        stateQueue.async { [weak self] in
            self?.isBrowsing = false
        }
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let addresses = sender.addresses, !addresses.isEmpty else {
            JiaLog("[BonjourService] No addresses resolved for \(sender.name)")
            return
        }

        let name = sender.name
        let port = Int(sender.port)

        var resolvedHost = name
        for addressData in addresses {
            let sockaddr = addressData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> sockaddr_in in
                ptr.load(as: sockaddr_in.self)
            }

            var hostBuffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            var addr = sockaddr.sin_addr

            if let cString = inet_ntop(AF_INET, &addr, &hostBuffer, socklen_t(INET_ADDRSTRLEN)) {
                let ipString = String(cString: cString)
                if ipString != "0.0.0.0" {
                    resolvedHost = ipString
                    break
                }
            }
        }

        if let txtData = sender.txtRecordData() {
            let txtDict = NetService.dictionary(fromTXTRecord: txtData)
            let entries = txtDict.map { key, value in
                "\(key)=\(String(data: value, encoding: .utf8) ?? "<data>")"
            }
            JiaLog("[BonjourService] Resolved \(name) at \(resolvedHost):\(port) TXT: {\(entries.joined(separator: ", "))}")
        }

        JiaLog("[BonjourService] Resolved \(name) at \(resolvedHost):\(port)")

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.bonjourService(self, didDiscoverService: name, host: resolvedHost, port: port)
        }
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        let code = errorDict[NetService.errorCode]?.intValue ?? -1

        JiaLog("[BonjourService] Failed to resolve \(sender.name) (code: \(code))")

        stateQueue.async { [weak self] in
            guard let self else { return }
            if let index = self.discoveredServices.firstIndex(of: sender) {
                self.discoveredServices.remove(at: index)
            }
        }

        sender.delegate = nil
        sender.stop()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.bonjourService(self, didRemoveService: sender.name)
        }
    }
}
