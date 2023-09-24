import UIKit
import SnapKit

private enum Constants {
    static let devName = Bundle.main.object(forInfoDictionaryKey: "DeveloperName") as? String
}

private enum TableSection: Int, CaseIterable {
    case photos = 0
    case loader
}

final class MainViewController: UIViewController {
  
//MARK: Properties
    
    private lazy var mainTableView: UITableView = {
        var tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .white
        tableView.register(PhotoCell.self, forCellReuseIdentifier: PhotoCell.key)
        tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.key)
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private lazy var imagePicker: UIImagePickerController = {
        var picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        return picker
    }()
    
    private var imageCache = NSCache<NSString, UIImage>()
    private var alamofireProvider: AlamofireProtocol?
    private var arrayPhotos: [Content] = []
    private var page = 0
    private var maxPage = 0
    private var isDownloadInProgress = true
    private var photoIndexPath: IndexPath!
    
    
//MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alamofireProvider = AlamofireProvider()
        getPhotos(page: page)
        configureUI()
        
        print(Constants.devName!)
    }
 
//MARK: UI
    
    private func configureUI() {
        view.addSubview(mainTableView)
        
        mainTableView.snp.makeConstraints {
            $0.trailing.leading.bottom.top.equalToSuperview()
        }
    }
        
//MARK: - Business Logic
    
    private func sendPhotoToServer(photo: UIImage, id: Int, userName: String) {
        guard let alamofireProvider = alamofireProvider else { return }
        alamofireProvider.sendPhotoToServer(photo: photo, id: id, userName: userName) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let data):
                guard let responseString = String(data: data, encoding: .utf8) else { return }
                showAllert(text: responseString, title: "Data")
            case .failure(let error):
                showAllert(text: error.localizedDescription, title: "Error")
            }
        }
    }
    
    private func getPhotos(page: Int) {
        guard let alamofireProvider = alamofireProvider, isDownloadInProgress == true else { return }
        isDownloadInProgress = false
        alamofireProvider.getPhotos(page: page, completion: { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let photos):
                photos.content.forEach({self.arrayPhotos.append($0)})
                self.maxPage = photos.totalPages
                self.page += 1
                self.loadImageToCache()
            case .failure(let error):
                showAllert(text: error.localizedDescription, title: "Error")
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
            guard let self else { return }
            self.isDownloadInProgress = true
            self.mainTableView.reloadData()
        }
    }
    
    private func showAllert(text: String, title: String) {
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}

//MARK: - MainViewController extension


//MARK: UITableViewDelegate
extension MainViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch TableSection.allCases[indexPath.section] {
        case .loader:
            getPhotos(page: page)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        photoIndexPath = indexPath
        present(imagePicker, animated: true)
    }
}


//MARK: UITableViewDataSource
extension MainViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        TableSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSection.allCases[section] {
        case .photos:
            return arrayPhotos.count
        case .loader:
            return page <= maxPage ? 1 : 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PhotoCell.key) as? PhotoCell,
              let loaderCell = tableView.dequeueReusableCell(withIdentifier: LoadingCell.key) as? LoadingCell else { return UITableViewCell() }
        
        switch TableSection.allCases[indexPath.section] {
        case .photos:
            cell.prepareForReuse()
            guard var image = UIImage(systemName: "exclamationmark.icloud.fill") else { return UITableViewCell() }
            if let key = arrayPhotos[indexPath.row].image, let cashedImage = imageCache.object(forKey: key as NSString) {
                image = cashedImage
            }
            cell.configureUI(photo: image, text: arrayPhotos[indexPath.row].name)
            cell.updateConstraints()
            return cell
        case .loader:
            loaderCell.updateConstraints()
            return loaderCell
        }
    }
}


//MARK: UIImagePickerControllerDelegate
extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage, let index = photoIndexPath {
            sendPhotoToServer(photo: image, id: arrayPhotos[index.row].id, userName: Constants.devName ?? "")
            photoIndexPath = nil
            picker.dismiss(animated: true)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
