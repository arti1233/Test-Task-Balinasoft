import Foundation

struct Photos: Codable {
    var page, pageSize, totalPages, totalElements: Int
    var content: [Content]
}

struct Content: Codable {
    var id: Int
    var name: String
    var image: String?
}
