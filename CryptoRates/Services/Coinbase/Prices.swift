//
//  Prices.swift
//  CryptoRates
//
//  Created by Pierluigi D'Andrea on 14/01/17.
//  Copyright © 2017 pNre. All rights reserved.
//

import Foundation
import Moya

enum Prices {

    case buy(currency: String)
    case sell(currency: String)
    case spot(currency: String)

}

extension Prices: TargetType {

    var baseURL: URL {
        return URL(string: "https://api.coinbase.com/v2/prices")!
    }

    var path: String {
        switch self {
        case .buy:
            return "/buy"
        case .sell:
            return "/sell"
        case .spot:
            return "/spot"
        }
    }

    var method: Moya.Method {
        return .get
    }

    var parameters: [String : Any]? {
        switch self {
        case .buy(let currency),
             .sell(let currency),
             .spot(let currency):
            return ["currency": currency]
        }
    }

    var sampleData: Data {
        fatalError("No sample data")
    }

    var task: Task {
        return .request
    }

    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }

}
