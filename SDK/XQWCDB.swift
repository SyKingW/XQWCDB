//
//  XQWCDB.swift
//  XQDBDemo
//
//  Created by WXQ on 2021/3/10.
//

import Foundation
import WCDBSwift


/**
 
 - note: 使用示例
 
 ```swift
 function main() {
     // 初始化
     XQWCDB.shared.initDB()
     // 创建表
     Person.xq_createTable()
     // 插入数据
     Person.xq_insert(with: [Person()])
     // 查询数据
     let models = Person.xq_getObjects()
 }
 
 class Person: NSObject, XQWCDBModelConvenientProtocol {
     // 表名
     static var xq_table: String = "person"
     // 实现协议
     enum CodingKeys: String, CodingTableKey {
         // 类名
         typealias Root = Person
         static let objectRelationalMapping = TableBinding(CodingKeys.self)
         // case 是对应 model 的字段
         case name
         case age
         case gender
         case lastInsertedRowID
         // 一些字段的规则，主key，不能为空等等规则
         static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
             return [
                 // 主 key
                 lastInsertedRowID: ColumnConstraintBinding(isPrimary: true),
             ]
         }
     }
     
     // 主key自增
     var isAutoIncrement: Bool { return true }
     // 主key
     var lastInsertedRowID: Int64 = 0
     
     override init() {
         super.init()
     }
     
     // 你 model 要写的数据，字段
     var name: String = ""
     var age: Int = 0
     var gender: Gender = Gender.other

     var friends: [Person] = []
 }

 // 枚举示例，遵守 ColumnCodable 协议
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
 ```
 */
public class XQWCDB: NSObject {
    
    public static let shared = XQWCDB()
    
    /// wcdb 库对象
    public var database: Database?
    
    /// 数据库 path
    public var dbPath: String = ""
    
    
    /// 初始化数据库
    /// - Parameter dbPath: 数据库路径  xxx.db，如为空则使用默认路径
    public func initDB(_ dbPath: String? = nil) {
        if let _ = self.database {
            return
        }
        
        var path = ""
        if let dbPath = dbPath {
            path = dbPath
        } else {
            path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "") + "/xqwcdb/xqwcdb.db"
        }
        
        self.dbPath = path
        self.database = Database.init(withPath: path)
        
        // 加密
//        self.database?.setCipher(key: <#T##Data?#>)
        
        if self.database?.canOpen == false {
            print("wcdb 不能打开")
            return
        }
        
//        HomeModel.xq_createTable()
//        PeopleModel.xq_createTable()
    }
    
    /// 删除 db 库
    public func removeDB() {
        if self.database == nil {
            return
        }
        
        self.database?.close()
        try? self.database?.removeFiles()
        self.database = nil
        self.dbPath = ""
    }
}

/// 直接让 model 类遵守该协议，就能实现简单的增删改查
public protocol XQWCDBModelConvenientProtocol: TableCodable {
    
    /// 表名
    static var xq_table: String {get}
    
    /// 创建表
    /// 一般初始化应用的时候调一次就行了
    static func xq_createTable()
    
    /// 插入数据
    static func xq_insert(with objects: [Self.CodingKeys.Root])
    
    /// 获取数据
    /// - Parameter condition: 如不传, 则获取所有数据
    /// condition 用法：Person.CodingKeys.name == "123"，这样就表达获取 Person 类 name 字段等于 "123" 的所有 model
    static func xq_getObjects(with condition: Condition?) -> [Self.CodingKeys.Root]
    
    /// 获取数据
    static func xq_getObject(with condition: Condition?) -> Self?
    
    /// 获取表数据的数量
    static func xq_getCount() -> Int
    
    /// 更新数据
    /// - Parameters:
    ///   - propertyConvertibleList: 更新字段，不传则更新所有字段
    ///   propertyConvertibleList 用法： [Person.CodingKeys.name]，这样表示更新 Person 类的 name 字段
    ///   - condition: 更新条件, 不传则更新整个表
    ///   condition 用法：Person.CodingKeys.name == "123"，这样就是 Person 类的 name 字段等于 "123" 时，才更新
    static func xq_update(with object: Self, propertyConvertibleList: [PropertyConvertible], where condition: Condition?)
    
    /// 删除数据
    /// - Parameter condition: 如不传, 则是清空表的所有数据
    /// condition 用法：Person.CodingKeys.name == "123"，这样就是删除 Person 类的 name 字段等于 "123" 的
    static func xq_delete(with condition: Condition?)
    
    /// 删除表
    static func xq_drop()
    
}

public extension XQWCDBModelConvenientProtocol {
    
    // 以下说的秒数，是用 iPhone 7 测的
    
    static func xq_createTable() {
        try? XQWCDB.shared.database?.create(table: self.xq_table, of: self)
    }
    
    static func xq_insert(with objects: [Self]) {
        // 100万条，14 秒左右
        try? XQWCDB.shared.database?.insert(objects: objects, intoTable: self.xq_table)
    }
    
    static func xq_getObjects(with condition: Condition? = nil) -> [Self] {
        // 100万条，15 秒左右
        if let modelArr: [Self] = try? XQWCDB.shared.database?.getObjects(fromTable: self.xq_table, where: condition) {
            return modelArr
        }
        return [Self]()
    }
    
    static func xq_getObject(with condition: Condition? = nil) -> Self? {
        if let model: Self = try? XQWCDB.shared.database?.getObject(fromTable: self.xq_table, where: condition) {
            return model
        }
        return nil
    }
    
    static func xq_getCount() -> Int {
        // 1百万条数据，1.5 秒左右
        let columns = try? XQWCDB.shared.database?.getColumn(on: self.CodingKeys.any, fromTable: self.xq_table)
        return columns?.count ?? 0
    }
    
    static func xq_update(with object: Self, propertyConvertibleList: [PropertyConvertible] = Self.CodingKeys.all, where condition: Condition? = nil) {
        try? XQWCDB.shared.database?.update(table: self.xq_table, on: propertyConvertibleList, with: object, where: condition)
    }
    
    static func xq_delete(with condition: Condition? = nil) {
        // 循环删除, 1万条, 需要 14 秒
        // 不能像 sql 那样，直接提交所有语句上去吗？感觉那样会快很多
        // 以后再研究一下，这样是有问题的
        try? XQWCDB.shared.database?.delete(fromTable: self.xq_table, where: condition)
        
    }
    
    static func xq_drop() {
        try? XQWCDB.shared.database?.drop(table: self.xq_table)
    }
    
    
    
}









