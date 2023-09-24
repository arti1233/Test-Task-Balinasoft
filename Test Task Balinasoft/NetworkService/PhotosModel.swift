import Foundation

struct Photos: Decodable {
    let page, pageSize, totalPages, totalElements: Int
    let content: [Content]
}

struct Content: Decodable {
    let id: Int
    let name: String
    let image: String?
}
