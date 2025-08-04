
import Foundation

public protocol AppOfferingIdentifier: CaseIterable {
    var id: String { get }
    var offeringGroup: any AppOfferingGroup { get }
}
