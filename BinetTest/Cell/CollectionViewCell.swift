//
//  CollectionViewCell.swift
//  BinetTest
//
//  Created by Федор Шашков on 25.01.2024.
//

import UIKit
import Alamofire


// Класс ячейки в collectionView
class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Настройка границ ячейки
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(red: 72/255, green: 76/255, blue: 76/255, alpha: 0.15).cgColor
        layer.cornerRadius = 8.0
        clipsToBounds = true
    }
    
    //Настройка содержимого элементов ячейки
    func configureCell(withItem item: [String: Any], baseUrl: String) {
        titleLabel.text = item["name"] as? String ?? ""
        descriptionLabel.text = item["description"] as? String ?? ""
        
        if let imageUrlString = item["image"] as? String,
           let encodedUrlString = imageUrlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let imageUrl = URL(string: baseUrl + encodedUrlString) {
            downloadImage(from: imageUrl)
        } else {
            print("Invalid image URL")
        }
    }
    
    // Метод для загрузки изображения с использованием Alamofire
    private func downloadImage(from url: URL) {
        AF.request(url).responseData { response in
            switch response.result {
            case .success(let data):
                if let image = UIImage(data: data) {
                    self.imageView.image = image
                }
            case .failure(let error):
                print("Image download failed with error: \(error)")
            }
        }
    }
    
  
    
}



