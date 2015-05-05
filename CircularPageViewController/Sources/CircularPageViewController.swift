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
            
            if self.viewControllers == oldValue {
                
                return
            }
            
            self.currentIndex = nil
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    public var currentIndex: Int? {
        
        get {
            
            return self._currentIndex
        }
        set {
            
            self.setCurrentIndex(newValue, updateOffset: true)
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
        pagingScrollView.showsHorizontalScrollIndicator = false
        pagingScrollView.delegate = self
        
        view.addSubview(pagingScrollView)
        self.pagingScrollView = pagingScrollView
        
        self.layoutViewControllers()
    }
    
    public override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        self.layoutViewControllers()
        
        if let pagingScrollView = self.pagingScrollView {
            
            let viewBounds = self.view.bounds
            let boundsWidth = viewBounds.width
            let numberOfViewControllers = self.viewControllers.count
            pagingScrollView.contentSize = CGSize(
                width: max(boundsWidth, CGFloat(numberOfViewControllers) * boundsWidth),
                height: 1.0
            )
            pagingScrollView.contentOffset = CGPoint(
                x: CGFloat(self.currentIndex ?? 0) * boundsWidth,
                y: 0.0
            )
            pagingScrollView.alwaysBounceHorizontal = numberOfViewControllers <= 1
        }
    }
    
    
    // MARK: Private
    
    private var _currentIndex: Int?
    private weak var pagingScrollView: UIScrollView? = nil
    
    private func layoutViewControllers() {
        
        if let pagingScrollView = self.pagingScrollView {
            
            let view = self.view
            let viewBounds = view.bounds
            let viewFrame = view.frame
            let scrollViewBounds = pagingScrollView.bounds
            let scrollViewInsets = pagingScrollView.contentInset
            let currentIndex = self.currentIndex
            
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
                pageView.userInteractionEnabled = currentIndex == index
            }
            let removeViewController = { (viewController: UIViewController) -> Void in
                
                viewController.willMoveToParentViewController(nil)
                viewController.view.removeFromSuperview()
                viewController.removeFromParentViewController()
                viewController.view.userInteractionEnabled = true
            }
            
            let viewControllers = self.viewControllers
            for childViewController in [UIViewController](self.childViewControllers as! [UIViewController]) {
                
                if let indexOfChildViewController = find(viewControllers, childViewController)
                    where self.isIndexWithinPagingWindow(indexOfChildViewController) {
                        
                        setViewControllerFrame(childViewController, indexOfChildViewController)
                }
                else {
                    
                    removeViewController(childViewController)
                }
            }
            
            self.enumerateViewControllersForCenterIndex(self.currentIndex) { (index, viewController) -> Void in
                
                if let indexOfChildViewController = find(self.childViewControllers as! [UIViewController], viewController) {
                    
                    return
                }
                
                if self.isIndexWithinPagingWindow(index) {
                    
                    self.addChildViewController(viewController)
                    setViewControllerFrame(viewController, index)
                    pagingScrollView.addSubview(viewController.view)
                    viewController.didMoveToParentViewController(self)
                }
                else {
                    
                    removeViewController(viewController)
                }
            }
        }
    }
    
    private struct Constants {
        
        static let numberOfPagesToPreload = 1
    }
    
    private func isIndexWithinPagingWindow(index: Int) -> Bool {
        
        if let currentIndex = self.currentIndex {
            
            switch index {
                
            case Int.min ..< 0, self.viewControllers.count ..< Int.max:
                return false
                
            case (currentIndex - Constants.numberOfPagesToPreload) ... (currentIndex + Constants.numberOfPagesToPreload):
                return true
                
            default:
                return false
            }
        }
        return false
    }
    
    private func enumerateViewControllersForCenterIndex(centerIndex: Int?, closure: (index: Int, viewController: UIViewController) -> Void) {
        
        if let centerIndex = centerIndex {
            
            let viewControllers = self.viewControllers
            let numberOfViewControllers = viewControllers.count
            
            let executeClosureIfNeeded = { (index: Int) -> Void in
                
                if index >= 0 && index < numberOfViewControllers {
                    
                    closure(index: index, viewController: viewControllers[index])
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
            
            for (index, viewController) in enumerate(self.viewControllers) {
                
                closure(index: index, viewController: viewController)
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
    
    private func setCurrentIndex(newValue: Int?, updateOffset: Bool) {
        
        let previousIndex = self._currentIndex
        let previousViewController = self.currentViewController
        if let newValue = newValue {
            
            let numberOfPages = self.viewControllers.count
            if numberOfPages > 0 {
                
                if newValue < 0 {
                    
                    self._currentIndex = 0
                }
                else if newValue >= numberOfPages {
                    
                    self._currentIndex = numberOfPages - 1
                }
                else {
                    
                    self._currentIndex = newValue
                }
            }
            else {
                
                self._currentIndex = nil
            }
        }
        else if self.viewControllers.count > 0 {
            
            self._currentIndex = previousIndex ?? 0
        }
        else {
            
            self._currentIndex = newValue
        }
        
        self.layoutViewControllers()
        
        let currentIndex = self._currentIndex
        if let pagingScrollView = self.pagingScrollView where updateOffset {
            
            pagingScrollView.delegate = nil
            pagingScrollView.contentOffset = CGPoint(
                x: CGFloat(currentIndex ?? 0) * self.view.bounds.width,
                y: pagingScrollView.contentOffset.y
            )
            pagingScrollView.delegate = self
        }
        
        if previousIndex != currentIndex || self.currentViewController != previousViewController {
            
            self.didChangeCurrentIndex()
            println("currentIndex: \(self._currentIndex)")
        }
    }
}


// MARK: - CircularPageViewController: UIScrollViewDelegate

extension CircularPageViewController: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        
        let pageWidth = self.view.frame.width
        let currentIndex = Int(floor((scrollView.contentOffset.x - (pageWidth / 2.0)) / pageWidth) + 1.0)
        self.setCurrentIndex(currentIndex, updateOffset: false)
    }
}
