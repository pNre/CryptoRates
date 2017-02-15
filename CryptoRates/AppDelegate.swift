//
//  AppDelegate.swift
//  CryptoRates
//
//  Created by Pierluigi D'Andrea on 14/01/17.
//  Copyright © 2017 pNre. All rights reserved.
//

import Cocoa
import Moya
import ObjectMapper
import ReactiveCocoa
import ReactiveSwift
import ReactiveMoya
import Result
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: Properties
    @IBOutlet weak var mainMenu: NSMenu!
    @IBOutlet weak var lastUpdateItem: NSMenuItem!
    @IBOutlet weak var toggleStartupLaunchItem: NSMenuItem! {
        didSet {
            toggleStartupLaunchItem.state = isLaunchedOnLogin ? NSOnState : NSOffState
        }
    }

    /// Status bar item
    private lazy var statusItem: NSStatusItem = {

        let item = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
        item.menu = self.mainMenu

        return item

    }()

    /// Last update date formatter
    private lazy var dateFormatter: DateFormatter = {

        let formatter = DateFormatter()

        formatter.dateStyle = .short
        formatter.timeStyle = .short

        return formatter

    }()

    /// Time interval between price updates
    fileprivate let updateInterval: MutableProperty<DispatchTimeInterval> = MutableProperty(.seconds(60))

    /// Currency to request the exchange rates for
    fileprivate let currency: MutableProperty<String> = MutableProperty(Locale.current.currencyCode ?? "EUR")

    /// Formatted buy and sell prices
    private lazy var prices: Property<(buy: String?, sell: String?)> = {

        let buy = self.priceProducer(for: { .buy(currency: $0) })
        let sell = self.priceProducer(for: { .sell(currency: $0) })

        let producer = SignalProducer.combineLatest(buy, sell)
            .map { (buy: $0, sell: $1) }

        return Property(initial: (buy: nil, sell: nil), then: producer)

    }()

    /// Provider for the Coinbase price API
    fileprivate lazy var provider: ReactiveSwiftMoyaProvider<Prices> = {

        return ReactiveSwiftMoyaProvider<Prices>(endpointClosure: { (target: Prices) -> Endpoint<Prices> in
            let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
            return defaultEndpoint.adding(newHTTPHeaderFields: ["CB-VERSION": "2017-01-14"])
        })

    }()

    // MARK: AppDelegate
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        prices.producer
            .skip(while: { $0?.isEmpty != false || $1?.isEmpty != false })
            .observe(on: UIScheduler())
            .startWithResult { [weak self] result in
                guard case .success(.some(let buy), .some(let sell)) = result else {
                    return
                }

                self?.statusItem.attributedTitle = AppDelegate.statusItemTitleFor(buy: buy, sell: sell)

                if let date = self?.dateFormatter.string(from: Date()) {
                    self?.lastUpdateItem.title = "Last update: \(date)"
                } else {
                    self?.lastUpdateItem.title = "Last update: unknown"
                }
            }

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}

// MARK: - Requests
extension AppDelegate {

    /// Formatted "sell" price
    fileprivate func priceProducer(for target: @escaping (String) -> Prices) -> SignalProducer<String?, NoError> {

        let provider = self.provider

        return SignalProducer.combineLatest(self.updateInterval.producer, self.currency.producer)
            .flatMap(.latest) { interval, currency -> SignalProducer<String?, NoError> in

                return timer(interval: interval, on: QueueScheduler())
                    .prefix(value: Date())
                    .flatMap(.latest) { _ -> SignalProducer<String?, NoError> in

                        return provider.request(target(currency))
                            .map(AppDelegate.map)
                            .flatMapError { _ -> SignalProducer<String?, NoError> in .empty }

                    }

            }

    }

    fileprivate static func map(response: Response) -> String? {

        guard let string = try? response.mapString() else {
            return nil
        }

        return (try? Mapper<PricesResponse>().map(JSONString: string))?.amount.currencyString

    }

}

// MARK: - Actions
extension AppDelegate {

    @IBAction func quitAction(_ sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }

    @IBAction func toggleStartupLaunchItemAction(_ sender: NSMenuItem) {

        let shouldEnable = !isLaunchedOnLogin

        guard SMLoginItemSetEnabled("com.pNre.CryptoRatesLauncher" as CFString, shouldEnable) else {
            return
        }

        sender.state = shouldEnable ? NSOnState : NSOffState

    }

}

// MARK: - Formatting
extension AppDelegate {

    fileprivate static func statusItemTitleFor(buy: String, sell: String) -> NSAttributedString {

        let title = "↓ \(buy) ⬝ ↑ \(sell)"
        let attributes = [NSFontAttributeName: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize())]

        return NSAttributedString(string: title, attributes: attributes)

    }

}

// MARK: - Launch items
extension AppDelegate {

    fileprivate var isLaunchedOnLogin: Bool {

        let dictionaries = SMCopyAllJobDictionaries(kSMDomainUserLaunchd).takeRetainedValue()

        guard let jobs = dictionaries as NSArray as? [[String: AnyObject]], !jobs.isEmpty else {
            return false
        }

        return jobs.contains { $0["Label"] as? String == "com.pNre.CryptoRatesLauncher" && $0["OnDemand"] as? Bool == true }

    }

}
