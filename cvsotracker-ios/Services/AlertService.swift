//
//  AlertService.swift
//  Services
//
//  Created by Ihar Tsimafeichyk on 2/10/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import Foundation
import UIKit

public protocol AlertServiceHolder {
    var alertService: AlertService { get }
}

public protocol AlertService {
    func showMessage(_ message: String)
    /// a flavor of showMessage when presenter should be not the top view controller but something else (e.g. topViewController is being dismissed)
    func showMessage(_ message: String, presenter: UIViewController)

    func showMessage(_ message: String?, title: String?)
    /// a flavor of showMessage when presenter should be not the top view controller but something else (e.g. topViewController is being dismissed)
    func showMessage(_ message: String?, title: String?, presenter: UIViewController)

    func showMessage(_ message: String,
                     actions: [AlertAction],
                     preferredStyle: UIAlertController.Style)

    func showMessage(_ message: String?,
                     title: String?,
                     actions: [AlertAction],
                     preferredStyle: UIAlertController.Style)

    /// a flavor of showMessage when presenter should be not the top view controller but something else (e.g. topViewController is being dismissed)
    func showMessage(_ message: String?,
                     title: String?,
                     actions: [AlertAction],
                     preferredStyle: UIAlertController.Style,
                     presenter: UIViewController)

    func showErrorMessage(_ message: String)
    func showErrorMessage(_ message: String, presenter: UIViewController)

    func showErrorMessage(_ message: String, onDismiss: @escaping (() -> Void))

    func showErrorMessage(_ message: String,
                          actions: [AlertAction],
                          preferredStyle: UIAlertController.Style)

    func showError(_ error: Swift.Error?)
}

public struct AlertAction: Equatable {
    public static func == (lhs: AlertAction, rhs: AlertAction) -> Bool {
        return lhs.title == rhs.title
    }

    let title: String
    let action: () -> Void
    let style: UIAlertAction.Style

    public init(title: String,
                action: @escaping (() -> Void),
                style: UIAlertAction.Style = .default) {
        self.title = title
        self.action = action
        self.style = style
    }

    public init(title: String,
                action: @escaping (() -> Void)) {
        self.title = title
        self.action = action
        style = .default
    }

    public static var close: AlertAction {
        return AlertAction(title: "Close",
                           action: {},
                           style: .cancel)
    }

    public static var cancel: AlertAction {
        return AlertAction(title: "Cancel",
                           action: {},
                           style: .cancel)
    }
}

public final class AlertServiceImplementation: AlertService {
    public static let errorTitle = "Error"
    public static let okTitle: String = "OK"

    public struct Dependencies {
        let mailService: MailService
        let logger: Logger

        public init(mailService: MailService, logger: Logger) {
            self.mailService = mailService
            self.logger = logger
        }
    }

    public let dependencies: Dependencies

    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    public func showMessage(_ message: String) {
        showMessage(message, title: nil, actions: nil, preferredStyle: .alert, presenter: UIApplication.topViewController, onDismiss: nil)
    }

    public func showMessage(_ message: String, presenter: UIViewController) {
        showMessage(message, title: nil, actions: nil, preferredStyle: .alert, presenter: presenter, onDismiss: nil)
    }

    public func showMessage(_ message: String?, title: String?) {
        showMessage(message, title: title, actions: nil, preferredStyle: .alert, presenter: UIApplication.topViewController, onDismiss: nil)
    }

    public func showMessage(_ message: String?, title: String?, presenter: UIViewController) {
        showMessage(message, title: title, actions: nil, preferredStyle: .alert, presenter: presenter, onDismiss: nil)
    }

    public func showMessage(_ message: String?, title: String?, actions: [AlertAction], preferredStyle: UIAlertController.Style) {
        showMessage(message, title: title, actions: actions, preferredStyle: preferredStyle, presenter: UIApplication.topViewController, onDismiss: nil)
    }

    public func showMessage(_ message: String?, title: String?, actions: [AlertAction], preferredStyle: UIAlertController.Style, presenter: UIViewController) {
        showMessage(message, title: title, actions: actions, preferredStyle: preferredStyle, presenter: presenter, onDismiss: nil)
    }

    public func showMessage(_ message: String, actions: [AlertAction], preferredStyle: UIAlertController.Style) {
        showMessage(message, title: nil, actions: actions, preferredStyle: preferredStyle, presenter: UIApplication.topViewController, onDismiss: nil)
    }

    /// ERRORS
    public func showErrorMessage(_ message: String) {
        DispatchQueue.main.async {
            self.showMessage(message, title: AlertServiceImplementation.errorTitle, actions: self.defaultErrorAlertActions(), preferredStyle: .alert, onDismiss: nil)
        }
    }

    public func showErrorMessage(_ message: String, presenter: UIViewController) {
        DispatchQueue.main.async {
            self.showMessage(message, title: AlertServiceImplementation.errorTitle, actions: self.defaultErrorAlertActions(), preferredStyle: .alert, presenter: presenter)
        }
    }

    public func showErrorMessage(_ message: String, onDismiss: @escaping (() -> Void)) {
        DispatchQueue.main.async {
            self.showMessage(message, title: AlertServiceImplementation.errorTitle, actions: self.defaultErrorAlertActions(), preferredStyle: .alert, onDismiss: onDismiss)
        }
    }

    public func showErrorMessage(_ message: String, actions: [AlertAction], preferredStyle _: UIAlertController.Style) {
        DispatchQueue.main.async {
            self.showMessage(message, title: AlertServiceImplementation.errorTitle, actions: actions + self.defaultErrorAlertActions(), preferredStyle: .alert, onDismiss: nil)
        }
    }

    public func showError(_ error: Swift.Error?) {
        DispatchQueue.main.async {
            let message = error?.localizedDescription ?? "Unknown error"
            self.showErrorMessage(message)
        }
    }
}

// MARK: - Private

private extension AlertServiceImplementation {
    func showMessage(_ message: String?,
                     title: String? = nil,
                     actions: [AlertAction]? = nil,
                     preferredStyle: UIAlertController.Style = .actionSheet,
                     presenter: UIViewController? = UIApplication.topViewController,
                     onDismiss: (() -> Void)? = nil) {
        if let presenter = presenter {
            if presenter is UIAlertController {
                // we do not support multiple alert presentation
                // build your queue if needed
                dependencies.logger.error("[UI] multiple UIAlertController presentation")
                return
            }

            let alertController = AlertServiceImplementation.makeAlertControllerWith(message,
                                                                                     title: title,
                                                                                     actions: actions,
                                                                                     preferredStyle: preferredStyle,
                                                                                     onDismiss: onDismiss)
            alertController.applyStatusBarStyle(presenter.preferredStatusBarStyle)
            presenter.present(alertController, animated: true, completion: nil)

        } else {
            dependencies.logger.error("[UI] AlertService have no presenter")

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                self.showMessage(message,
                                 title: title,
                                 actions: actions,
                                 preferredStyle: preferredStyle,
                                 presenter: UIApplication.topViewController,
                                 onDismiss: onDismiss)
            }
        }
    }

    static func makeAlertControllerWith(_ message: String?,
                                        title: String?,
                                        actions: [AlertAction]?,
                                        preferredStyle: UIAlertController.Style = .actionSheet,
                                        onDismiss: (() -> Void)? = nil) -> AlertController {
        let alert = AlertController(title: title, message: message, preferredStyle: preferredStyle)
        alert.loadViewIfNeeded()
        alert.modalPresentationStyle = .overFullScreen

        if let actArray = actions { // map actions
            actArray.forEach { action in
                let alertAction = UIAlertAction(title: action.title,
                                                style: UIAlertAction.Style(rawValue: action.style.rawValue) ?? .default,
                                                handler: { (_) -> Void in
                                                    action.action()
                                                    alert.dismiss(animated: true, completion: onDismiss)
                })
                alert.addAction(alertAction)
            }
        } else { // add ok button if there is no actions
            let okAction = UIAlertAction(title: okTitle, style: .default) { (_) -> Void in
                alert.dismiss(animated: true, completion: onDismiss)
            }
            alert.addAction(okAction)
        }
        return alert
    }

    private func defaultErrorAlertActions() -> [AlertAction] {
        return [AlertAction(title: "Contact us", action: {
            self.dependencies.mailService.showContactSupportMailComposer()
        }, style: .default), AlertAction.close]
    }
}

///this VC used to avoid black/white status bar style changing when presentin alerts
private class AlertController: UIAlertController {
    private var statusBarStyle: UIStatusBarStyle?

    func applyStatusBarStyle(_ statusBarStyle: UIStatusBarStyle) {
        self.statusBarStyle = statusBarStyle
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setNeedsStatusBarAppearanceUpdate()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle ?? .lightContent
    }
}

// MARK: - Protocol

public protocol SpinnerProtocol: AnyObject {
    func startAnimating()
    func stopAnimating()

    var isAnimating: Bool { get }
}

extension UIActivityIndicatorView: SpinnerProtocol {}

// MARK: - Top view controller

internal extension UIApplication {
    static var topViewController: UIViewController? {
        guard let rootController = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }

        return UIApplication.topViewController(rootController)
    }
}

// MARK: private

private extension UIApplication {
    static func topViewController(_ viewController: UIViewController) -> UIViewController {
        guard let presentedViewController = viewController.presentedViewController else {
            return viewController
        }
        if let navigationController = presentedViewController as? UINavigationController {
            if let visibleViewController = navigationController.visibleViewController {
                return topViewController(visibleViewController)
            }
        } else if let tabBarController = presentedViewController as? UITabBarController {
            if let selectedViewController = tabBarController.selectedViewController {
                return topViewController(selectedViewController)
            }
        }
        return topViewController(presentedViewController)
    }
}
