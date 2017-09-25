import Foundation
import UIKit
import ImageIO

@objc public class FormDataPost: NSObject {
    
    static var expectedContentLength = 0
    static var savedLength = 0
    static var onProgress: ((Float) -> Void)?
    public static func getUploadToken(_ url: String, _ finished: @escaping (_ cb: String)->Void) -> String {
        do {
            var request = URLRequest(url: URL(string: url)!)
            request.httpMethod = "POST"
            //        let postString = "id=13&name=Jack"
            //        request.httpBody = postString.data(using: .utf8)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {                                                 // check for fundamental networking error
                    print("error=\(String(describing: error))")
                    finished("error: \(String(describing: error))")
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode < 200 || httpStatus.statusCode > 300 {           // check for http errors
                    print("statusCode should be 200, but is \(httpStatus.statusCode)")
                    finished("error: statusCode should be 200, but is \(httpStatus.statusCode)")
                    return
                }
                
                let responseString = String(data: data, encoding: .utf8)
                print("responseString = \(responseString!)")
                finished(responseString!)
            }
            task.resume()
            return "OK"
        } catch {
            return "error: \(error)"
        }
    }
    
    public static func upload(_ filePath: String, _ fileKey: String, _ uploadUrl: String, _ paramJSON: String, _ onProgress: @escaping (_ cb: Float)->Void, _ finished: @escaping (_ cb: String)->Void) -> String {
        do {
            var r  = URLRequest(url: URL(string: uploadUrl)!)
            r.httpMethod = "POST"
            let boundary = "Boundary-\(UUID().uuidString)"
            let json = try JSONSerialization.jsonObject(with: paramJSON.data(using: .utf8)!) as? [String: String]
            r.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
//            var documentsUrl: URL {
//                return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//            }
//            let fileName = URL(string: filePath)?.lastPathComponent
//            let fileURL = documentsUrl.appendingPathComponent(fileName!)
//            let imageData1 = try Data(contentsOf: fileURL)
            let fileManager = FileManager.default
            if (!fileManager.fileExists(atPath: filePath)){
                return "error: image not exists in \(filePath)"
            }
            let image = UIImage(contentsOfFile: filePath) // try UIImage(contentsOfFile: filePath)

            var mT = "image/png"
            var data: Data?
            if let cgImage = image!.cgImage, cgImage.renderingIntent == .defaultIntent {
                data = UIImageJPEGRepresentation(image!, 0.8)
                mT = "image/jpg"
            }
            else {
                data = UIImagePNGRepresentation(image!)
            }
            
            r.httpBody = createBody(parameters: json!,
                                    boundary: boundary,
                                    data: data!,
                                    mimeType: mT,
                                    filename: (filePath as NSString).lastPathComponent,
                                    fileKey: fileKey)
            // set up the session
            FormDataPost.onProgress = onProgress
            FormDataPost.savedLength = 0
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config, delegate: UploadDelegate(onProgress: onProgress), delegateQueue: nil)
            //            let task = URLSession.shared.dataTask(with: r) { data, response, error in
            let task = session.dataTask(with: r) { data, response, error in
                guard let data = data, error == nil else {                                                 // check for fundamental networking error
                    print("error=\(String(describing: error))")
                    DispatchQueue.main.async(){
                        finished("error: \(String(describing: error))")
                    }
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode < 200 || httpStatus.statusCode > 300 {           // check for http errors
                    print("statusCode should be 200, but is \(httpStatus.statusCode)")
                    print("response = \(String(describing: response))")
                    DispatchQueue.main.async(){
                        finished("error: statusCode should be 200, but is \(httpStatus.statusCode)")
                    }
                    return
                }
                
                let responseString = String(data: data, encoding: .utf8)
                print("responseString = \(responseString!)")
                DispatchQueue.main.async(){
                    finished(responseString!)
                }
            }
            task.resume()
            return "OK"
        } catch {
            return "error: \(error)"
        }
    }
    
    public static func uploadImg(_ image: UIImage, _ fileName: String, _ fileKey: String, _ uploadUrl: String, _ paramJSON: String, _ onProgress: @escaping (_ cb: Float)->Void, _ finished: @escaping (_ cb: String)->Void) -> String {
        do {
            var r  = URLRequest(url: URL(string: uploadUrl)!)
            r.httpMethod = "POST"
            let boundary = "Boundary-\(UUID().uuidString)"
            let json = try JSONSerialization.jsonObject(with: paramJSON.data(using: .utf8)!) as? [String: String]
            r.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var mT = "image/png"
            var data: Data?
            if let cgImage = image.cgImage, cgImage.renderingIntent == .defaultIntent {
                data = UIImageJPEGRepresentation(image, 0.8)
                mT = "image/jpg"
            }
            else {
                data = UIImagePNGRepresentation(image)
            }
            
            r.httpBody = createBody(parameters: json!,
                                    boundary: boundary,
                                    data: data!,
                                    mimeType: mT,
                                    filename: fileName,
                                    fileKey: fileKey)
            // set up the session
            FormDataPost.onProgress = onProgress
            FormDataPost.savedLength = 0
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config, delegate: UploadDelegate(onProgress: onProgress), delegateQueue: nil)
            //            let task = URLSession.shared.dataTask(with: r) { data, response, error in
            let task = session.dataTask(with: r) { data, response, error in
                guard let data = data, error == nil else {                                                 // check for fundamental networking error
                    print("error=\(String(describing: error))")
                    DispatchQueue.main.async(){
                        finished("error: \(String(describing: error))")
                    }
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode < 200 || httpStatus.statusCode > 300 {           // check for http errors
                    print("statusCode should be 200, but is \(httpStatus.statusCode)")
                    print("response = \(String(describing: response))")
                    DispatchQueue.main.async(){
                        finished("error: statusCode should be 200, but is \(httpStatus.statusCode)")
                    }
                    return
                }
                
                let responseString = String(data: data, encoding: .utf8)
                print("responseString = \(responseString!)")
                DispatchQueue.main.async(){
                    finished(responseString!)
                }
            }
            task.resume()
            return "OK"
        } catch {
            return "error: \(error)"
        }
    }

    
    private static func createBody(parameters: [String: String],
                    boundary: String,
                    data: Data,
                    mimeType: String,
                    filename: String,
                    fileKey: String) -> Data {
        var body = Data()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            body.append(Data(boundaryPrefix.utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".utf8))
            body.append(Data("\(value)\r\n".utf8))
        }
        
        body.append(Data(boundaryPrefix.utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(fileKey)\"; filename=\"\(filename)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
        body.append(data)
        body.append(Data("\r\n".utf8))
        body.append(Data("--".appending(boundary.appending("--")).utf8))
        
        return body as Data
    }
}

@objc class UploadDelegate: NSObject, URLSessionTaskDelegate {
    var onProgress: ((Float)->Void)?
    
    public init(onProgress: @escaping (_ cb: Float)->Void) {
        self.onProgress = onProgress
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let percentage = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        if self.onProgress != nil {
            DispatchQueue.main.async(){
             self.onProgress!(percentage)
            }
        }
    }
}

struct ImageHeaderData{
    static var PNG: [UInt8] = [0x89]
    static var JPEG: [UInt8] = [0xFF]
    static var GIF: [UInt8] = [0x47]
    static var TIFF_01: [UInt8] = [0x49]
    static var TIFF_02: [UInt8] = [0x4D]
}

enum ImageFormat{
    case Unknown, PNG, JPEG, GIF, TIFF
}


extension NSData{
    var imageFormat: ImageFormat{
        var buffer = [UInt8](repeating: 0, count: 1)
        self.getBytes(&buffer, range: NSRange(location: 0,length: 1))
        if buffer == ImageHeaderData.PNG
        {
            return .PNG
        } else if buffer == ImageHeaderData.JPEG
        {
            return .JPEG
        } else if buffer == ImageHeaderData.GIF
        {
            return .GIF
        } else if buffer == ImageHeaderData.TIFF_01 || buffer == ImageHeaderData.TIFF_02{
            return .TIFF
        } else{
            return .Unknown
        }
    }
}
