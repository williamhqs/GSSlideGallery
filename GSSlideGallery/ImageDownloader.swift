//
//  PrimaryImageDownloader.swift
//  GSSlideGallery
//
//  Created by William Hu on 8/7/17.
//  Copyright © 2017 William Hu. All rights reserved.
//
import UIKit

class ImageDownloader: NSObject {
    static private let queue = OperationQueue()
    
    class func start(urls: [String], complete:@escaping ([UIImage]) -> Void) {
        var images = [UIImage?](repeating:nil, count: urls.count)
        urls.enumerated().forEach { (index, urlString) in
            let operation = BlockOperation(block: {
                if let url = HotelImageType.buildImageURLByScene7constant(urlString: urlString, imageType: .primary) {
                    SDWebImageManager.shared().loadImage(with: url, options: SDWebImageOptions.retryFailed, progress: nil) { (image: UIImage?, data: Data?, error: Error?, type: SDImageCacheType, finished: Bool, url: URL?) in
                        if error == nil, let image = image {
                            images[index] = image
                        }
                        if PrimaryImageDownloader.queue.operationCount == 0 {
                            complete(images.flatMap{$0})
                        }
                    }
                }
            })
            PrimaryImageDownloader.queue.addOperation(operation)
        }
    }
    
    class func cancelAllDownloadOperations() {
        PrimaryImageDownloader.queue.cancelAllOperations()
    }
}
