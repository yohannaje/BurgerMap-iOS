//
//  ContainerViewController.swift
//  HamburgerTest
//
//  Created by Nico Ameghino on 10/27/15.
//  Copyright © 2015 Nico Ameghino. All rights reserved.
//

import UIKit

protocol ContainerViewControllerDelegate {
}

class ContainerViewController: UIViewController {
    
    static let sharedInstance = ContainerViewController()
    
    let menuWidth = CGFloat(260)
    var delegate: ContainerViewControllerDelegate?
    
    lazy var centerViewController: UIViewController = {
        return UIStoryboard.contentViewController
    }()
    
    var leftViewController: UIViewController! = {
        return UIStoryboard.menuViewController
    }()
    
    var rightViewController: UIViewController!
    
    var menuWidthConstraint: NSLayoutConstraint!
    var menuLeadingConstraint: NSLayoutConstraint!
    
    var menuIsOpen: Bool {
        return menuWidthConstraint.constant != 0 && menuLeadingConstraint.constant == 0
    }
    
    lazy var toggleMenuBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "Menu", style: .Plain, target: self, action: "toggleMenu:")
        return item
    }()
    
    lazy var openMenuSwipeGestureRecognizer: UIGestureRecognizer = {
        let gr = UISwipeGestureRecognizer(target: self, action: "openMenu:")
        gr.direction = .Right
        return gr
    }()

    lazy var closeMenuSwipeGestureRecognizer: UIGestureRecognizer = {
        let gr = UISwipeGestureRecognizer(target: self, action: "closeMenu:")
        gr.direction = .Left
        return gr
    }()
    
    lazy var closeMenuTapGestureRecognizer: UIGestureRecognizer = {
        let gr = UITapGestureRecognizer(target: self, action: "closeMenu:")
        return gr
    }()

    func animateMenu() {
        UIView.animateWithDuration(0.3,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.5,
            options: [],
            animations: view.layoutIfNeeded,
            completion: nil
        )
    }
    
    func openMenu(sender: AnyObject) {
        if menuIsOpen { return }
        menuLeadingConstraint.constant = 0
        centerViewController.view.addGestureRecognizer(closeMenuTapGestureRecognizer)
        leftViewController.view.layer.shadowOpacity = 0.8
        leftViewController.view.layer.shadowOffset = CGSize(width: 1, height: 1)
        animateMenu()
    }
    
    func closeMenu(sender: AnyObject) {
        if !menuIsOpen { return }
        menuLeadingConstraint.constant = -menuWidth
        centerViewController.view.removeGestureRecognizer(closeMenuTapGestureRecognizer)
        leftViewController.view.layer.shadowOpacity = 0
        animateMenu()
    }
    
    func toggleMenu(sender: AnyObject) {
        if menuIsOpen {
            closeMenu(sender)
        } else {
            openMenu(sender)
        }
    }
    
    private func createConstraintsForMenu() {
        menuWidthConstraint = NSLayoutConstraint(
            item: leftViewController.view,
            attribute: .Width,
            relatedBy: .Equal,
            toItem: nil,
            attribute: .NotAnAttribute,
            multiplier: 1.0,
            constant: menuWidth
        )
        
        menuLeadingConstraint = NSLayoutConstraint(
            item: leftViewController.view,
            attribute: .Leading,
            relatedBy: .Equal,
            toItem: centerViewController.view,
            attribute: .Leading,
            multiplier: 1.0,
            constant: 0
        )
        
        let topGuide: AnyObject = {
            return (centerViewController as! UINavigationController).navigationBar
        }()
        
        leftViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            menuWidthConstraint,
            menuLeadingConstraint,
            NSLayoutConstraint(item: leftViewController.view, attribute: .Bottom, relatedBy: .Equal, toItem: centerViewController.view, attribute: .Bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: leftViewController.view, attribute: .Top, relatedBy: .Equal, toItem: topGuide, attribute: .Bottom, multiplier: 1.0, constant: 0),
        ])
        
        view.layoutIfNeeded()
    }
    
    private func createConstraintsForContent() {
        centerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            NSLayoutConstraint(item: centerViewController.view, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: centerViewController.view, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: centerViewController.view, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: centerViewController.view, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1.0, constant: 0),
            ])
        
        view.layoutIfNeeded()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        [centerViewController, leftViewController].forEach {
            vc in
            vc.view.translatesAutoresizingMaskIntoConstraints = false
            addChildViewController(vc)
            vc.willMoveToParentViewController(self)
            view.addSubview(vc.view)
        }
        
        leftViewController.view.addGestureRecognizer(closeMenuSwipeGestureRecognizer)
        
        createConstraintsForMenu()
        createConstraintsForContent()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}


extension UIStoryboard {
    class var appStoryboard: UIStoryboard { return UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()) }
    class var contentViewController: UIViewController { return appStoryboard.instantiateViewControllerWithIdentifier("ContentViewController") }
    class var menuViewController: UIViewController { return appStoryboard.instantiateViewControllerWithIdentifier("MenuViewController") }
}