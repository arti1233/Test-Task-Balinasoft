import Foundation
import SnapKit
import UIKit

final class PhotoCell: UITableViewCell {
 
    //MARK: - Properties
    
    static var key = "PhotoCell"
    
    private lazy var mainView: UIView = {
        var view = UIView()
        view.backgroundColor = .blue.withAlphaComponent(0.5)
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.4
        view.layer.shadowOffset = CGSize(width: 5, height: 4)
        view.layer.cornerRadius = 20
        return view
    }()
    
    private lazy var photoImage: UIImageView = {
        var view = UIImageView()
        view.contentMode = .scaleToFill
        view.tintColor = .black
        return view
    }()
    
    private lazy var nameLabel: UILabel = {
        var label = UILabel()
        label.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        label.numberOfLines = 0
        return label
    }()

    //MARK: - LifeCycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(mainView)
        mainView.addSubview(photoImage)
        mainView.addSubview(nameLabel)        
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - UI
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImage.image = UIImage()
        nameLabel.text = ""
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        mainView.snp.makeConstraints {
            $0.trailing.leading.top.bottom.equalToSuperview().inset(8)
        }
        
        photoImage.snp.makeConstraints {
            $0.height.equalTo(100)
            $0.width.equalTo(100)
            $0.top.bottom.equalToSuperview().inset(24)
            $0.leading.equalToSuperview().inset(8)
        }
        
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(photoImage.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(16)
        }
    }
    
    func configureUI(photo: UIImage, text: String) {
        photoImage.image = photo
        nameLabel.text = text
    }
}
