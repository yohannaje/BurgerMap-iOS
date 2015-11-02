//
//  Filter.swift
//  BurgerMap
//
//  Created by Nicolas Ameghino on 11/1/15.
//
//

import Foundation
import UIKit

protocol MenuItem {
    var title: String { get }
    var iconName: String { get }
}

extension MenuItem {
    var icon: UIImage? {
        get {
            return UIImage(named: self.iconName)?.imageWithRenderingMode(.AlwaysTemplate)
        }
    }
}

struct MenuShortcut: MenuItem {
    let action: String
    let title: String
    let iconName: String
}

struct MenuFilter: MenuItem {
    let value: String
    let title: String
    let iconName: String
    let cellType: String?
}