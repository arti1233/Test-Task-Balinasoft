import Foundation
import UIKit

private enum Constants {
    static let devName = Bundle.main.object(forInfoDictionaryKey: "DeveloperName") as? String
}

protocol MainViewModelProtocol {
    func sendPhotoToServer(photo: UIImage)
    func getPhotos()
    func changeSentPhotoIndexPath(indexPath: IndexPath?)
    func getNumberOfCells() -> Int
    func showLoader() -> Int
    func configurePhotoCell(indexPath: IndexPath, cell: PhotoCell) -> UITableViewCell
    
    var onUpdateTableView: (() -> Void)? { get set }
    var onPresentAlert: ((_ text: String, _ title: String) -> Void)? { get set }
}

final class MainViewModel: MainViewModelProtocol {
    
    var onPresentAlert: ((String, String) -> Void)?
    var onUpdateTableView: (() -> Void)?
   
    //MARK: - Properties
    
    private var imageCache = NSCache<NSString, UIImage>()
    private var alamofireProvider: AlamofireProtocol = AlamofireProvider()
    private var arrayPhotos: [Content] = []
    private var page = 0
    private var maxPage = 0
    private var isDownloadInProgress = true
    private var photoIndexPath: IndexPath!
    
    
    //MARK: - Business Logic
    
    func showLoader() -> Int {
        page <= maxPage ? 1 : 0
    }
    
    func getNumberOfCells() -> Int {
        arrayPhotos.count
    }
    
    func configurePhotoCell(indexPath: IndexPath, cell: PhotoCell) -> UITableViewCell {
        cell.prepareForReuse()
        guard var image = UIImage(systemName: "exclamationmark.icloud.fill") else { return UITableViewCell() }
        if let key = arrayPhotos[indexPath.row].image, let cashedImage = imageCache.object(forKey: key as NSString) {
            image = cashedImage
        }
        cell.configureUI(photo: image, text: arrayPhotos[indexPath.row].name)
        cell.updateConstraints()
        return cell
    }
    
    func changeSentPhotoIndexPath(indexPath: IndexPath?) {
        photoIndexPath = indexPath
    }
    
    func sendPhotoToServer(photo: UIImage) {
        alamofireProvider.sendPhotoToServer(photo: photo, id: arrayPhotos[photoIndexPath.row].id, userName: Constants.devName ?? "") { [weak self] result in
            guard let self, let onPresentAlert else { return }
            switch result {
            case .success(let data):
                guard let responseString = String(data: data, encoding: .utf8) else { return }
                onPresentAlert(responseString, "Data")
            case .failure(let error):
                onPresentAlert(error.localizedDescription, "Error")
                print("")
            }
        }
    }
    
    func getPhotos() {
        guard isDownloadInProgress == true else { return }
        isDownloadInProgress = false
        alamofireProvider.getPhotos(page: page, completion: { [weak self] result in
            guard let self, let onPresentAlert else { return }
            switch result {
            case .success(let photos):
                photos.content.forEach({self.arrayPhotos.append($0)})
                self.maxPage = photos.totalPages
                self.page += 1
                self.loadImageToCache()
            case .failure(let error):
                onPresentAlert(error.localizedDescription,"Error")
                print("")
            }
        })
    }
    
    private func loadImageToCache() {
        let group = DispatchGroup()
        for info in arrayPhotos {
            group.enter()
            if let image = info.image, imageCache.object(forKey: image as NSString) == nil {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self, let loadImage = info.image?.image else { return }
                    self.imageCache.setObject(loadImage, forKey: image as NSString)
                    group.leave()
                }
            } else {
                group.leave()
            }
        }
        
        group.wait()
        
        group.notify(queue: .main) { [weak self] in
            guard let self, let onUpdateTableView else { return }
            self.isDownloadInProgress = true
            onUpdateTableView()
        }
    }
}
