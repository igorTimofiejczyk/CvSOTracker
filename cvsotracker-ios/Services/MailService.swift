//
//  MailService.swift
//  Services
//
//  Created by Ihar Tsimafeichyk on 2/10/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import Foundation
import MessageUI

public protocol MailServiceHolder {
    var mailService: MailService { get }
}

public protocol MailService {
    var canSendMail: Bool { get }

    var supportEmailAddress: String { get }

    func showMailUnavailableError()

    func makeMailComposer(subject: String, messageBody: String, isHTML: Bool) -> UIViewController?

    func makeMailComposer(subject: String,
                          messageBody: String,
                          isHTML: Bool,
                          toRecipients: [String]?,
                          attachments: [MailAttachment]?,
                          toCcRecipients: [String]?) -> UIViewController?

    var MFMailComposeViewControllerDismissNotification: Notification.Name { get }

    func showContactSupportMailComposer()
}

public extension MailService {
    var MFMailComposeViewControllerDismissNotification: Notification.Name {
        return Notification.Name("MFMailComposeViewControllerDismiss")
    }
}

public struct MailAttachment {
    let data: Data
    let mimeType: String
    let fileName: String
}

public final class MailServiceImplementation: NSObject, MailService {
    private struct Constants {
        static let supportEmail = "cvsotracker@gmail.com"
    }

    let onError: (String) -> Void
    let logger: Logger

    public init(logger: Logger, onError: @escaping ((String) -> Void)) {
        self.logger = logger
        self.onError = onError
    }

    public var canSendMail: Bool {
        return MFMailComposeViewController.canSendMail()
    }

    public var supportEmailAddress: String {
        return Constants.supportEmail
    }

    public func showMailUnavailableError() {
        onError("Unable to prepare email. Please, check your mail settings and try again later.")
    }

    public func makeMailComposer(subject: String, messageBody: String, isHTML: Bool) -> UIViewController? {
        return makeMailComposer(subject: subject, messageBody: messageBody, isHTML: isHTML, toRecipients: nil)
    }

    public func makeMailComposer(subject: String,
                                 messageBody: String,
                                 isHTML: Bool,
                                 toRecipients: [String]?,
                                 attachments: [MailAttachment]? = nil,
                                 toCcRecipients: [String]? = nil) -> UIViewController? {
        guard canSendMail else {
            showMailUnavailableError()
            //to mute unused warning becase delegate is false-positive case for script
            mailComposeController(MFMailComposeViewController(), didFinishWith: MFMailComposeResult.failed, error: nil)
            return nil
        }

        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = self
        mailComposeVC.setSubject(subject)
        mailComposeVC.setMessageBody(messageBody, isHTML: isHTML)
        mailComposeVC.setToRecipients(toRecipients)
        mailComposeVC.setCcRecipients(toCcRecipients)
        attachments?.forEach { (attachment) -> Void in
            mailComposeVC.addAttachmentData(attachment.data, mimeType: attachment.mimeType, fileName: attachment.fileName)
        }
        return mailComposeVC
    }

    public func showContactSupportMailComposer() {
        if let vc = makeMailComposer(subject: "CvSOTracker support", messageBody: "Help me please!", isHTML: false) {
            UIApplication.topViewController?.present(vc, animated: true, completion: nil)
        } else {
            logger.error("[Mail] failed to present contact support mail composer")
        }
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension MailServiceImplementation: MFMailComposeViewControllerDelegate {
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: {
            /// we want to know that MFMailCompose was dismissed
            NotificationCenter.default.post(name: self.MFMailComposeViewControllerDismissNotification, object: nil, userInfo: ["MFMailComposeResult": result.rawValue])
            if error != nil || result.rawValue == MFMailComposeResult.failed.rawValue {
                self.logger.error("[Mail] Mail composer failed with error: \(String(describing: error))")
            } else {
                switch result.rawValue {
                case MFMailComposeResult.cancelled.rawValue:
                    self.logger.info("[Mail] Mail send cancelled")
                case MFMailComposeResult.saved.rawValue:
                    self.logger.info("[Mail] Mail saved")
                case MFMailComposeResult.sent.rawValue:
                    self.logger.info("[Mail] Mail sent")
                default:
                    break
                }
            }
        })
    }
}
