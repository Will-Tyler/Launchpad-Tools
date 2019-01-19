//
//  main.swift
//  Launchpad Tools
//
//  Created by Will Tyler on 1/19/19.
//  Copyright © 2019 Will Tyler. All rights reserved.
//

import Foundation


_ = "SELECT rowid, title FROM apps WHERE rowid IN (SELECT rowid FROM items WHERE parent_id = 137 OR parent_id = 138) ORDER BY title ASC LIMIT 35;"

let path = "/var/folders/s5/7swt2cts5xn7fldkx_jlp4jm0000gn/0/com.apple.dock.launchpad/db/db"
let db = try Connection(path)
let items = Table("items")

for item in try db.prepare(items) {
	print(item)
}
