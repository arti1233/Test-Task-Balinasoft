import Foundation
import UIKit
import Alamofire

struct UrlConstants {
    static var photosUrl = "https://junior.balinasoft.com/api/v2/photo/type"
}

protocol AlamofireProtocol {
    func getPhotos(page: Int, completion: @escaping(Result<Photos, Error>) -> Void)
}


class AlamofireProvider: AlamofireProtocol {
    func getPhotos(page: Int, completion: @escaping (Result<Photos, Error>) -> Void) {
        AF.request(UrlConstants.photosUrl, method: .get, parameters: ["page": page]).responseDecodable(of: Photos.self) { response in
            switch response.result {
            case .success(let result):
                return completion(.success(result))
            case .failure(let error):
                return completion(.failure(error))
            }
        }
    }
}
