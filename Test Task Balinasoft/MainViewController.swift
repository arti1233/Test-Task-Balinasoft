import UIKit
import SnapKit

private enum TableSection: Int, CaseIterable {
    case photos = 0
    case loader
}

final class MainViewController: UIViewController {
    
    private lazy var mainTableView: UITableView = {
        var tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .white
        tableView.register(PhotoUITableViewCell.self, forCellReuseIdentifier: PhotoUITableViewCell.key)
        tableView.register(LoadingTableViewCell.self, forCellReuseIdentifier: LoadingTableViewCell.key)
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private var imageCache = NSCache<NSString, UIImage>()
    
    private var alamofireProvider: AlamofireProtocol?
    
    private var arrayPhotos: [Content] = []
    
    private var page = 0
    
    private var isLoadingPhoto = true
    
    
//MARK: ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
        getPhotos(page: page)
        configureUI()
        
        alamofireProvider = AlamofireProvider()
        
       
    }
    
    func getPhotos(page: Int) {
        guard let alamofireProvider = alamofireProvider, isLoadingPhoto == true else { return }
        isLoadingPhoto = false
        alamofireProvider.getPhotos(page: page, completion: { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let photos):
                print("Все ок")
                photos.content.forEach({self.arrayPhotos.append($0)})
                self.page += 1
                self.loadImageToCache()
                print(photos)
            case .failure(_):
                print("Все плохо")
            }
        })
    }
    
    func loadImageToCache() {
        let group = DispatchGroup()
        for info in arrayPhotos {
            group.enter()
            if let image = info.image, imageCache.object(forKey: image as NSString) == nil {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self else { return }
                    let loadImage = info.image?.image
                    self.imageCache.setObject(loadImage!, forKey: image as NSString)
                    group.leave()
                }
            } else {
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.isLoadingPhoto = true
            self.mainTableView.reloadData()
            print("Позиции загрузились в кэш")
        }
    }
    

    
    
    func configureUI() {
        view.addSubview(mainTableView)
        
        mainTableView.snp.makeConstraints {
            $0.trailing.leading.bottom.top.equalToSuperview()
        }
    }
}

//MARK: - MainViewController extension


//MARK: UITableViewDelegate
extension MainViewController: UITableViewDelegate {
    
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
            return page <= 6 ? 1 : 0
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch TableSection.allCases[indexPath.section] {
        case .loader:
            getPhotos(page: page)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PhotoUITableViewCell.key) as? PhotoUITableViewCell,
              let loaderCell = tableView.dequeueReusableCell(withIdentifier: LoadingTableViewCell.key) as? LoadingTableViewCell else { return UITableViewCell() }
        
        switch TableSection.allCases[indexPath.section] {
        case .photos:
            cell.prepareForReuse()
            var image = UIImage(systemName: "xmark")!
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
