//
//  main.swift
//  Launchpad Tools
//
//  Created by Will Tyler on 1/19/19.
//  Copyright © 2019 Will Tyler. All rights reserved.
//

import Foundation


let path = "/var/folders/s5/7swt2cts5xn7fldkx_jlp4jm0000gn/0/com.apple.dock.launchpad/db/db"
let db = try Connection(path)
let items = Table("items")
let apps = Table("apps")

let title = Expression<String>("title")
let parentID = Expression<Int64>("parent_id")

let userAppItems = items.select(rowid, parentID).filter(parentID == 137 || parentID == 138)
var rowIDs = [Int64]()

for item in try db.prepare(userAppItems) {
	rowIDs.append(item[rowid])
}

let query = apps.select(rowid, title).filter(rowIDs.contains(rowid)).order(title.asc)

for item in try db.prepare(query) {
	print(item[title])
}
