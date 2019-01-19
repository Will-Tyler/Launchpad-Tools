//
//  main.swift
//  Launchpad Tools
//
//  Created by Will Tyler on 1/19/19.
//  Copyright © 2019 Will Tyler. All rights reserved.
//

import Foundation
import SQLite


print("Hello, World!")
let database = try Connection("/var/folders/s5/7swt2cts5xn7fldkx_jlp4jm0000gn/0/com.apple.dock.launchpad/db/db")
let items = Table("items")

for item in try database.prepare(items) {
	print(item)
}
