#  Launchpad Tools

A set of tools to help mac users manage their launchpad. Launchpad is a convenient, iOS-style window which allows users to launch applications quickly. My goal with this project was to create a way to quickly modify the order in which the apps appear. I wanted be able to have all my Apple apps on the left-most window with all my personal apps sorted alphabetically in the following windows. Currently, this project is a really hacky Swift script, which will sort the first two pages of my personal apps (I only have two pages). Hopefully, this project can develop into more all-encompasing set of tools for Mac users.

## Launchpad Database

Launchpad has stored its information in various locations as an SQLite database over the past few operating systems. For me (I'm on Mojave), it was in `/var/folders/s5/7swt2cts5xn7fldkx_jlp4jm0000gn/0/com.apple.dock.launchpad/db`. Other possibilities include `/private/var/folders/s5/7swt2cts5xn7fldkx_jlp4jm0000gn/0/com.apple.dock.launchpad/db` (for High Sierra I believe), and somewhere in `~/Library/Application Support/Dock` for Yosemite. If you want to try messing around with Launchpad yourself, make sure you have found the correct database (so you don't waste time messing with the wrong one like me 🤗). I used Jetbrain's Datagrip tool to easily see the different tables.

Looking at the database tables does not immediately reveal how the order of the apps is stored. The way it works is that each app is designated by its `rowid` ( I think also labeled as `item_id` in the apps table). In the items table, each item has a `parent_id` and an `ordering`.  The parent id is essentially the page or group that the app belongs with. For me `137` was the second page, and `138` was the third page. Then the `ordering` is what position the item is in relative to the rest of the items that share the same `parent_id`.  That's the most important part. The other details can be pretty easily determined through observation and experimentation.

## main.swift

This is the Swift script I used due to the complicated relationships in the database tables. I used [SQLite.swift](https://github.com/stephencelis/SQLite.swift) to manage the Launchpad database.

My process was roughly:

 * Get the `rowIDs` for the apps in the order that they show up in Launchpad for the second and third pages (my personal apps). That is, sorted by `parentID`, then `ordering`.
 * Get the names of the apps from the `apps` table.
 * Sort the array of `appItems` in order to match that of `rowIDs`, which is the way they show up in Launchpad.
 * Create a variable to disable the database triggers. The database has what can be thought of as event listeners, which will automatically change some numbers. This is important to disable because when I am manually sorting the apps, all I need to do is switch the positions without affecting anything else.
 * I then go through all the `appItems` and manually swap their `parentIDs` and `ordering` where necessary.
 
 ## Remarks
 
 Hopefully, someone with more time than me can make a more all-encompasing set of Launchpad tools or a Launchpad API.
