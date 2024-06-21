//
//  BBCardScannerVC.swift
//  BBCardReaderExample
//
//  Created by bayraa on 2024.06.19.
//
import AVFoundation
import CoreImage
import UIKit
import Vision


public enum BBScannerType {
    case creditCard
    case qrCode
}

public typealias BBCreditCardScannerResult = (_ cardNumber : String, _ cardName : String, _ cardDate : String) -> Void
public typealias BBQRcodeScannerResult = (_ barcode : String) -> Void

public class BBCardScannerVC: UIViewController {
    // MARK: - STATIC DECLARATIONS
    
    let marginX = 24.0
    let maskMargin = 24.0
    
    let marginL = 32.0
    let marginXL = 44.0
    
    //CREDIT CARD ASPECT
    static let cardScannerAspectWidth = 17.0
    static let cardScannerAspectHeight = 11.0
    
    //BAR CODE ASPECT
    static let qrCodeScannerAspectWidth = 1.0
    static let qrCodeScannerAspectHeight = 1.0
    
    var scannerType : BBScannerType = .creditCard
    
    // MARK: - Private Properties
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        preview.videoGravity = .resizeAspectFill
        return preview
    }()

    private let device = AVCaptureDevice.default(for: .video)

    private var viewGuide: PartialTransparentView!

    var creditCardNumber: String?
    var creditCardName: String?
    var creditCardDate: String?
    
    var gotQRCode = false
    private let videoOutput = AVCaptureVideoDataOutput()

    // MARK: - Public Properties

    public var hintBottomText : String = ""
    public var buttonConfirmTitle :String = ""
    public var viewTitle : String = ""

    private var creditcardResultHandler: BBCreditCardScannerResult?
    private var qrCodeResultHandler: BBQRcodeScannerResult?
    var buttonCompletion : (() -> ())?
    
    // MARK: - Initializers
    //CREDIT CARD READER
    init(creditCardResult: @escaping BBCreditCardScannerResult) {
        self.scannerType = .creditCard
        self.creditcardResultHandler = creditCardResult
        super.init(nibName: nil, bundle: nil)
    }
    
    //QR READER
    init(qrcodeResult: @escaping BBQRcodeScannerResult) {
        self.scannerType = .qrCode
        self.qrCodeResultHandler = qrcodeResult
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        view = UIView()
    }

    deinit {
        stop()
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        setupPopupUI()
        captureSession.startRunning()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }

    // MARK: - Add Views

    private func setupCaptureSession() {
        addCameraInput()
        addPreviewLayer()
        addVideoOutput()
        addGuideView()
    }

    private func addCameraInput() {
        guard let device = device else { return }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        captureSession.addInput(cameraInput)
    }

    private func addPreviewLayer() {
        view.layer.addSublayer(previewLayer)
    }

    private func addVideoOutput() {
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as NSString: NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "my.image.handling.queue"))
        captureSession.addOutput(videoOutput)
        
        guard let connection = videoOutput.connection(with: AVMediaType.video),
            connection.isVideoOrientationSupported else {
            return
        }
        connection.videoOrientation = .portrait
    }

    private func addGuideView() {
        
        
        let areaWidth = UIScreen.main.bounds.width - (marginX * 2.0)
        let areaHeight = self.scannerType == .creditCard ? areaWidth / BBCardScannerVC.cardScannerAspectWidth * BBCardScannerVC.cardScannerAspectHeight : areaWidth
        
        
        let marginY = ((UIScreen.main.bounds.height - areaHeight) / 2.0) - 150.0

        viewGuide = PartialTransparentView(rectsArray: [CGRect(x: marginX, y: marginY, width: areaWidth, height: areaHeight)])
        viewGuide.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(viewGuide)
        view.bringSubviewToFront(viewGuide)
     
        titleLabel.text = viewTitle
        hintLabel.text = hintBottomText
        
        confirmButton.setTitle(buttonConfirmTitle, for: .normal)
        confirmButton.addTarget(self, action: #selector(bottomButtonClicked), for: .touchUpInside)
        
        view.addSubview(titleLabel)
        view.addSubview(hintLabel)
        view.addSubview(confirmButton)
        
        let cardAttributeX = marginX + maskMargin
        
        NSLayoutConstraint.activate([

            viewGuide.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            viewGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            viewGuide.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            viewGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
                        
            hintLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: marginY + areaHeight + maskMargin),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintLabel.widthAnchor.constraint(equalToConstant: 280.0),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: maskMargin),
            titleLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: cardAttributeX),
            titleLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -cardAttributeX),
                        
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -marginX),
            confirmButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: marginX),
            confirmButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -marginX),
            confirmButton.heightAnchor.constraint(equalToConstant: 44.0)
        ])

        
        if scannerType == .creditCard {
            
            dismissButton.addTarget(self, action: #selector(dismissButtonClicked), for: .touchUpInside)
            
            view.addSubview(cNumberLabel)
            view.addSubview(cDateLabel)
            view.addSubview(cNameLabel)
            view.addSubview(dismissButton)
            
            NSLayoutConstraint.activate([
                cNumberLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: marginY + (areaHeight / 2.0) ),
                cNumberLabel.leftAnchor.constraint(equalTo: viewGuide.leftAnchor, constant: cardAttributeX),
                cNumberLabel.rightAnchor.constraint(equalTo: viewGuide.rightAnchor, constant: -cardAttributeX),
                cNumberLabel.heightAnchor.constraint(equalToConstant: 26.0),
                
                cNameLabel.topAnchor.constraint(equalTo: cNumberLabel.bottomAnchor, constant: marginX),
                cNameLabel.leftAnchor.constraint(equalTo: viewGuide.leftAnchor, constant: cardAttributeX),
                cNameLabel.heightAnchor.constraint(equalToConstant: 20.0),
                cNameLabel.rightAnchor.constraint(equalToSystemSpacingAfter: viewGuide.centerXAnchor, multiplier: -marginX),
                
                cDateLabel.topAnchor.constraint(equalTo: cNameLabel.topAnchor),
                cDateLabel.leftAnchor.constraint(equalTo: viewGuide.centerXAnchor, constant: marginX),
                cDateLabel.rightAnchor.constraint(equalTo: viewGuide.rightAnchor, constant: -cardAttributeX),
                cDateLabel.heightAnchor.constraint(equalToConstant: 20.0),
                
                dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                dismissButton.leftAnchor.constraint(equalTo: view.leftAnchor),
                dismissButton.heightAnchor.constraint(equalToConstant: 40.0),
                dismissButton.widthAnchor.constraint(equalToConstant: 40.0)
            ])
        }
    }
    
    func setupPopupUI(){
        
        popupView.alpha = 0.0
        view.addSubview(popupView)
        
        let fontSize = 60.0
        
        let iconLabel = UILabel()
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.textColor = .systemRed
        iconLabel.textAlignment = .center
        iconLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .light)
        iconLabel.text = "QR"
        popupView.addSubview(iconLabel)
        
        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.textColor = .systemGray2
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        descLabel.font = UIFont.systemFont(ofSize: 20.0)
        descLabel.text = "Invalid QR Code, please try again."
        popupView.addSubview(descLabel)
        
        let okButton = UIButton()
        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.setTitleColor(.white, for: .normal)
        okButton.backgroundColor = .systemYellow
        okButton.clipsToBounds = true
        okButton.layer.cornerRadius = 8.0
        okButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
        okButton.setTitle("Ок", for: .normal)
        okButton.addTarget(self, action: #selector(tryScanAgain), for: .touchUpInside)
        popupView.addSubview(okButton)
        
        NSLayoutConstraint.activate([
            popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popupView.widthAnchor.constraint(equalToConstant: 335.0),
            popupView.heightAnchor.constraint(equalToConstant: 290.0),
            
            iconLabel.topAnchor.constraint(equalTo: popupView.topAnchor, constant: marginXL),
            iconLabel.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: fontSize),
            iconLabel.heightAnchor.constraint(equalToConstant: fontSize),
            
            descLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: marginL),
            descLabel.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            descLabel.widthAnchor.constraint(equalToConstant: 187.0),
            
            okButton.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -marginX),
            okButton.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            okButton.heightAnchor.constraint(equalToConstant: 40.0),
            okButton.widthAnchor.constraint(equalToConstant: 128.0)
        ])
    }

    func changeCardNumberStyle(number : String) -> String{
        
        let spaceless = number.replacingOccurrences(of: " ", with: "", options: .literal)
        
        let convertedNumber = NSNumber(value: Int(spaceless) ?? 0)
        
        let numberFormatter = NumberFormatter()
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.groupingSeparator = " "
        numberFormatter.groupingSize = 4
        
        return numberFormatter.string(from: convertedNumber) ?? ""
    }

    // MARK: - Completed process
    @objc func dismissButtonClicked(){
        stop()
        self.dismiss(animated: true)
    }
    
    @objc func bottomButtonClicked() {
        
        stop()
        dismiss(animated: true) {
            self.buttonCompletion!()
        }
    }

    @objc func showWrongQRCodePopup(){
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseInOut) {
                self.popupView.alpha = 1.0
            }
        }
        
    }
    
    @objc func dissmissWrongQRCodePopup(){
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseInOut) {
                self.popupView.alpha = 0.0
            }
        }
    }
    
    private func stop() {
        captureSession.stopRunning()
    }

    // MARK: - Card text detection
    private func handleObservedPaymentCard(in frame: CVImageBuffer) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.extractPaymentCardData(frame: frame)
        }
    }

    private func extractPaymentCardData(frame: CVImageBuffer) {
        let ciImage = CIImage(cvImageBuffer: frame, options: [.applyOrientationProperty : true])
        
        let resizeFilter = CIFilter(name: "CILanczosScaleTransform")!

        // Desired output size
        let targetSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)

        // Compute scale and corrective aspect ratio
        let scale = targetSize.height / ciImage.extent.height
        let aspectRatio = targetSize.width / (ciImage.extent.width * scale)

        resizeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        resizeFilter.setValue(scale, forKey: kCIInputScaleKey)
        resizeFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)

        let outputImage = resizeFilter.outputImage
        
        if scannerType == .creditCard {
            self.getCardInformation(image: outputImage!)
        }else{
            self.getQRCodeInformatino(image: outputImage!)
        }
    }
    
    func getQRCodeInformatino(image : CIImage) {
        
        if gotQRCode {
            return
        }
        
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: options)
        let features = qrDetector?.features(in: image, options: options)

        for feature in features as! [CIQRCodeFeature] where feature.messageString != nil{

            self.tapticFeedback()
            gotQRCode = true
            guard let handler = self.qrCodeResultHandler, let qrCode = feature.messageString else {return}
            
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    handler(qrCode)
                }
            }
            return
        }
    }
    
    func getCardInformation(image : CIImage){
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate


        let stillImageRequestHandler = VNImageRequestHandler(ciImage: image, options: [:])
        try? stillImageRequestHandler.perform([request])

        guard let texts = request.results, texts.count > 0 else {
            // no text detected
            return
        }
        
        let arrayLines = texts.flatMap({ $0.topCandidates(20).map({ $0.string }) })

        for line in arrayLines {

            let trimmed = line.replacingOccurrences(of: " ", with: "")

            if creditCardNumber == nil &&
                trimmed.count >= 15 &&
                trimmed.count <= 16 &&
                trimmed.isOnlyNumbers {
                creditCardNumber = self.changeCardNumberStyle(number: line)
                DispatchQueue.main.async {
                    self.cNumberLabel.text = self.creditCardNumber
                    self.tapticFeedback()
                    self.checkCardInputs()
                }
                continue
            }

            if creditCardDate == nil &&
                trimmed.count >= 5 && // 12/20
                trimmed.count <= 7 && // 12/2020
                trimmed.isDate {
                
                creditCardDate = line
                DispatchQueue.main.async {
                    self.cDateLabel.text = line
                    self.tapticFeedback()
                    self.checkCardInputs()
                }
                continue
            }

            // Not used yet
            if creditCardName == nil &&
                trimmed.count > 10 &&
                line.contains(" ") &&
                trimmed.isOnlyAlpha {
                
                creditCardName = line
                DispatchQueue.main.async {
                    self.cNameLabel.text = line
                    self.tapticFeedback()
                    self.checkCardInputs()
                }
                continue
            }
        }
    }
    
    func checkCardInputs(){
        
        guard let number = creditCardNumber, let name = creditCardName, let date = creditCardDate else { return }
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                self.creditcardResultHandler!(number, name, date)
            }
        }
    }

    @objc func tryScanAgain(){
        dissmissWrongQRCodePopup()
        gotQRCode = false
    }
    
    private func tapticFeedback() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    lazy var cNumberLabel : UILabel = {
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        label.textColor = .white
        
        return label
    }()
    
    lazy var cDateLabel : UILabel = {
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        label.textColor = .white
        
        return label
    }()
    
    lazy var cNameLabel : UILabel = {
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        label.textColor = .white
        
        return label
    }()
    
    lazy var titleLabel : UILabel = {
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = .white
        label.textAlignment = .center
        
        return label
    }()
    
    lazy var hintLabel : UILabel = {
        
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = .white
        label.textAlignment = .center
        
        return label
    }()

    lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8.0
        return button
    }()
    
    lazy var dismissButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    lazy var popupView : UIView = {
       
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 20.0
        view.clipsToBounds = true
        
        return view
    }()
    
    

}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension BBCardScannerVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }

        handleObservedPaymentCard(in: frame)
    }
}

// MARK: - Extensions

private extension String {
    var isOnlyAlpha: Bool {
        return !isEmpty && range(of: "[^a-zA-Z]", options: .regularExpression) == nil
    }

    var isOnlyNumbers: Bool {
        return !isEmpty && range(of: "[^0-9]", options: .regularExpression) == nil
    }

    // Date Pattern MM/YY or MM/YYYY
    var isDate: Bool {
        let arrayDate = components(separatedBy: "/")
        if arrayDate.count == 2 {
            let currentYear = Calendar.current.component(.year, from: Date())
            if let month = Int(arrayDate[0]), let year = Int(arrayDate[1]) {
                if month > 12 || month < 1 {
                    return false
                }
                if year < (currentYear - 2000 + 20) && year >= (currentYear - 2000) { // Between current year and 20 years ahead
                    return true
                }
                if year >= currentYear && year < (currentYear + 20) { // Between current year and 20 years ahead
                    return true
                }
            }
        }
        return false
    }
}

// MARK: - Class PartialTransparentView

class PartialTransparentView: UIView {
    var rectsArray: [CGRect]?

    convenience init(rectsArray: [CGRect]) {
        self.init()

        self.rectsArray = rectsArray

        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        isOpaque = false
    }

    override func draw(_ rect: CGRect) {
        backgroundColor?.setFill()
        UIRectFill(rect)

        guard let rectsArray = rectsArray else {
            return
        }

        for holeRect in rectsArray {
            let path = UIBezierPath(roundedRect: holeRect, cornerRadius: 10)

            let dashes : [CGFloat] = [14.0, 14.0]
            let holeRectIntersection = rect.intersection(holeRect)

            UIRectFill(holeRectIntersection)

            UIColor.clear.setFill()
            UIGraphicsGetCurrentContext()?.setBlendMode(CGBlendMode.copy)

            path.lineJoinStyle = .round
            path.lineWidth = 2.0
            path.lineCapStyle = .round
            path.setLineDash(dashes, count: dashes.count, phase: 0.0)
            
            UIColor.white.setStroke()
            path.stroke()

            path.fill()
        }
    }
}
