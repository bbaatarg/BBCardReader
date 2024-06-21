//
//  ViewController.swift
//  BBCardReaderExample
//
//  Created by bayraa on 2024.06.19.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleLabel)
        view.addSubview(buttonQR)
        view.addSubview(buttonCard)
        view.addSubview(cardResultView)

        view.backgroundColor = UIColor(red: 31.0/255.0, green: 33.0/255.0, blue: 35.0/255.0, alpha: 1.0)
        
        cardResultView.isHidden = true
        
        let originY = view.frame.height - 160.0
        let marginX = 24.0
        let buttonWidth = view.frame.width - marginX - marginX
        
        titleLabel.frame = CGRect(x: marginX, y: 88.0, width: buttonWidth, height: 24.0)
        buttonQR.frame = CGRect(x: marginX, y: originY, width: buttonWidth, height: 44.0)
        buttonCard.frame = CGRect(x: marginX, y: originY + 44.0 + 16.0, width: buttonWidth, height: 44.0)
        
        buttonQR.addTarget(self, action: #selector(qrSelected), for: .touchUpInside)
        buttonCard.addTarget(self, action: #selector(cardSelected), for: .touchUpInside)
    }

    @objc func qrSelected(){
        
        //Launching QR code scanner
        let scannerVC = BBCardScannerVC { barcode in
            self.showQRResult(result: barcode)
        }
        scannerVC.hintBottomText = "Please keep your mobile phone close to the QR c0de"
        scannerVC.buttonConfirmTitle = "Cancel"
        scannerVC.buttonCompletion = {
            print("button clicked")
        }
        scannerVC.modalPresentationStyle = .fullScreen
        scannerVC.modalTransitionStyle = .crossDissolve
        present(scannerVC, animated: true, completion: nil)
    }
    
    @objc func cardSelected(){
        //Launching credit card scanner
        cardResultView.isHidden = true
        
        let scannerVC = BBCardScannerVC { cardNumber, cardName, cardDate in
            self.cardResultView.setResult(cardNumber: cardNumber, cardName: cardName, cardDate: cardDate)
        }
        scannerVC.hintBottomText = "Please keep your mobile phone close to the credit card"
        scannerVC.buttonConfirmTitle = "Cancel"
        scannerVC.buttonCompletion = {
            print("button clicked")
        }
        scannerVC.modalPresentationStyle = .fullScreen
        scannerVC.modalTransitionStyle = .crossDissolve
        present(scannerVC, animated: true, completion: nil)

    }
    
    func showQRResult(result: String?){
    
        let controller = UIAlertController(title: "Result is", message: result, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Ok", style: .cancel))
        present(controller, animated: true)
    }
    
    lazy var cardResultView : CardPreviewView = {
        let view = CardPreviewView(frame: CGRect(x: 0.0, y: 160.0, width: view.frame.width, height: view.frame.width))
        return view
    }()
    
    lazy var titleLabel : UILabel = {
        
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20.0, weight: .semibold)
        label.text = "BBCard Reader Example"
        label.textColor = .white
        return label
    }()
    
    lazy var buttonQR : UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Scan QR code"
        config.image = UIImage(systemName: "qrcode", withConfiguration: UIImage.SymbolConfiguration(scale: .small))
        config.imagePadding = 4.0
        
        let button = UIButton(configuration: config)
        button.tintColor = .darkText
        button.layer.cornerRadius = 8.0
        button.backgroundColor = .white
        button.clipsToBounds = true
        return button
    }()
    
    lazy var buttonCard : UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Scan Credit Card"
        config.image = UIImage(systemName: "creditcard", withConfiguration: UIImage.SymbolConfiguration(scale: .small))
        config.imagePadding = 4.0

        let button = UIButton(configuration: config)
        button.tintColor = .white
        button.layer.cornerRadius = 8.0
        button.backgroundColor = .systemBlue
        button.clipsToBounds = true
        return button
    }()
}

class CardPreviewView : UIView{
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(bgView)
        bgView.addSubview(numberLabel)
        bgView.addSubview(nameLabel)
        bgView.addSubview(dateLabel)
        
        let marginX = 24.0
        let innerMargin = 16.0
        let cardWidth = frame.width - marginX - marginX
        let cardHeight = cardWidth / 3.0 * 2.0
        
        let innerWidth = cardWidth - innerMargin - innerMargin
        
        var originY = cardHeight - (20.0 + innerMargin) * 3.0 - innerMargin
        bgView.frame = CGRect(x: marginX, y: 0.0, width: cardWidth, height: cardHeight)
        numberLabel.frame = CGRect(x: innerMargin, y: originY, width: innerWidth, height: 20.0)
        originY += innerMargin + 20.0
        nameLabel.frame = CGRect(x: innerMargin, y: originY, width:innerWidth , height: 20.0)
        originY += innerMargin + 20.0
        dateLabel.frame = CGRect(x: innerMargin, y: originY, width:innerWidth , height: 20.0)
        
//        self.isHidden = true
    }
    
    func setResult(cardNumber: String?, cardName: String?, cardDate: String?){
        
        numberLabel.text = cardNumber
        nameLabel.text = cardName
        dateLabel.text = cardDate
        self.isHidden = false
    }
    
    lazy var bgView : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray
        view.layer.cornerRadius = 12.0
        view.layer.masksToBounds = false
        view.layer.shadowOffset = CGSize(width: 12.0, height: 12.0)
        view.layer.shadowRadius = 8.0
        view.layer.shadowColor = UIColor.white.cgColor
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    lazy var numberLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .left
        
        return label
    }()
    
    lazy var nameLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .left
        label.textColor = .white

        return label
    }()
    
    lazy var dateLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .left
        
        return label
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
