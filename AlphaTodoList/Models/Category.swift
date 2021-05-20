//
//  Category.swift
//  AlphaTodoList
//
//  Created by developer on 20.05.21.
//

import Foundation
import RealmSwift

class Category: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var color: String = ""
    let items = List<Item>()
}
