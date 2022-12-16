# XQWCDB

对WCDB的简单封装


# 导入

```
pod 'XQWCDB', :git => 'https://github.com/SyKingW/XQWCDB.git'
```

# 使用

初始化数据库

```swift
XQWCDB.shared.initDB()
```

示例 Person 类

```swift
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
```

创建 person 表

```swift
Person.xq_createTable()
```

插入数据

```swift
let p = Person()
p.friends = [Person()]
p.gender = .man
p.name = "男"
Person.xq_insert(with: [p])
```

获取数据

```swift
let pList = Person.xq_getObjects()
```

更新数据

```swift
var p = Person()
p.age = 20
Person.xq_update(with: p, propertyConvertibleList: [Person.CodingKeys.age], where: Person.CodingKeys.name == "男")
```

删除数据

```swift
Person.xq_delete(with: Person.CodingKeys.name == "男")
```







