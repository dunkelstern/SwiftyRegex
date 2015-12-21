//
//  Package.swift
//  SwiftyRegex
//
//  Created by Johannes Schriewer on 2015-12-20.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "SwiftyRegex",
    targets: [
        Target(name:"SwiftyRegexTests", dependencies: [.Target(name: "SwiftyRegex")]),
        Target(name:"SwiftyRegex")
    ],
    dependencies: [
      .Package(url: "https://github.com/dunkelstern/pcre.git", majorVersion: 0)
    ]
)
