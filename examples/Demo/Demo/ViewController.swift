//
//  ViewController.swift
//  Demo
//
//  Created by xq on 2022/12/15.
//

import UIKit
import XQWCDB
import WCDBSwift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化数据库
        XQWCDB.shared.initDB()
        // 创建 person 表
        Person.xq_createTable()
        
        // 插入数据
        let p = Person()
        p.friends = [Person()]
        p.gender = .man
        p.name = "男"
        Person.xq_insert(with: [p])
        
        // 更新数据
        p.age = 20
//        Person.xq_insert(with: [p])
        Person.xq_update(with: p, propertyConvertibleList: [Person.CodingKeys.age], where: Person.CodingKeys.name == "男")
        
        // 获取数据
        let ps = Person.xq_getObjects()
        for item in ps {
            print("\(item.name) \(item.gender) \(item.age) \(item.lastInsertedRowID)")
        }
        
        // 删除数据
//        Person.xq_delete(with: Person.CodingKeys.name == "男")
        
        print(XQWCDB.shared.dbPath)
        
        // 删除数据库
        XQWCDB.shared.removeDB()
        
        // 重新再次初始化数据看
        XQWCDB.shared.initDB()
        // 创建表
        Person.xq_createTable()
        // 插入数据
        let p1 = Person()
        p1.gender = .woman
        p1.name = "女"
        Person.xq_insert(with: [p1])
        
        // 获取数据
        let ps1 = Person.xq_getObjects()
        for item in ps1 {
            print("\(item.name) \(item.gender) \(item.age) \(item.lastInsertedRowID)")
        }
    }


}

class Person: NSObject, XQWCDBModelConvenientProtocol {
    static var xq_table: String = "person"

    enum CodingKeys: String, CodingTableKey {
        typealias Root = Person
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        case name
        case age
        case gender
        case lastInsertedRowID
        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                lastInsertedRowID: ColumnConstraintBinding(isPrimary: true),
            ]
        }
    }
    
    var isAutoIncrement: Bool { return true }
    var lastInsertedRowID: Int64 = 0
    
    override init() {
        super.init()
    }
    
    var name: String = ""
    var age: Int = 0
    var gender: Gender = Gender.other

    var friends: [Person] = []
}



enum Gender: Int, ColumnCodable {
    init?(with value: WCDBSwift.FundamentalValue) {
        self.init(rawValue: Int(value.int32Value))
    }

    func archivedValue() -> WCDBSwift.FundamentalValue {
        FundamentalValue(self.rawValue)
    }
    
    static var columnType: WCDBSwift.ColumnType = .integer32
    
    case man = 0
    case woman = 1
    case other = 2
}
