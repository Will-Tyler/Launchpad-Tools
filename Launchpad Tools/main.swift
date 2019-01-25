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

let itemsTable = Table("items")
let appsTable = Table("apps")
let groupsTable = Table("groups")
let dbInfoTable = Table("dbinfo")

func getItems() throws -> [Item] {
	let uuid = Expression<String>("uuid")
	let flags = Expression<Int64?>("flags")
	let type = Expression<Int64>("type")
	let parentID = Expression<Int64>("parent_id")
	let ordering = Expression<Int64>("ordering")
	let result = try db.prepare(itemsTable)

	return result.map({ Item(rowID: $0[rowid], uuid: $0[uuid], flags: $0[flags], type: $0[type], parentID: $0[parentID], ordering: $0[ordering]) })
}

func getApps() throws -> [App] {
	let itemID = Expression<Int64>("item_id")
	let title = Expression<String>("title")
	let bundleID = Expression<String>("bundleid")
	let storeID = Expression<String?>("storeid")
	let categoryID = Expression<Int64?>("category_id")
	let modDate = Expression<Double>("moddate")
	let bookmark = Expression<Data>("bookmark")
	let result = try db.prepare(appsTable)

	return result.map({ App(itemID: $0[itemID], title: $0[title], bundleID: $0[bundleID], storeID: $0[storeID], categoryID: $0[categoryID], modDate: $0[modDate], bookmark: $0[bookmark]) })
}

func getGroups() throws -> [Group] {
	let itemID = Expression<Int64>("item_id")
	let categoryID = Expression<Int64?>("category_id")
	let title = Expression<String?>("title")
	let result = try db.prepare(groupsTable)

	return result.map({ Group(itemID: $0[itemID], categoryID: $0[categoryID], title: $0[title]) })
}

fileprivate let title = Expression<String>("title")
fileprivate let parentID = Expression<Int64>("parent_id")
fileprivate let ordering = Expression<Int64>("ordering")

fileprivate func condense(parentIDs: Set<Int64>) throws {
	typealias Item = (rowid: Int64, parentID: Int64, ordering: Int64)

	let itemsQuery = itemsTable.order(parentID, ordering).filter(parentIDs.contains(parentID)).select(rowid, parentID, ordering)
	var items: [Item] = (try db.prepare(itemsQuery)).map({ (rowid: $0[rowid], parentID: $0[parentID], ordering: $0[ordering]) })

	let parentIDs = parentIDs.sorted(by: <)
	let firstParentIDs = parentIDs.dropLast()

	for (index, id) in firstParentIDs.enumerated() {
		while let last = items.last(where: { $0.parentID == id }), last.ordering < 34 {
			let nextParent = parentIDs[index + 1]

			if let firstIndex = items.firstIndex(where: { $0.parentID == nextParent}) {
				let first = items[firstIndex]
				let update = itemsTable.filter(rowid == first.rowid).update(parentID <- id)

				try db.run(update)
				items = (try db.prepare(itemsQuery)).map({ (rowid: $0[rowid], parentID: $0[parentID], ordering: $0[ordering]) })
			}
			else {
				break
			}
		}
	}
}

fileprivate func sort(parentIDs: Set<Int64>) throws {
	let userAppItems = itemsTable.order(parentID, ordering).filter(parentIDs.contains(parentID)).select(rowid)
	let rowIDs = (try db.prepare(userAppItems)).map({ $0[rowid] })
	let appTitlesTable = appsTable.select(rowid, title).filter(rowIDs.contains(rowid))

	typealias AppItem = (rowID: Int64, title: String)
	var appItems = (try db.prepare(appTitlesTable)).map({ AppItem(rowID: $0[rowid], title: $0[title]) })

	appItems.sort(by: { (left, right) in
		let leftIndex = rowIDs.firstIndex(of: left.rowID)!
		let rightIndex = rowIDs.firstIndex(of: right.rowID)!

		return leftIndex < rightIndex
	})

	LaunchpadDB.shouldIgnoreItemUpdates = true

	var index = 0
	let count = appItems.count

	while index < count-1 {
		let left = appItems[index]
		let right = appItems[index+1]
		let leftTitle = left.title.lowercased()
		let rightTitle = right.title.lowercased()

		if leftTitle > rightTitle { // should swap
			appItems[index] = right
			appItems[index+1] = left

			let leftTable = itemsTable.filter(rowid == left.rowID)
			let leftRow = (try db.prepare(leftTable)).map({ $0 }).first!
			let leftParent = leftRow[parentID]
			let leftOrdering = leftRow[ordering]

			let rightTable = itemsTable.filter(rowid == right.rowID)
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

	LaunchpadDB.shouldIgnoreItemUpdates = false
}

//try condense(parentIDs: [126, 132, 133])
try sort(parentIDs: [126, 132, 133])
