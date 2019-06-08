//
//  Copyright © 2019 Murray, Emmet. All rights reserved.
//

import UIKit
import Vision


class ViewController: UIViewController {
    
    private enum Message {
        static let tryAgain = "Please try to take the image again".localize()
    }
    
    private enum Title {
        static let processSuccess = "Finished processing image".localize()
        
        static let processFailure = "Failed to process image".localize()
        static let requestFailure = "Failed to perform request".localize()
        static let imageLoadFailure = "Failed to load image".localize()
        
        static let alertButton = "Ok".localize()
    }
    
    lazy var model: VNCoreMLModel = {
       return try! VNCoreMLModel(for: Cards().model)
    }()
    
    
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var takePictureButton: UIButton!
    @IBOutlet weak private var selectPhotoButton: UIButton!
    
    @IBAction private func takePhoto(_ sender: Any) {
        showImagePicker(with: .camera)
    }
    
    @IBAction func selectPhoto(_ sender: Any) {
        showImagePicker(with: .savedPhotosAlbum)
    }
    
    private func showImagePicker(with sourceType: UIImagePickerController.SourceType) {
        takePictureButton.isEnabled = false
        selectPhotoButton.isEnabled = false
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func analyzeImage(_ image: UIImage) {
        let coreRequest = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                self?.presentAlert(title: Title.processFailure, message: Message.tryAgain)
                return
            }
            let message = results.prefix(5).map { $0.resultDescription }.joined(separator: "\n")
            self?.presentAlert(title: Title.processSuccess, message: message)
            DispatchQueue.main.async { [weak self] in
                self?.selectPhotoButton.isEnabled = true
                self?.takePictureButton.isEnabled = true
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([coreRequest])
            } catch {
                self.presentAlert(title: Title.requestFailure, message: Message.tryAgain)
            }
        }
    }
}


extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        if let image = info[.originalImage] as? UIImage {
            DispatchQueue.main.async { [weak self] in
                self?.imageView.image = image
            }
            analyzeImage(image)
        } else {
            presentAlert(title: Title.imageLoadFailure, message: Message.tryAgain)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        DispatchQueue.main.async { [weak self] in
            self?.selectPhotoButton.isEnabled = true
            self?.takePictureButton.isEnabled = true
        }
        dismiss(animated: true, completion: nil)
    }
}


extension ViewController {
    func presentAlert(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: Title.alertButton, style: .default)
            controller.addAction(action)
            self?.present(controller, animated: true, completion: nil)
        }
    }
}


extension VNClassificationObservation {
    var resultDescription: String {
        return String(format: NSLocalizedString("%@ - %.2f%%", comment: ""), identifier, confidence * 100)
    }
}


extension String {
    func localize(with comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}
