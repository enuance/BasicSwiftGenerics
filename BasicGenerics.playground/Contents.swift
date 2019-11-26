import Foundation
/*:
 # Swift Basic Generic Programming
 
 We're going to work through several examples to see what generic programming is all about.
 Some of the major topics I'd like to cover are:
 - Generics
 - PATs (*Protocols with Associated Types*)
 - Mirrors
 - KeyPaths
 ___
*/
/*:
 ## Generics
 
 Questions For the topic of Generics:
 - What are generic Type Parameters?
 - What is Type Reification?
 - What are generic constraints?
*/
/*:
 First we'll be working through Stacks to answer some of these questions
 A Stack is a container type that enforces a Last in / First Out (*LIFO*) order
 Some common methods that you'll find on the stack are:
 - `push` *Adds an element to the stack*
 - `pop` *removes the last element from the stack*
 */
//: 1. Make A Stack called `IntStack` that works with Integers

struct IntStack {
    
    private var container = [Int]()
    
    init(elements: Int...) {
        self.container = elements
    }
    
    mutating func push(element: Int) {
        container.append(element)
    }
    
    mutating func pop() -> Int? {
        container.popLast()
    }
    
}

var intStack = IntStack(elements: 1, 4, 68, 19)

print(intStack.pop() ?? 0)

intStack.push(element: 111)

print(intStack.pop() ?? 0)
intStack.pop()
intStack.pop()
intStack.pop()
intStack.pop()

//: 2. Make A generic stack called `Stack<T>`

struct Stack<Element: Describable>: ExpressibleByArrayLiteral {
    
    private var container: [Element]
    
    init(elements: Element...) {
        self.container = elements
    }
    
    init(arrayLiteral elements: Element...) {
        self.container = elements
    }
    
    mutating func push(_ element: Element) {
        container.append(element)
    }
    
    @discardableResult
    mutating func pop() -> Element? {
        container.popLast()
    }
    
    func readContents() {
        print("*** Contents of \(type(of: self)) ***")
        container
            .enumerated()
            .forEach { print($0, $1.displayDescription) }
    }
    
}


var stack: Stack = ["Hello", "There", "You"]

var anotherStack = Stack(elements: 1, 6, 7, 4)

stack.pop()

anotherStack.pop()

stack.readContents()

anotherStack.readContents()

//: ### Generic Type Constraints
//: 3. Make a protocol named `Describable` with a `String` property called `displayDescription`

protocol Describable {
    
    var displayDescription: String { get }
    
}

//: 4. Make a New String Interpolation rule called typePrefixed

extension String.StringInterpolation {
    
    mutating func appendInterpolation<T>(typePrefixed value: T) {
        appendLiteral("\(T.self) \(value)")
    }
    
}

//: 5. Constrain the Stack generic to Describable

extension Describable {
    
    var displayDescription: String { "\(typePrefixed: self)" }
    
}

extension String: Describable { }

extension Int: Describable { }

//: 6. Add Conditional Conformance for a `Sum` method using `Numeric` & `String`

extension Stack where Element: Numeric {
    
    func sum() -> Element {
        container.reduce(0) { $0 + $1 }
    }
    
}

extension Stack where Element == String {
    
    func sum() -> Element {
        container.joined(separator: " ")
    }
    
}

anotherStack.sum()

stack.sum()

//: ___
/*:
 ## PATs (*Protocols With Associated Types*)
 
 Questions For the topic of PATs:
 - What are Associated Types?
 - What are existentials?
 - What is type erasure?
 - What are opaque return types?
 */
/*:
 For the next example we'll be working through a Queue. A Queue is very similar
 to a Stack in that it is a container type that enforces a certain order for accessing
 its elements. The queue however uses the First in / First out (*FIFO*) order.
 Some common methods that you'll find on the queue are:
 - `enqueue` *Adds an element to the queue*
 - `dequeue` *removes the first element from the queue*
 */

//: *CHALLENGE: Make A Generic Queue `struct Queue<Element>: ExpressibleByArrayLiteral`*

struct Queue<Element>: ExpressibleByArrayLiteral {
    
    private var container: [Element]
    
    init(elements: Element...) {
        self.container = elements
    }
    
    init(arrayLiteral elements: Element...) {
        self.container = elements
    }
    
    mutating func enqueue(_ element: Element) {
        container.insert(element, at: 0)
    }
    
    mutating func dequeue() -> Element? {
        container.popLast()
    }
    
}

//: - `protocol Merchandise`

protocol Merchandise {
    
    var name: String { get }
    
    var price: Double { get }
    
}

//: - `struct Customer<T: Store>`

struct Customer<T: Store> {
    
    let name: String
    
    let order: T.MerchendiseType
    
}

//: - `protocol Store`

protocol Store {
    
    associatedtype MerchendiseType: Merchandise
    
    var customerLine: Queue<Customer<Self>> { get set }
    
    var revenue: Double { get set }
    
    mutating func add(_ customer: Customer<Self>)
    
    func greet(_ customer: Customer<Self>)
    
    func sayGoodbye(_ customer: Customer<Self>)
    
    mutating func fulfillOrder(for customer: Customer<Self>)
    
    mutating func processOrders() -> Double
    
}

//: - `extension Store`

extension Store {
    
    mutating func add(_ customer: Customer<Self>) {
        customerLine.enqueue(customer)
    }
    
    func greet(_ customer: Customer<Self>) {
        print("Hello \(customer.name)!")
    }
    
    func sayGoodbye(_ customer: Customer<Self>) {
        print("Thank You! Hope to see you again, \(customer.name)!")
    }
    
    mutating func fulfillOrder(for customer: Customer<Self>) {
        print("Your total will be $\(customer.order.price)")
        revenue += customer.order.price
        print("Here's your \(customer.order.name)")
    }
    
    mutating func processOrders() -> Double {
        var nextCustomer = customerLine.dequeue()
        
        while nextCustomer != nil {
            nextCustomer.map {
                greet($0)
                fulfillOrder(for: $0)
                sayGoodbye($0)
            }
            nextCustomer = customerLine.dequeue()
        }
        
        return revenue
    }
    
}

//: - `enum Drink: Merchandise`

enum Drink: Merchandise {
    case latte
    case americano
    case brewedCoffee
    
    var name: String {
        switch self {
        case .latte:
            return "Latte"
        case .americano:
            return "Americano"
        case .brewedCoffee:
            return "brewedCoffee"
        }
    }
    
    var price: Double {
        switch self {
        case .latte:
            return 6.84
        case .americano:
            return 4.65
        case .brewedCoffee:
            return 2.39
        }
    }
    
}

//: - `struct Starbucks: Store`

struct Starbucks: Store {
    
    typealias MerchendiseType = Drink
    
    var revenue: Double
    
    var customerLine: Queue<Customer<Starbucks>> = []
    
}

var sbux = Starbucks(revenue: 0.0)
var jessica = Customer<Starbucks>(name: "Jessica", order: .latte)
var peete = Customer<Starbucks>(name: "Peete", order: .brewedCoffee)
[jessica, peete].forEach { sbux.add($0) }

sbux.processOrders()


// Another example

enum Hardware: Merchandise {
    case wrench
    case hammer
    case shovel
    
    var name: String {
        switch self {
        case .wrench:
            return "Wrench"
        case .hammer:
            return "Hammer"
        case .shovel:
            return "Shovel"
        }
    }
    
    var price: Double {
        switch self {
        case .wrench:
            return 6.99
        case .hammer:
            return 12.99
        case .shovel:
            return 15.99
        }
    }
    
}

struct HardwareStore: Store {
    
    typealias MerchendiseType = Hardware
    
    var revenue: Double
    
    var customerLine: Queue<Customer<HardwareStore>> = []
}

var hardwareStore = HardwareStore(revenue: 0.0)
var jasmina = Customer<HardwareStore>(name: "jasmina", order: .shovel)
var andrew = Customer<HardwareStore>(name: "Andrew", order: .hammer)
[jasmina, andrew].forEach { hardwareStore.add($0) }

hardwareStore.processOrders()

//: ___
/*:
 ## Mirrors
 
 Questions For the topic of Mirrors:
 - What is Type introspection?
 - What contexts would you use this in?
 */

//: - `struct Rockstar` name & stagename

struct Rockstar {
    
    let name: String
    
    let stagename: String
    
}

//: - `struct Property<T>`

struct Property<T> {
    
    let name: String
    
    let value: T
    
}

//: - `struct AnyProperty`

struct AnyProperty {
    let name: String
    let value: Any
    
    init?(label: String?, value: Any) {
        guard let label = label else {
            return nil
        }
        self.name = label
        self.value = value
    }
    
    func typed<T>(as type: T.Type) -> Property<T>? {
        guard let typedValue = value as? T else {
            return nil
        }
        return Property(name: name, value: typedValue)
    }
    
}

//: - `extension Mirror.Children`

extension Mirror.Children {
    
    var properties: [AnyProperty] {
        self.compactMap { AnyProperty(label: $0.0, value: $0.1) }
    }
    
}

let rockstar = Rockstar(name: "Johnny", stagename: "String Shredder")

let mirror = Mirror(reflecting: rockstar)

let properties = mirror.children.properties

properties
    .compactMap { $0.typed(as: String.self) }
    .forEach { print($0) }

//: ___
/*:
 ## KeyPaths
 
 Questions For the topic of KeyPaths:
 - What are Keypaths?
 - What Keypath types are there?
 */

struct SomeThing {
    
    let name: String
    let preferredName: String
    
    let myName: KeyPath<Self, String> = \SomeThing.preferredName
    
}

let thisThing = SomeThing(
    name: "Something Type",
    preferredName: "The best type EVER!"
)

let myNamePath = thisThing.myName

let pathValue = thisThing[keyPath: myNamePath]
