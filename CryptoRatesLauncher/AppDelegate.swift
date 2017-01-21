//
//  AppDelegate.swift
//  CryptoRatesLauncher
//
//  Created by Pierluigi D'Andrea on 20/01/17.
//  Copyright © 2017 pNre. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        NSWorkspace.shared().open(URL(string: "cryptorates://")!)
        NSApp.terminate(nil)

    }

}
