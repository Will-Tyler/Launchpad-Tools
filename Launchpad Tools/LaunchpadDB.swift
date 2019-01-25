//
//  LaunchpadDB.swift
//  Launchpad Tools
//
//  Created by Will Tyler on 1/25/19.
//  Copyright © 2019 Will Tyler. All rights reserved.
//

import Foundation


class LaunchpadDB {

	private static let key = Expression<String>("key")
	private static let value = Expression<String>("value")

	static var shouldIgnoreItemUpdates: Bool {
		get {
			let query = dbInfoTable.filter(key == "ignore_items_update_triggers")
			let rows = (try! db.prepare(query)).map({ $0 })
			let first = rows.first!

			return first[value] == "1"
		}
		set {
			let ignores = dbInfoTable.filter(key == "ignore_items_update_triggers")
			let update = ignores.update(value <- newValue ? "1" : "0")

			try! db.run(update)
		}
	}

}
