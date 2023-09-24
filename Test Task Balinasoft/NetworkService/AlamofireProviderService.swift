import Foundation
import UIKit
import Alamofire

struct UrlConstants {
    static var photosUrl = "https://junior.balinasoft.com/api/v2/photo/type"
    static var uploadPhotoUrl = "https://junior.balinasoft.com/api/v2/photo"
}

protocol AlamofireProtocol {
    func getPhotos(page: Int, completion: @escaping(Result<Photos, Error>) -> Void)
    func sendPhotoToServer(photo: UIImage, id: Int, userName: String, completion: @escaping(Result<Data, Error>) -> Void)
}


final class AlamofireProvider: AlamofireProtocol {

    func sendPhotoToServer(photo: UIImage, id: Int, userName: String, completion: @escaping (Result<Data, Error>) -> Void) {
        if let imageData = photo.jpegData(compressionQuality: 1) {
            AF.upload(
                multipartFormData: { multipartFormData in
                    multipartFormData.append(imageData, withName: "photo", fileName: photo.description, mimeType: "image/jpeg")
                    multipartFormData.append(id.description.data(using: .utf8)!, withName: "typeId")
                    multipartFormData.append(userName.data(using: .utf8)!, withName: "name")
                },
                to: UrlConstants.uploadPhotoUrl,
                method: .post,
                headers: nil
            ).response { response in
                switch response.result {
                case .success(let data):
                    guard let data = data else { return }
                    return completion(.success(data))
                case .failure(let error):
                   return completion(.failure(error))
                }
            }
        }
    }

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
