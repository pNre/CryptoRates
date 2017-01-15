//
//  PricesResponse.swift
//  CryptoRates
//
//  Created by Pierluigi D'Andrea on 14/01/17.
//  Copyright © 2017 pNre. All rights reserved.
//

import Foundation
import ObjectMapper

struct PricesResponse: ImmutableMappable {

    let amount: NSDecimalNumber
    let currency: String

    init(map: Map) throws {

        amount = try map.value("data.amount", using: NSDecimalNumberTransform())
        currency = try map.value("data.currency")

    }

}
