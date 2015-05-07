//
//  CircularPageViewController.swift
//  CircularPageViewController
//
//  Copyright (c) 2015 John Rommel Estropia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import UIKit


// MARK: - CircularPageViewControllerDelegate

public protocol CircularPageViewControllerDelegate: class {
    
    func pageViewController(controller: CircularPageViewController, didChangeCurrentIndex currentIndex: Int?, viewController: UIViewController?)
}



// MARK: - CircularPageViewController

public class CircularPageViewController: UIViewController {
    
    // MARK: Public
    
    public weak var delegate: CircularPageViewControllerDelegate?
    
    public var viewControllers: [UIViewController] = [] {
        
        didSet {
            
            let viewControllers = self.viewControllers
            if viewControllers == oldValue {
                
                return
            }
            
            self.repeatedViewControllers = (viewControllers.count < Constants.minimumNumberOfPagesForCircularPaging
                ? viewControllers
                : viewControllers + viewControllers + viewControllers)
            
            if let previousIndex = self.currentIndex where previousIndex < oldValue.count {
                
                self.currentViewController = oldValue[previousIndex]
            }
            else {
                
                self.currentIndex = nil
            }
            
            if self.isViewLoaded() {
                
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }
        }
    }
    
    public var currentIndex: Int? {
        
        get {
            
            return self.normalizedIndexForIndex(self.actualIndex)
        }
        set {
            
            self.setActualIndex(self.actualIndexForIndex(newValue), updateOffset: true)
        }
    }
    
    public var currentViewController: UIViewController? {
        
        get {
            
            if let currentIndex = self.currentIndex where currentIndex < self.viewControllers.count {
                
                return self.viewControllers[currentIndex]
            }
            return nil
        }
        set {
            
            if let newValue = newValue {
                
                self.currentIndex = find(self.viewControllers, newValue)
            }
            else {
                
                self.currentIndex = nil
            }
        }
    }
    
    public convenience init(viewControllers: [UIViewController]) {
        
        self.init(nibName: nil, bundle: nil)
        
        self.viewControllers = viewControllers
        self.currentIndex = nil
        self.layoutViewControllers()
    }
    
    
    // MARK: UIViewController
    
    public override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let view = self.view
        let pagingScrollView = UIScrollView(frame: view.bounds)
        pagingScrollView.scrollsToTop = false
        pagingScrollView.pagingEnabled = true
        pagingScrollView.alwaysBounceVertical = false
        pagingScrollView.alwaysBounceHorizontal = true
        pagingScrollView.showsHorizontalScrollIndicator = false
        pagingScrollView.backgroundColor = UIColor.clearColor()
        pagingScrollView.decelerationRate = UIScrollViewDecelerationRateFast
        pagingScrollView.multipleTouchEnabled = false
        pagingScrollView.exclusiveTouch = true
        pagingScrollView.delegate = self
        
        view.addSubview(pagingScrollView)
        self.pagingScrollView = pagingScrollView
        
        self.layoutViewControllers()
    }
    
    public override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        self.layoutViewControllers()
        
        if let pagingScrollView = self.pagingScrollView {
            
            let boundsWidth = self.view.bounds.width
            let numberOfViewControllers = self.viewControllers.count
            
            pagingScrollView.contentSize = CGSize(
                width: (numberOfViewControllers < Constants.minimumNumberOfPagesForCircularPaging
                    ? max(boundsWidth, boundsWidth * CGFloat(numberOfViewControllers))
                    : CGFloat(numberOfViewControllers * 3) * boundsWidth
                ),
                height: 1.0
            )
            pagingScrollView.contentOffset = CGPoint(
                x: CGFloat(self.actualIndexForIndex(self.currentIndex)) * self.view.bounds.width,
                y: pagingScrollView.contentOffset.y
            )
            pagingScrollView.bounces = numberOfViewControllers < Constants.minimumNumberOfPagesForCircularPaging
        }
    }
    
    
    // MARK: Private
    
    private struct Constants {
        
        static let numberOfPagesToPreload = 1
        static let minimumNumberOfPagesForCircularPaging = 3
    }
    
    private var actualIndex: Int?
    private var repeatedViewControllers: [UIViewController] = []
    private weak var pagingScrollView: UIScrollView? = nil
    
    private func layoutViewControllers() {
        
        if let pagingScrollView = self.pagingScrollView {
            
            let view = self.view
            let viewBounds = view.bounds
            let viewFrame = view.frame
            let scrollViewBounds = pagingScrollView.bounds
            let scrollViewInsets = pagingScrollView.contentInset
            let currentIndex = self.currentIndex
            let actualIndex = self.actualIndex
            
            let setViewControllerFrame = { (viewController: UIViewController, index: Int) -> Void in
                
                let pageView = viewController.view
                let expectedFrame = CGRect(
                    x: round(CGFloat(index) * viewBounds.width),
                    y: 0.0,
                    width: viewBounds.width,
                    height: scrollViewBounds.height - scrollViewInsets.top - scrollViewInsets.bottom
                )
                if pageView.frame != expectedFrame {
                    
                    pageView.frame = expectedFrame
                }
                pageView.userInteractionEnabled = currentIndex == self.normalizedIndexForIndex(index)
            }
            let removeViewController = { (viewController: UIViewController) -> Void in
                
                if viewController.parentViewController != self {
                    
                    return
                }
                
                viewController.willMoveToParentViewController(nil)
                if viewController.isViewLoaded() {
                    
                    viewController.view.removeFromSuperview()
                    viewController.view.userInteractionEnabled = true
                }
                viewController.removeFromParentViewController()
            }
            
            let repeatedViewControllers = self.repeatedViewControllers
            for childViewController in [UIViewController](self.childViewControllers as! [UIViewController]) {
                
                if find(repeatedViewControllers, childViewController) == nil {
                    
                    removeViewController(childViewController)
                }
            }
            
            self.enumerateViewControllersForCenterIndex(actualIndex) { (index, viewController) -> Void in
                
                if self.isIndex(index, withinPagingWindowForIndex: actualIndex) {
                    
                    if viewController.parentViewController == self {
                        
                        setViewControllerFrame(viewController, index)
                        viewController.didMoveToParentViewController(self)
                    }
                    else {
                        
                        self.addChildViewController(viewController)
                        setViewControllerFrame(viewController, index)
                        pagingScrollView.addSubview(viewController.view)
                        viewController.didMoveToParentViewController(self)
                    }
                }
                else {
                    
                    removeViewController(viewController)
                }
            }
        }
    }
    
    private func isIndex(index: Int, withinPagingWindowForIndex centerIndex: Int?) -> Bool {
        
        if let centerIndex = centerIndex {
            
            switch index {
                
            case Int.min ..< 0, self.repeatedViewControllers.count ..< Int.max:
                return false
                
            case (centerIndex - Constants.numberOfPagesToPreload) ... (centerIndex + Constants.numberOfPagesToPreload):
                return true
                
            default:
                return false
            }
        }
        return false
    }
    
    private func enumerateViewControllersForCenterIndex(centerIndex: Int?, closure: (actualIndex: Int, viewController: UIViewController) -> Void) {
        
        if let centerIndex = centerIndex {
            
            var reportedViewControllers = Set<UIViewController>()
            let repeatedViewControllers = self.repeatedViewControllers
            let numberOfViewControllers = repeatedViewControllers.count
            
            let executeClosureIfNeeded = { (actualIndex: Int) -> Void in
                
                if actualIndex >= 0 && actualIndex < numberOfViewControllers {
                    
                    let viewController = repeatedViewControllers[actualIndex]
                    if reportedViewControllers.contains(viewController) {
                        
                        return
                    }
                    
                    closure(actualIndex: actualIndex, viewController: viewController)
                    reportedViewControllers.insert(viewController)
                }
            }
            
            executeClosureIfNeeded(centerIndex)
            for var index = 1; index <= Constants.numberOfPagesToPreload; ++index {
                
                executeClosureIfNeeded(centerIndex + index)
                executeClosureIfNeeded(centerIndex - index)
            }
            
            for var index = 0; index < (centerIndex - Constants.numberOfPagesToPreload) && index < numberOfViewControllers; ++index {
                
                executeClosureIfNeeded(index)
            }
            for var index = (centerIndex + Constants.numberOfPagesToPreload); index < numberOfViewControllers; ++index {
                
                executeClosureIfNeeded(index)
            }
        }
        else {
            
            for (actualIndex, viewController) in enumerate(self.repeatedViewControllers) {
                
                closure(actualIndex: actualIndex, viewController: viewController)
            }
        }
    }
    
    private func didChangeCurrentIndex() {
        
        let currentIndex = self.currentIndex
        self.delegate?.pageViewController(
            self,
            didChangeCurrentIndex: currentIndex,
            viewController: (currentIndex == nil ? nil : self.viewControllers[currentIndex!])
        )
    }
    
    private func setActualIndex(newValue: Int?, updateOffset: Bool) {
        
        let previousIndex = self.actualIndex
        let previousViewController = self.currentViewController
        if self.repeatedViewControllers.count > 0 {
            
            if let newValue = newValue where newValue >= 0 && newValue < self.repeatedViewControllers.count {
                
                self.actualIndex = newValue
            }
            else {
                
                self.actualIndex = self.actualIndexForIndex(0)
            }
        }
        else {
            
            self.actualIndex = nil
        }
        
        self.layoutViewControllers()
        
        if let pagingScrollView = self.pagingScrollView where updateOffset {
            
            pagingScrollView.delegate = nil
            pagingScrollView.contentOffset = CGPoint(
                x: CGFloat(self.actualIndex ?? 0) * self.view.bounds.width,
                y: pagingScrollView.contentOffset.y
            )
            pagingScrollView.delegate = self
        }
        
        if self.normalizedIndexForIndex(previousIndex) != self.currentIndex || self.currentViewController != previousViewController {
            
            self.didChangeCurrentIndex()
        }
    }
    
    private func normalizedIndexForIndex(index: Int?) -> Int? {
        
        let numberOfViewControllers = self.viewControllers.count
        if let actualIndex = index where numberOfViewControllers > 0 {
            
            return actualIndex % numberOfViewControllers
        }
        return nil
    }
    
    private func actualIndexForIndex(index: Int?) -> Int {
        
        let numberOfViewControllers = self.viewControllers.count
        if numberOfViewControllers > 0 {
            
            let normalizedIndex = (index ?? 0) % numberOfViewControllers
            return (numberOfViewControllers < Constants.minimumNumberOfPagesForCircularPaging
                ? normalizedIndex
                : normalizedIndex + numberOfViewControllers
            )
        }
        return 0
    }
}


// MARK: - CircularPageViewController: UIScrollViewDelegate

extension CircularPageViewController: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        
        let pageWidth = self.view.frame.width
        let currentIndex = Int(floor((scrollView.contentOffset.x - (pageWidth / 2.0)) / pageWidth) + 1.0)
        self.setActualIndex(currentIndex, updateOffset: false)
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let pageWidth = self.view.frame.width
        let currentIndex = Int(floor((scrollView.contentOffset.x - (pageWidth / 2.0)) / pageWidth) + 1.0)
        self.setActualIndex(self.actualIndexForIndex(currentIndex), updateOffset: true)
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        
        let pageWidth = self.view.frame.width
        let currentIndex = Int(floor((scrollView.contentOffset.x - (pageWidth / 2.0)) / pageWidth) + 1.0)
        self.setActualIndex(self.actualIndexForIndex(currentIndex), updateOffset: true)
    }
}
