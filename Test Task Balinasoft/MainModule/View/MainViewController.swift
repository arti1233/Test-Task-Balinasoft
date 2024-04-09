import UIKit
import SnapKit

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
    
    var viewModel: MainViewModelProtocol = MainViewModel()
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.getPhotos()
        configureUI()
        
        viewModel.onUpdateTableView = { [weak self] in
            guard let self else { return }
            self.mainTableView.reloadData()
        }
        
        viewModel.onPresentAlert = { [weak self] text, title in
            guard let self else { return }
            showAllert(text: text, title: title)
        }
    }
    
    //MARK: UIAlertController
    
    func showAllert(text: String, title: String) {
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    //MARK: UI
    
    private func configureUI() {
        view.addSubview(mainTableView)
        
        mainTableView.snp.makeConstraints {
            $0.trailing.leading.bottom.top.equalToSuperview()
        }
    }
}

//MARK: - MainViewController extension


//MARK: UITableViewDelegate
extension MainViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch TableSection.allCases[indexPath.section] {
        case .loader:
            viewModel.getPhotos()
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAllert(text: "Device has no camera.", title: "Camera Error")
            return
        }
        viewModel.changeSentPhotoIndexPath(indexPath: indexPath)
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
            return viewModel.getNumberOfCells()
        case .loader:
            return viewModel.showLoader() 
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PhotoCell.key) as? PhotoCell,
              let loaderCell = tableView.dequeueReusableCell(withIdentifier: LoadingCell.key) as? LoadingCell else { return UITableViewCell() }
        
        switch TableSection.allCases[indexPath.section] {
        case .photos:
            return viewModel.configurePhotoCell(indexPath: indexPath, cell: cell)
        case .loader:
            loaderCell.updateConstraints()
            return loaderCell
        }
    }
}


//MARK: UIImagePickerControllerDelegate
extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            viewModel.sendPhotoToServer(photo: image)
            viewModel.changeSentPhotoIndexPath(indexPath: nil)
            picker.dismiss(animated: true)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
