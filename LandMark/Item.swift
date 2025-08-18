import Foundation
import SwiftData

@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var title: String
    var content: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        title: String = "New Item",
        content: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.title = title
        self.content = content
    }
}

extension Item {
    var displayTitle: String {
        title.isEmpty ? "Untitled" : title
    }

    var formattedDate: String {
        timestamp.formatted(date: .abbreviated, time: .shortened)
    }
}
