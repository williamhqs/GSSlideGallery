//
//  PrimaryImageCell.swift
//  GSSlideGallery
//
//  Created by William Hu on 8/7/17.
//  Copyright © 2017 William Hu. All rights reserved.
//
import UIKit

class GSSlideGallery: UIView {
    
    private let noImageViewHeight = 44.0
    private static let ratio: CGFloat = 9 / 16
    private static let primaryImageCellIdentifier = "primaryImageCellIdentifier"
    
    @IBOutlet weak var photoCountView: UIView!
    @IBOutlet weak var photoCount: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var centerImageView: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    private var primaryImages = [UIImage]()
    private var currentPage: Int = 0
    private var isTimerSuspend: Bool = false
    
    private var item: PrimaryImageCellItem? {
        didSet {
            self.indicator.startAnimating()
            if let item = item {
                setupInitialImageViewSize()
                photoCountView.backgroundColor = item.photoCountColor
                photoCount.text = String(item.photoCount)
                pageControl.numberOfPages =  item.primaryURLStrings.count
                pageControl.isHidden = item.primaryURLStrings.count == 1 ? true : false
                PrimaryImageDownloader.start(urls: item.primaryURLStrings, complete: { (images: [UIImage]) in
                    self.indicator.stopAnimating()
                    self.photoCountView.isHidden = false
                    if images.count > 0 {
                        self.primaryImages = images
                        self.centerImageView.image = images[0]
                        self.startAnimation()
                    }
                })
            } else {
                updateWhenNoPhoto()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupInitialImageViewSize()
        addSwipeGesture(for: centerImageView)
        addSwipeGesture(for: rightImageView)
        addSwipeGesture(for: leftImageView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        item?.timer?.cancel()
        item?.timer = nil
    }
    
    func configure(item: PrimaryImageCellItem) {
        self.item = item
        if (item.primaryURLStrings.count == 0) {
            updateWhenNoPhoto()
        }
    }
    
    private func updateWhenNoPhoto() {
        centerImageView.image = #imageLiteral(resourceName: "noImage")
        centerImageView.frame.size = CGSize(width: noImageViewHeight, height: noImageViewHeight)
        centerImageView.center = contentView.center
        photoCountView.isHidden = true
        indicator.stopAnimating()
    }
    
    private func setupInitialImageViewSize() {
        centerImageView.translatesAutoresizingMaskIntoConstraints = true
        rightImageView.translatesAutoresizingMaskIntoConstraints = true
        leftImageView.translatesAutoresizingMaskIntoConstraints = true
        centerImageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: PrimaryImageCell.heightForCell())
        rightImageView.frame = CGRect(x: UIScreen.main.bounds.width, y: 0, width: UIScreen.main.bounds.width, height: PrimaryImageCell.heightForCell())
        leftImageView.frame = CGRect(x: -UIScreen.main.bounds.width, y: 0, width: UIScreen.main.bounds.width, height: PrimaryImageCell.heightForCell())
        
    }
    
    private func startAnimation() {
        if self.primaryImages.count > 1 {
            rightImageView.image = primaryImages[1]
            item?.timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
            item?.timer?.setEventHandler(handler: {
                DispatchQueue.main.async {
                    self.play()
                }
            })
            
            item?.timer?.scheduleRepeating(deadline: .now() + 0.5, interval: .seconds(4))
            item?.timer?.resume()
        }
    }
    
    @objc private func changeImage(gesture: UISwipeGestureRecognizer) {
        
        if primaryImages.count <= 1 {
            return
        }
        
        if gesture.state == .ended {
            suspendTimer()
        }
        
        play(direction: gesture.direction)
        
    }
    
    private func play(direction: UISwipeGestureRecognizerDirection = .left) {
        direction == .left ? next() : previous()
        let imageView = direction == .left ?  rightImageView : leftImageView
        contentView.bringSubview(toFront: imageView!)
        bringPageControlFront()
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.showCurrent(imageView: imageView!)
        }, completion: { finished in
            if finished {
                self.prepare(direction: direction)
                self.resumeTimer()
            }
        })
    }

    private func resumeTimer() {
        if isTimerSuspend {
            item?.timer?.resume()
        }
        isTimerSuspend = false
    }
    
    private func suspendTimer() {
        item?.timer?.suspend()
        isTimerSuspend = true
    }
    
    private func bringPageControlFront() {
        contentView.bringSubview(toFront: pageControl)
        contentView.bringSubview(toFront: photoCountView)
    }
    
    private func showCurrent(imageView: UIImageView) {
        updatePageConrol()
        imageView.image = primaryImages[currentPage]
        updateImageViewOriginX(imageView: imageView, x: 0)
    }
    
    private func prepare(direction: UISwipeGestureRecognizerDirection = .left) {
        centerImageView.image = primaryImages[currentPage]
        contentView.bringSubview(toFront: centerImageView)
        bringPageControlFront()
        let x = (direction == .left ? UIScreen.main.bounds.width : -UIScreen.main.bounds.width)
        let imageView = direction == .left ? rightImageView : leftImageView
        updateImageViewOriginX(imageView: imageView!, x: x)
    }
    
    private func updateImageViewOriginX(imageView: UIImageView, x: CGFloat) {
        var frame = imageView.frame
        frame.origin.x = x
        imageView.frame = frame
    }
    
    private func updatePageConrol() {
        pageControl.currentPage = currentPage
    }
    
    private func next() {
        if currentPage < primaryImages.count - 1 {
            currentPage += 1
        } else {
            currentPage = 0
        }
    }
    
    private func previous() {
        if currentPage > 0  {
            currentPage -= 1
        } else {
            currentPage = primaryImages.count - 1
        }
    }
    
    private func addSwipeGesture(for imageView: UIImageView) {
        [UISwipeGestureRecognizerDirection.left, .right].forEach { direction in
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(changeImage))
            gesture.direction = direction
            imageView.addGestureRecognizer(gesture)
        }
    }
    

}
