import UIKit
import Photos

/// Wrap a PHAsset for video
public class Video: Equatable {
    
    public let asset: PHAsset
    
    var durationRequestID: Int = 0
    var duration: Double = 0
    
    // MARK: - Initialization
    
    init(asset: PHAsset) {
        self.asset = asset
    }
    
    /// Fetch video duration asynchronously
    ///
    /// - Parameter completion: Called when finish
    func fetchDuration(_ completion: @escaping (Double) -> Void) {
        guard duration == 0
            else {
                DispatchQueue.main.async {
                    completion(self.duration)
                }
                return
        }
        
        DispatchQueue.main.async {
            if (self.asset.duration != 0.0){
                self.duration = self.asset.duration
                completion(self.duration)
            }else{
                completion(self.duration)
            }
        }
    }
    
    /// Fetch AVPlayerItem asynchronoulys
    ///
    /// - Parameter completion: Called when finish
    public func fetchPlayerItem(_ completion: @escaping (AVPlayerItem?) -> Void) {
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: videoOptions) {
            item, _ in
            
            DispatchQueue.main.async {
                completion(item)
            }
        }
    }
    
    /// Fetch AVAsset asynchronoulys
    ///
    /// - Parameter completion: Called when finish
    public func fetchAVAsset(_ completion: @escaping (AVAsset?) -> Void, progressCallback :((Double, Error?) -> Void)? = nil) {
                
        let imageManager = PHImageManager()
        var avAsset: AVAsset?
        
        let options = videoOptions
        
        options.progressHandler = {(progress, error,_,_) in
            
            debugPrint(progress)
            if let pCalback = progressCallback{
                pCalback(progress ?? 0, error)
            }
        }
      
        // Now go fetch the AVAsset for the given PHAsset
        imageManager.requestAVAsset(forVideo: asset, options: options) { (requestedAsset, _, _) in
            
            // We're done, let the semaphore know it can unlock now
            let videoData :Data
            if let avassetURL = requestedAsset as? AVURLAsset {
                guard let video = try? Data(contentsOf: avassetURL.url) else {
                    return
                }
                videoData = video
                let URL = self.storeVideo(file: avassetURL.url, data: videoData)
                
                avAsset = AVAsset(url: URL!)
                
                debugPrint(avAsset!.duration)
                debugPrint(avAsset!.description)
                DispatchQueue.main.async {
                    completion(avAsset)
                }
            }
        }

    }
    
    func requestAVAsset(asset: PHAsset) -> AVAsset? {
        // We only want videos here
        guard asset.mediaType == .video else { return nil }
        // Create your semaphore and allow only one thread to access it
        let semaphore = DispatchSemaphore.init(value: 0)
        let imageManager = PHImageManager()
        var avAsset: AVAsset?
      
        // Now go fetch the AVAsset for the given PHAsset
        imageManager.requestAVAsset(forVideo: asset, options: videoOptions) { (requestedAsset, _, _) in
            
            // We're done, let the semaphore know it can unlock now
            let videoData :Data
            if let avassetURL = requestedAsset as? AVURLAsset {
                guard let video = try? Data(contentsOf: avassetURL.url) else {
                    return
                }
                videoData = video
                let URL = self.storeVideo(file: avassetURL.url, data: videoData)
                
                avAsset = AVAsset(url: URL!)
                
                debugPrint(avAsset!.duration)
                debugPrint(avAsset!.description)
            }
            
            semaphore.signal()
        }
        // Lock the thread with the wait() command
        semaphore.wait()
        return avAsset
    }
    
    func storeVideo(file :URL, data:Data?) -> URL? {
        if let videoData = data{
            let fileName = ProcessInfo().globallyUniqueString
            let fileExtension = file.pathExtension
            let file = "\(fileName).\(fileExtension)"
            let tmpDir = NSTemporaryDirectory()
            let fileURL = URL(fileURLWithPath: tmpDir, isDirectory: true).appendingPathComponent(file)
            try? videoData.write(to: fileURL)
                return fileURL
            }
            return nil
        }
    
    /// Fetch thumbnail image for this video asynchronoulys
    ///
    /// - Parameter size: The preferred size
    /// - Parameter completion: Called when finish
    public func fetchThumbnail(size: CGSize = CGSize(width: 100, height: 100), completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options) { image, _ in
                DispatchQueue.main.async {
                    completion(image)
                }
        }
    }
    
    // MARK: - Helper
    private var videoOptions: PHVideoRequestOptions {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        
        return options
    }
}

// MARK: - Equatable

public func ==(lhs: Video, rhs: Video) -> Bool {
    return lhs.asset == rhs.asset
}
