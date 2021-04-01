//
//  XQWCDB.swift
//  XQDBDemo
//
//  Created by WXQ on 2021/3/10.
//

import Foundation
import WCDBSwift

public class XQWCDB: NSObject {
    
    public static let shared = XQWCDB()
    
    public var database: Database?
    
    
    /// 初始化数据库
    /// - Parameter dbPath: 数据库路径  xxx.db，如为空则使用默认路径
    public func initDB(_ dbPath: String = "") {
        if let _ = self.database {
            return
        }
        
        var path = ""
        if dbPath.count == 0 {
            path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "") + "/xqwcdb/xqwcdb.db"
        }
        
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
}

/// 直接让 model 类遵守该协议，就能实现简单的增删改查
public protocol XQWCDBModelConvenientProtocol: WCDBSwift.TableCodable {
    
    /// 表名
    static var xq_table: String {get}
    
    /// 创建表
    static func xq_createTable()
    
    /// 插入数据
    /// @note 类型写 Self.CodingKeys.Root 是因为如果写 Self，编译时，系统会报错
    static func xq_insert(with objects: [Self.CodingKeys.Root])
    
    /// 获取数据
    /// - Parameter condition: 如不传, 则获取所有数据
    static func xq_getObjects(with condition: WCDBSwift.Condition?) -> [Self.CodingKeys.Root]
    
    /// 获取数据
    static func xq_getObject(with condition: WCDBSwift.Condition?) -> Self?
    
    /// 获取表数据的数量
    static func xq_getCount() -> Int
    
    /// 更新数据
    /// - Parameters:
    ///   - propertyConvertibleList: 更新字段，不传则更新所有字段
    ///   - condition: 更新条件, 不传则更新整个表
    static func xq_update(with object: Self, propertyConvertibleList: [WCDBSwift.PropertyConvertible], where condition: WCDBSwift.Condition?)
    
    /// 删除数据
    /// - Parameter condition: 如不传, 则是清空表的所有数据
    static func xq_delete(with condition: WCDBSwift.Condition?)
    
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
    
    static func xq_getObjects(with condition: WCDBSwift.Condition? = nil) -> [Self] {
        // 100万条，15 秒左右
        if let modelArr: [Self] = try? XQWCDB.shared.database?.getObjects(fromTable: self.xq_table, where: condition) {
            return modelArr
        }
        return [Self]()
    }
    
    static func xq_getObject(with condition: WCDBSwift.Condition? = nil) -> Self? {
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
    
    static func xq_update(with object: Self, propertyConvertibleList: [WCDBSwift.PropertyConvertible] = Self.CodingKeys.all, where condition: WCDBSwift.Condition? = nil) {
        try? XQWCDB.shared.database?.update(table: self.xq_table, on: propertyConvertibleList, with: object, where: condition)
    }
    
    static func xq_delete(with condition: WCDBSwift.Condition? = nil) {
        // 循环删除, 1万条, 需要 14 秒
        // 不能像 sql 那样，直接提交所有语句上去吗？感觉那样会快很多
        // 以后再研究一下，这样是有问题的
        try? XQWCDB.shared.database?.delete(fromTable: self.xq_table, where: condition)
        
    }
    
    static func xq_drop() {
        try? XQWCDB.shared.database?.drop(table: self.xq_table)
    }
    
    
    
}









