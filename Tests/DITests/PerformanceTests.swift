import DI
import XCTest

@inline(never)
func blackhole(_: some Any) {}

private let loop = 2000

final class PerformanceTests: XCTestCase {
    func testAA() {
        let root = RootComponent()
        print(#function, root.parentAComponent.childAComponent.take())
        measure {
            DispatchQueue.concurrentPerform(iterations: loop) { _ in
                let component = root.parentAComponent.childAComponent
                blackhole(component.take())
            }
        }
    }

    func testAB() {
        let root = RootComponent()
        print(#function, root.parentAComponent.childBComponent.take())
        measure {
            DispatchQueue.concurrentPerform(iterations: loop) { _ in
                let component = root.parentAComponent.childBComponent
                blackhole(component.take())
            }
        }
    }

    func testBA() {
        let root = RootComponent()
        print(#function, root.parentBComponent.childAComponent.take())
        measure {
            DispatchQueue.concurrentPerform(iterations: loop) { _ in
                let component = root.parentBComponent.childAComponent
                blackhole(component.take())
            }
        }
    }

    func testBB() {
        let root = RootComponent()
        print(#function, root.parentBComponent.childBComponent.take())
        measure {
            DispatchQueue.concurrentPerform(iterations: loop) { _ in
                let component = root.parentBComponent.childBComponent
                blackhole(component.take())
            }
        }
    }

    func testMixed() {
        let root = RootComponent()
        measure {
            DispatchQueue.concurrentPerform(iterations: loop) { i in
                let v = switch i % 4 {
                case 0:
                    root.parentAComponent.childAComponent.take()
                case 1:
                    root.parentAComponent.childBComponent.take()
                case 2:
                    root.parentBComponent.childAComponent.take()
                default:
                    root.parentBComponent.childBComponent.take()
                }
                blackhole(v)
            }
        }
    }
}

extension AnyKey {
    fileprivate static let dependency0 = Key<String>()
    fileprivate static let dependency1 = Key<String>()
    fileprivate static let dependency2 = Key<String>()
    fileprivate static let dependency3 = Key<String>()
    fileprivate static let dependency4 = Key<String>()
    fileprivate static let dependency5 = Key<String>()
    fileprivate static let dependency6 = Key<String>()
    fileprivate static let dependency7 = Key<String>()
    fileprivate static let dependency8 = Key<String>()
    fileprivate static let dependency9 = Key<String>()
    fileprivate static let dependency10 = Key<String>()
    fileprivate static let dependency11 = Key<String>()
    fileprivate static let dependency12 = Key<String>()
    fileprivate static let dependency13 = Key<String>()
    fileprivate static let dependency14 = Key<String>()
    fileprivate static let dependency15 = Key<String>()
    fileprivate static let dependency16 = Key<String>()
    fileprivate static let dependency17 = Key<String>()
    fileprivate static let dependency18 = Key<String>()
    fileprivate static let dependency19 = Key<String>()
    fileprivate static let dependency20 = Key<String>()
    fileprivate static let dependency21 = Key<String>()
    fileprivate static let dependency22 = Key<String>()
    fileprivate static let dependency23 = Key<String>()
    fileprivate static let dependency24 = Key<String>()
    fileprivate static let dependency25 = Key<String>()
    fileprivate static let dependency26 = Key<String>()
    fileprivate static let dependency27 = Key<String>()
    fileprivate static let dependency28 = Key<String>()
    fileprivate static let dependency29 = Key<String>()
    fileprivate static let dependency30 = Key<String>()
    fileprivate static let dependency31 = Key<String>()
    fileprivate static let dependency32 = Key<String>()
    fileprivate static let dependency33 = Key<String>()
    fileprivate static let dependency34 = Key<String>()
    fileprivate static let dependency35 = Key<String>()
    fileprivate static let dependency36 = Key<String>()
    fileprivate static let dependency37 = Key<String>()
    fileprivate static let dependency38 = Key<String>()
    fileprivate static let dependency39 = Key<String>()
    fileprivate static let dependency40 = Key<String>()
    fileprivate static let dependency41 = Key<String>()
    fileprivate static let dependency42 = Key<String>()
    fileprivate static let dependency43 = Key<String>()
    fileprivate static let dependency44 = Key<String>()
    fileprivate static let dependency45 = Key<String>()
    fileprivate static let dependency46 = Key<String>()
    fileprivate static let dependency47 = Key<String>()
    fileprivate static let dependency48 = Key<String>()
    fileprivate static let dependency49 = Key<String>()
}

@Component(root: true)
fileprivate struct RootComponent: Sendable {
    @Provides(.dependency0)
    var dependency0: String {
        return get(.dependency25) + "Root0"
    }
    @Provides(.dependency1)
    var dependency1: String {
        return get(.dependency26) + "Root1"
    }
    @Provides(.dependency2)
    var dependency2: String {
        return get(.dependency27) + "Root2"
    }
    @Provides(.dependency3)
    var dependency3: String {
        return get(.dependency28) + "Root3"
    }
    @Provides(.dependency4)
    var dependency4: String {
        return get(.dependency29) + "Root4"
    }
    @Provides(.dependency5)
    var dependency5: String {
        return get(.dependency30) + "Root5"
    }
    @Provides(.dependency6)
    var dependency6: String {
        return get(.dependency31) + "Root6"
    }
    @Provides(.dependency7)
    var dependency7: String {
        return get(.dependency32) + "Root7"
    }
    @Provides(.dependency8)
    var dependency8: String {
        return get(.dependency33) + "Root8"
    }
    @Provides(.dependency9)
    var dependency9: String {
        return get(.dependency34) + "Root9"
    }
    @Provides(.dependency10)
    var dependency10: String {
        return get(.dependency35) + "Root10"
    }
    @Provides(.dependency11)
    var dependency11: String {
        return get(.dependency36) + "Root11"
    }
    @Provides(.dependency12)
    var dependency12: String {
        return get(.dependency37) + "Root12"
    }
    @Provides(.dependency13)
    var dependency13: String {
        return get(.dependency38) + "Root13"
    }
    @Provides(.dependency14)
    var dependency14: String {
        return get(.dependency39) + "Root14"
    }
    @Provides(.dependency15)
    var dependency15: String {
        return get(.dependency40) + "Root15"
    }
    @Provides(.dependency16)
    var dependency16: String {
        return get(.dependency41) + "Root16"
    }
    @Provides(.dependency17)
    var dependency17: String {
        return get(.dependency42) + "Root17"
    }
    @Provides(.dependency18)
    var dependency18: String {
        return get(.dependency43) + "Root18"
    }
    @Provides(.dependency19)
    var dependency19: String {
        return get(.dependency44) + "Root19"
    }
    @Provides(.dependency20)
    var dependency20: String {
        return get(.dependency45) + "Root20"
    }
    @Provides(.dependency21)
    var dependency21: String {
        return get(.dependency46) + "Root21"
    }
    @Provides(.dependency22)
    var dependency22: String {
        return get(.dependency47) + "Root22"
    }
    @Provides(.dependency23)
    var dependency23: String {
        return get(.dependency48) + "Root23"
    }
    @Provides(.dependency24)
    var dependency24: String {
        return get(.dependency49) + "Root24"
    }
    @Provides(.dependency25)
    var dependency25: String {
        "Root25"
    }
    @Provides(.dependency26)
    var dependency26: String {
        "Root26"
    }
    @Provides(.dependency27)
    var dependency27: String {
        "Root27"
    }
    @Provides(.dependency28)
    var dependency28: String {
        "Root28"
    }
    @Provides(.dependency29)
    var dependency29: String {
        "Root29"
    }
    @Provides(.dependency30)
    var dependency30: String {
        "Root30"
    }
    @Provides(.dependency31)
    var dependency31: String {
        "Root31"
    }
    @Provides(.dependency32)
    var dependency32: String {
        "Root32"
    }
    @Provides(.dependency33)
    var dependency33: String {
        "Root33"
    }
    @Provides(.dependency34)
    var dependency34: String {
        "Root34"
    }
    @Provides(.dependency35)
    var dependency35: String {
        "Root35"
    }
    @Provides(.dependency36)
    var dependency36: String {
        "Root36"
    }
    @Provides(.dependency37)
    var dependency37: String {
        "Root37"
    }
    @Provides(.dependency38)
    var dependency38: String {
        "Root38"
    }
    @Provides(.dependency39)
    var dependency39: String {
        "Root39"
    }
    @Provides(.dependency40)
    var dependency40: String {
        "Root40"
    }
    @Provides(.dependency41)
    var dependency41: String {
        "Root41"
    }
    @Provides(.dependency42)
    var dependency42: String {
        "Root42"
    }
    @Provides(.dependency43)
    var dependency43: String {
        "Root43"
    }
    @Provides(.dependency44)
    var dependency44: String {
        "Root44"
    }
    @Provides(.dependency45)
    var dependency45: String {
        "Root45"
    }
    @Provides(.dependency46)
    var dependency46: String {
        "Root46"
    }
    @Provides(.dependency47)
    var dependency47: String {
        "Root47"
    }
    @Provides(.dependency48)
    var dependency48: String {
        "Root48"
    }
    @Provides(.dependency49)
    var dependency49: String {
        "Root49"
    }

    var parentAComponent: ParentAComponent {
        ParentAComponent(parent: self)
    }

    var parentBComponent: ParentBComponent {
        ParentBComponent(parent: self)
    }
}

@Component
fileprivate struct ParentAComponent: Sendable {
    @Provides(.dependency25)
    var dependency25: String {
        "ParentA25"
    }
    @Provides(.dependency26)
    var dependency26: String {
        "ParentA26"
    }
    @Provides(.dependency27)
    var dependency27: String {
        "ParentA27"
    }
    @Provides(.dependency28)
    var dependency28: String {
        "ParentA28"
    }
    @Provides(.dependency29)
    var dependency29: String {
        "ParentA29"
    }

    var childAComponent: ChildAComponent {
        ChildAComponent(parent: self)
    }

    var childBComponent: ChildBComponent {
        ChildBComponent(parent: self)
    }
}

@Component
fileprivate struct ParentBComponent: Sendable {
    @Provides(.dependency25)
    var dependency25: String {
        return get(.dependency15) + get(.dependency35) + "ParentB25"
    }
    @Provides(.dependency26)
    var dependency26: String {
        return get(.dependency16) + get(.dependency36) + "ParentB26"
    }
    @Provides(.dependency27)
    var dependency27: String {
        return get(.dependency17) + get(.dependency37) + "ParentB27"
    }
    @Provides(.dependency28)
    var dependency28: String {
        return get(.dependency18) + get(.dependency38) + "ParentB28"
    }
    @Provides(.dependency29)
    var dependency29: String {
        return get(.dependency19) + get(.dependency39) + "ParentB29"
    }
    @Provides(.dependency30)
    var dependency30: String {
        return get(.dependency20) + get(.dependency40) + "ParentB30"
    }
    @Provides(.dependency31)
    var dependency31: String {
        return get(.dependency21) + get(.dependency41) + "ParentB31"
    }
    @Provides(.dependency32)
    var dependency32: String {
        return get(.dependency22) + get(.dependency42) + "ParentB32"
    }
    @Provides(.dependency33)
    var dependency33: String {
        return get(.dependency23) + get(.dependency43) + "ParentB33"
    }
    @Provides(.dependency34)
    var dependency34: String {
        return get(.dependency24) + get(.dependency44) + "ParentB34"
    }

    var childAComponent: ChildAComponent {
        ChildAComponent(parent: self)
    }

    var childBComponent: ChildBComponent {
        ChildBComponent(parent: self)
    }
}

@Component
fileprivate struct ChildAComponent: Sendable {
    @Provides(.dependency0)
    var dependency0: String {
        "ChildA0"
    }
    @Provides(.dependency1)
    var dependency1: String {
        "ChildA1"
    }
    @Provides(.dependency2)
    var dependency2: String {
        "ChildA2"
    }
    @Provides(.dependency3)
    var dependency3: String {
        "ChildA3"
    }
    @Provides(.dependency4)
    var dependency4: String {
        "ChildA4"
    }

    func take() -> String {
        return [get(.dependency0), get(.dependency1), get(.dependency2), get(.dependency3), get(.dependency4), get(.dependency5), get(.dependency6), get(.dependency7), get(.dependency8), get(.dependency9)].joined(separator: "-")
    }
}

@Component
fileprivate struct ChildBComponent: Sendable {
    @Provides(.dependency5)
    var dependency5: String {
        return get(.dependency15) + get(.dependency25) + "ChildB5"
    }
    @Provides(.dependency6)
    var dependency6: String {
        return get(.dependency16) + get(.dependency26) + "ChildB6"
    }
    @Provides(.dependency7)
    var dependency7: String {
        return get(.dependency17) + get(.dependency27) + "ChildB7"
    }
    @Provides(.dependency8)
    var dependency8: String {
        return get(.dependency18) + get(.dependency28) + "ChildB8"
    }
    @Provides(.dependency9)
    var dependency9: String {
        return get(.dependency19) + get(.dependency29) + "ChildB9"
    }

    func take() -> String {
        return [get(.dependency0), get(.dependency1), get(.dependency2), get(.dependency3), get(.dependency4), get(.dependency5), get(.dependency6), get(.dependency7), get(.dependency8), get(.dependency9)].joined(separator: "-")
    }
}
