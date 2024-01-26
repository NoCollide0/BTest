//
//  ViewController.swift
//  BinetTest
//
//  Created by Федор Шашков on 23.01.2024.
//

import UIKit
import Alamofire

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
        
    
    let url = "http://shans.d2.i-partner.ru"

    
    var dataArray = [[String: Any]]()  // Массив для хранения данных
    var searchDataArray = [[String: Any]]() // Массив для хранения полученых данных при поисковом запросе
    var searching = false // Флаг для разграничения обычной и поисковой загрузки
    var offset = 0 // Переменная для пересчета загруженных элементов
    let limit = 8 // Кол-во загружаемых элементов
    var endOfData = false // Флаг сигнализирующий о том что данные с сервера больше не поступают
    
    
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    let searchTextField = UITextField()
    let messageLabel = UILabel()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        searchTextField.delegate = self

        fetchData()
        buildSearchTextField()
        buildMessageLabel()

        self.collectionView.register(UINib(nibName: "CollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "CollectionViewCell")
        
    }
    
    
    
    // Выполняем запрос с помощью Alamofire и обрабатываем входящие данные
    func fetchData() {
        let urlData = "/api/ppp/index/?offset=\(offset)&limit=\(limit)"
        AF.request(url + urlData).responseJSON { [weak self] response in
            guard let self = self else { return }

            switch response.result {
            case .success(let value):
                if let jsonArray = value as? [[String: Any]] {
                    if jsonArray.isEmpty {
                        print("No more data available.")
                        self.endOfData = true
                    } else {
                        // Обработка случая получения дубликатов, во избежание когда в последней порции данных строятся ячейки дубликаты в collectionView
                        let uniqueItems = jsonArray.filter { newItem in
                            !self.dataArray.contains { existingItem in
                                return newItem["id"] as? Int == existingItem["id"] as? Int
                            }
                        }
                        self.dataArray.append(contentsOf: uniqueItems)
                        let startIndex = self.dataArray.count - uniqueItems.count
                        let endIndex = self.dataArray.count
                        let indexPaths = (startIndex..<endIndex).map { IndexPath(item: $0, section: 0) }
                        self.collectionView.performBatchUpdates({
                            self.collectionView.insertItems(at: indexPaths)
                        }, completion: nil)
                    }
                }
            case .failure(let error):
                print("Error: \(error)")
                self.endOfData = true
                self.showMessage("Сервер не отвечает или отсутствует интернет-соединение. Пожалуйста попробуйте позже.")
            }
        }
    }
    
   
    
    // Настройки collectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var numberOfElements = 0
        if searching == false {
            numberOfElements = dataArray.count
        } else {
            numberOfElements = searchDataArray.count
        }
        return numberOfElements
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        if searching == false {
            let item = dataArray[indexPath.item]
            cell.configureCell(withItem: item, baseUrl: url)
        } else {
            let item = searchDataArray[indexPath.item]
            cell.configureCell(withItem: item, baseUrl: url)
        }
                
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let lastSectionIndex = collectionView.numberOfSections - 1
        let lastItemIndex = collectionView.numberOfItems(inSection: lastSectionIndex) - 1

        if indexPath.section == lastSectionIndex && indexPath.item == lastItemIndex {
            if endOfData == true {
                print("End of data from server")
            } else {
                // Пользователь долистал до последней карточки
                if searching == false {
                    loadMoreData()
                } else {
                    print("")
                }
                
            }

        }
    }
    // Настройка ширины ячейки под экран
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let cellWidth = (screenWidth / 2) - 25
        return CGSize(width: cellWidth, height: 296)
    }
    
    
    
    
    func loadMoreData() {
        offset += limit // Увеличиваем offset перед загрузкой новых данных
        fetchData() // Загружаем новые данные с обновленным offset
    }

    
    
    
    // Настройка сообщения в случае отсутствия интернета или поиска без результата
    func buildMessageLabel() {
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .darkGray
        messageLabel.font = UIFont.systemFont(ofSize: 18)
        messageLabel.isHidden = true
        
        view.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    func showMessage(_ message: String) {
        messageLabel.text = message
        messageLabel.isHidden = false
    }
    func hideMessage() {
        messageLabel.isHidden = true
    }
    
    
    // Настройка поля поиска
    func buildSearchTextField() {
        searchTextField.placeholder = "Введите текст для поиска"
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.isHidden = true
        searchTextField.autocorrectionType = .no
        searchTextField.smartQuotesType = .no
        searchTextField.spellCheckingType = .no
        searchTextField.layer.borderColor = UIColor.gray.cgColor
        searchTextField.layer.borderWidth = 1.0
        searchTextField.layer.cornerRadius = 5.0
        
        view.addSubview(searchTextField)
        
        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: 5),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchTextField.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    
    // Обработка нажатия готово на клавиатуре в поле поиска
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Пользователь ничего не ввел? Возвращаемся к общему списку загруженных данных
        if textField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true {
            textField.isHidden = true
            UIView.animate(withDuration: 0.3) {
                    self.collectionView.contentOffset = CGPoint(x: 0, y: self.searchTextField.frame.height-25)
                }
            self.searching = false
            self.updateCollectionView()
            self.hideMessage()
        } else {
            if let searchText = textField.text?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                let searchUrl = "http://shans.d2.i-partner.ru/api/ppp/index/?search=\(searchText)"
                
                AF.request(searchUrl).responseJSON { response in
                    switch response.result {
                    case .success(let value):
                        if let jsonArray = value as? [[String: Any]] {
                            // Обновляем searchDataArray и перезагружаем collectionView
                            self.searchDataArray = jsonArray
                            
                            if self.searchDataArray.isEmpty {
                                self.updateCollectionView()
                                self.searching = true
                                self.showMessage("Ничего не найдено.")
                            } else {
                                self.updateCollectionView()
                                self.searching = true
                                self.hideMessage()
                            }
                        }
                    case .failure(let error):
                        // Обработка ошибок
                        print("Error: \(error)")
                        self.searching = true
                        self.showMessage("Сервер не отвечает или отсутствует интернет-соединение. Пожалуйста попробуйте позже.")
                    }
                }
            }
            textField.isHidden = true
            UIView.animate(withDuration: 0.3) {
                    self.collectionView.contentOffset = CGPoint(x: 0, y: self.searchTextField.frame.height-35)
                }
        }
        self.view.endEditing(true)
        
        return true
    }
    
    
    // Обновление содержимого collectionView
    func updateCollectionView() {
        UIView.transition(with: self.collectionView, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.collectionView.reloadData()
        }, completion: nil)
    }
    
    
    
    
    // Кнопка поиска
    @IBAction func searchButtonTapped(_ sender: Any) {
        collectionView.setContentOffset(collectionView.contentOffset, animated: false)
        UIView.animate(withDuration: 0.3) {
                self.collectionView.contentOffset = CGPoint(x: 0, y: -self.searchTextField.frame.height+15)
            }
        searchTextField.isHidden = false
        searchTextField.becomeFirstResponder()
        print("Button tapped")
    }
    

    
    
}

