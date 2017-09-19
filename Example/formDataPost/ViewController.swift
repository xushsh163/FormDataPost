//
//  ViewController.swift
//  formDataPost
//
//  Created by xushsh163 on 09/17/2017.
//  Copyright (c) 2017 xushsh163. All rights reserved.
//

import UIKit
import formDataPost

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate
{

    var res: String = "";
    var textField : UITextView!
    var label : UILabel!
    var label2 : UILabel!
    let str : String = "enter url: "
    let str2 : String = "progress: "
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let button = UIButton(frame: CGRect(x: 50, y: 210, width: 100, height: 50))
        button.setTitle("upload", for: UIControlState(rawValue: 0))
        button.backgroundColor = UIColor.red
        button.addTarget(self, action: #selector(ratingButtonTapped), for: .touchUpInside)
        self.view.addSubview(button)
        
        let placeholder = NSAttributedString(string: "Enter here", attributes: [NSForegroundColorAttributeName: UIColor.lightGray])
        textField = UITextView(frame: CGRect(x: 10, y: 100, width: 300, height: 100))
        
        textField.textColor = UIColor.black
        textField.delegate = self
//        textField.borderStyle = UITextBorderStyle.roundedRect
//        textField.clearsOnBeginEditing = true
        textField.text = "http://enter_your_token_server"
        view.addSubview(textField)
        
        label = UILabel(frame: CGRect(x: 10, y: 50, width: 200, height: 20))
        label.text = str
        view.addSubview(label)
        label2 = UILabel(frame: CGRect(x: 10, y: 320, width: 200, height: 20))
        label2.text = str2
        view.addSubview(label2)
    }
    
    // MARK: Button Action
    func ratingButtonTapped(_ button: UIButton) {
        let url = textField.text
        let ret = FormDataPost.getUploadToken(url!, {(ret: String)-> Void in
            DispatchQueue.main.async() {
                // Do stuff to UI
                // self.showToast(message: "res: \(ret)")
                self.res = ret;
                let picker = UIImagePickerController()
                picker.allowsEditing = false
                picker.sourceType = .photoLibrary
                picker.delegate = self
                self.present(picker, animated: true, completion: nil)
            }
        })
        showToast(message: "ret: \(ret)")
    }
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        let imageURL = info[UIImagePickerControllerReferenceURL] as! NSURL
        let imageName = imageURL.lastPathComponent
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let photoURL          = NSURL(fileURLWithPath: documentDirectory)
        let localPath         = photoURL.appendingPathComponent(imageName!)
        if !FileManager.default.fileExists(atPath: localPath!.path) {
            do {
                try UIImageJPEGRepresentation(chosenImage, 1.0)?.write(to: localPath!)
                print("file saved")
            }catch {
                print("error saving file")
            }
        }
        else {
            print("file already exists")
        }
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: self.res.data(using: .utf8)!) as? [String: String]
            let jsonObject: [String: String] = [
                "key": jsonDict!["dir"]! + imageName!,
                "policy": jsonDict!["policy"]!,
                "OSSAccessKeyId": jsonDict!["accessid"]!,
                "success_action_status": "200",
                "callback": jsonDict!["callback"]!,
                "signature": jsonDict!["signature"]!
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
            let dictFromJSON = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
            let res = FormDataPost.upload((localPath?.path)!, "file", jsonDict!["host"]!, dictFromJSON,
                                          { (ret) in
                                            DispatchQueue.main.async() {
                                                // Do stuff to UI
                                                self.label2.text = self.str2 + String(ret * 100)
                                            }
            },
                                          { (ret) in
                DispatchQueue.main.async() {
                    // Do stuff to UI
                    self.showToast(message: "res: \(ret)")
                }
            })
        } catch {
            self.showToast(message: "error: \(error)")
        }
        
        
        
        // use the image
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //Color #2 - While selecting the text field
        self.textField.text = textField.text
    }

}

