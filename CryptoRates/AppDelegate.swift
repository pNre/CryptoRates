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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: Properties

    /// Status bar item
    private lazy var statusItem: NSStatusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)

    /// Time interval between price updates
    fileprivate let updateInterval: MutableProperty<TimeInterval> = MutableProperty(60)

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
                guard case .success(let buy, let sell) = result else {
                    return
                }

                let title = "↓ \(buy ?? "?") ⬝ ↑ \(sell ?? "?")"
                let attributedTitle = NSAttributedString(string: title,
                                                         attributes: [NSFontAttributeName: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize())])

                self?.statusItem.attributedTitle = attributedTitle
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
                return provider.request(target(currency)).producer
                    .map { response -> String? in
                        guard let string = try? response.mapString() else {
                            return nil
                        }

                        let price = try? Mapper<PricesResponse>().map(JSONString: string)
                        return price?.amount.currencyString
                    }
                    .flatMapError { _ -> SignalProducer<String?, NoError> in .empty }
            }

    }

}