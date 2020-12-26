//
//  KeyboardObserver.swift
//  cvsotracker
//
//  Created by Ihar Tsimafeichyk on 2/17/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import Combine
import SwiftUI

/**
 For the future, consider usage of following code:

    let keyboardWillOpen = NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillShowNotification)
        .map {$0.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect}
        .map {$0.height}
    let keyboardWillHide =  NotificationCenter.default
        .publisher(for: UIResponder.keyboardWillHideNotification)
        .map { _ in CGFloat(0)}
    _ = Publishers.Merge(keyboardWillOpen, keyboardWillHide)
        .subscribe(on: RunLoop.main)
        .assign(to: \UIScrollView.contentInset.bottom, on: scrollView)
 */

final class KeyboardObserver: ObservableObject {
    @Published var isVisible = false
    var keyboardWillShowPublisher: AnyCancellable? = nil
    var keyboardWillHidePublisher: AnyCancellable? = nil

    init(center: NotificationCenter = .default) {
        keyboardWillShowPublisher = center.publisher(for: UIResponder.keyboardWillShowNotification)
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink {[weak self] _ in
                self?.isVisible = true
        }

        keyboardWillHidePublisher = center.publisher(for: UIResponder.keyboardWillHideNotification)
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink {[weak self] _ in
                self?.isVisible = false
        }
    }
}
