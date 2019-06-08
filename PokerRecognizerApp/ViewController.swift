//
//  Copyright © 2019 Murray, Emmet. All rights reserved.
//

import UIKit
import Vision


final class ViewController: UIViewController {
    
    private enum Message {
        static let tryAgain = "Please try to take the image again".localize()
    }
    
    private enum Title {
        static let alertButton = "Ok".localize()

        enum Sucess {
            static let processing = "Finished processing image".localize()
        }
        
        enum Failure {
            static let processing = "Failed to process image".localize()
            static let request = "Failed to perform request".localize()
            static let imageLoading = "Failed to load image".localize()
        }
    }
    
    private enum DisplayParameter {
        static let numberOfResults = 5
    }
    
    private lazy var model: VNCoreMLModel = {
       return try! VNCoreMLModel(for: Cards().model)
    }()
    
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var takePhotoButton: UIButton!
    @IBOutlet weak private var selectPhotoButton: UIButton!
    
    @IBAction private func takePhoto(_ sender: Any) {
        showImagePicker(with: .camera)
    }
    
    @IBAction func selectPhoto(_ sender: Any) {
        showImagePicker(with: .savedPhotosAlbum)
    }
    
    private func showImagePicker(with sourceType: UIImagePickerController.SourceType) {
        updateInput(enabled: false)
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func analyzeImage(_ image: UIImage) {
        let coreRequest = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                self?.presentAlert(title: Title.Failure.processing, message: Message.tryAgain)
                return
            }
            let message = results.prefix(DisplayParameter.numberOfResults).map { $0.resultDescription }.joined(separator: "\n")
            self?.presentAlert(title: Title.Sucess.processing, message: message)
            self?.updateInput(enabled: true)
        }
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([coreRequest])
            } catch {
                self.presentAlert(title: Title.Failure.request, message: Message.tryAgain)
            }
        }
    }
    
    private func updateInput(enabled: Bool) {
        DispatchQueue.main.async {
            self.selectPhotoButton.isEnabled = enabled
            self.takePhotoButton.isEnabled = enabled
        }
    }
}


extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        if let image = info[.originalImage] as? UIImage {
            DispatchQueue.main.async { self.imageView.image = image }
            analyzeImage(image)
        } else {
            presentAlert(title: Title.Failure.imageLoading, message: Message.tryAgain)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        updateInput(enabled: true)
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
