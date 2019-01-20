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
let dbInfo = Table("dbinfo")

let title = Expression<String>("title")
let parentID = Expression<Int64>("parent_id")
let ordering = Expression<Int64>("ordering")
let key = Expression<String>("key")
let value = Expression<String>("value")

let userAppItems = items.order(parentID, ordering).select(rowid, parentID).filter(parentID == 137 || parentID == 138)
let rowIDs = (try db.prepare(userAppItems)).map({ $0[rowid] })

let query = apps.select(rowid, title).filter(rowIDs.contains(rowid))

typealias AppItem = (rowID: Int64, title: String)
var appItems = (try db.prepare(query)).map({ (rowID: $0[rowid], title: $0[title]) })

appItems.sort(by: { (left, right) in
	let leftIndex = rowIDs.firstIndex(of: left.rowID)!
	let rightIndex = rowIDs.firstIndex(of: right.rowID)!

	return leftIndex < rightIndex
})

var shouldIgnoreItemUpdates: Bool {
	get {
		let query = dbInfo.filter(key == "ignore_items_update_triggers")
		let rows = (try! db.prepare(query)).map({ $0 })
		let first = rows.first!

		return first[value] == "1"
	}
	set {
		let ignores = dbInfo.filter(key == "ignore_items_update_triggers")
		let update = ignores.update(value <- newValue ? "1" : "0")

		try! db.run(update)
	}
}

shouldIgnoreItemUpdates = true

var index = 0
let count = appItems.count

while index < count-1 {
	let left = appItems[index]
	let right = appItems[index+1]
	let leftTitle = appItems[index].title
	let rightTitle = appItems[index+1].title

	if leftTitle > rightTitle { // should swap
		appItems[index] = right
		appItems[index+1] = left

		let leftTable = items.filter(rowid == left.rowID)
		let leftRow = (try db.prepare(leftTable)).map({ $0 }).first!
		let leftParent = leftRow[parentID]
		let leftOrdering = leftRow[ordering]

		let rightTable = items.filter(rowid == right.rowID)
		let rightRow = (try db.prepare(rightTable)).map({ $0 }).first!
		let rightParent = rightRow[parentID]
		let rightOrdering = rightRow[ordering]

		let leftParentUpdate = leftTable.update(parentID <- rightParent)
		let leftOrderingUpdate = leftTable.update(ordering <- rightOrdering)

		let rightParentUpdate = rightTable.update(parentID <- leftParent)
		let rightOrderingUpdate = rightTable.update(ordering <- leftOrdering)

		try db.run(leftParentUpdate)
		try db.run(leftOrderingUpdate)

		try db.run(rightParentUpdate)
		try db.run(rightOrderingUpdate)

		if index > 0 {
			index -= 1
		}
	}
	else {
		index += 1
	}
}

shouldIgnoreItemUpdates = false

for appItem in appItems {
	print(appItem.title)
}
