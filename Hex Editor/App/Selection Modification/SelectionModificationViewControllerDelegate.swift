//
//  SelectionModificationViewControllerDelegate.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2020-02-22.
//  Copyright © 2020 Philip Kronawetter. All rights reserved.
//

protocol SelectionModificationViewControllerDelegate: AnyObject {
	func selectionModificationViewController(_ selectionModificationViewController: SelectionModificationViewController, didChange selection: Range<Int>)
}
