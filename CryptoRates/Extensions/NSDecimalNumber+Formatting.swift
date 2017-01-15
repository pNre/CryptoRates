//
//  NSDecimalNumber+Formatting.swift
//  CryptoRates
//
//  Created by Pierluigi D'Andrea on 15/01/17.
//  Copyright © 2017 pNre. All rights reserved.
//

import Foundation

extension NSDecimalNumber {

    /// Number formatter used for currency amounts
    private static let currencyFormatter: NumberFormatter = {

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency

        return formatter

    }()

    /// Updates the locale of the currency formatter
    ///
    /// - Parameter locale: Locale
    static func setCurrencyFormatterLocale(_ locale: Locale) {
        currencyFormatter.locale = locale
    }

    /// Receiver formatted as a currency
    var currencyString: String? {
        return NSDecimalNumber.currencyFormatter.string(from: self)
    }

}
