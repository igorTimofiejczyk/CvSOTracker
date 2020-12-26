//
//  InformationView.swift
//  nconapp
//
//  Created by Ihar Tsimafeichyk on 2/10/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import Services
import SwiftUI
import WebKit

struct InformationView: View {
    @Environment(\.presentationMode) var presentationMode

    @State var mailComposeView = false

    var body: some View {
    NavigationView {
        List {
            Section(header: Text("Feedback").padding(EdgeInsets(top: 22, leading: 0, bottom: 0, trailing: 0))) {
                InformationViewRow(info: "Review on the App Store").onTapGesture {
                    guard let writeReviewURL = URL(string: AppInfo.appAppStoreReviewUrl)
                        else { fatalError("Expected a valid URL") }
                    UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
                }
                InformationViewRow(info: "Contact us").onTapGesture {
                    self.mailComposeView = true
                }
            }
            Section(header: Text("About")) {
                NavigationLink (destination: InformationWebView(path: ResourcesPath.termOfUsePath).navigationBarTitle("Terms of Use")) {
                        InformationViewRow(info: "Terms of Use")
                }
                NavigationLink (destination: InformationWebView(path: ResourcesPath.dataSourcePath).navigationBarTitle("Data Sources")) {
                    InformationViewRow(info: "Data Sources")
                }
                NavigationLink (destination: LicenseView().navigationBarTitle("Open Source Libraries")) {
                    InformationViewRow(info: "Open Source Libraries")
                }
            }
            Section(header: Text("\(AppInfo.appName) Version: \(AppInfo.appVersion)")) {
                //AppVersionRow()
                EmptyView()
            }
        }.listStyle(GroupedListStyle())
            .navigationBarItems(trailing: CloseButton(presentationMode: presentationMode))
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationBarTitle("App info", displayMode: .inline)
        }.sheet(isPresented: $mailComposeView, onDismiss: {
            self.mailComposeView = false
        }, content: {
            MailComposeViewController {
                self.mailComposeView = false
            }
        })
    }
}

struct InformationViewRow: View {
    let info: String
    var body: some View {
        HStack {
            Text(info).padding(4)
        }
    }
}

struct AppVersionRow: View {
    var body: some View {
        HStack {
            Text(AppInfo.appVersion).padding(4)
        }
    }
}

struct LicenseRow: View {
    let title: String
    let license: String
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(license).foregroundColor(.accentColor)
        }
    }
}

struct LicenseView: View {
    var body: some View {
        List {
            NavigationLink (destination: InformationWebView(path: ResourcesPath.BSD3).navigationBarTitle("BSD 3-Clause License")) {
                LicenseRow(title: "CocoaLumberjack", license: "BSD 3")
            }
            NavigationLink (destination: InformationWebView(path: ResourcesPath.MIT).navigationBarTitle("MIT License")) {
                LicenseRow(title: "SwiftLint", license: "MIT")
            }
        }
    }
}

struct DataSourceView: View {
    var body: some View {
        ScrollView {
            VStack {
                Text("").padding()
                Spacer()
            }
        }
    }
}

struct InformationWebView: UIViewRepresentable {
    let path: String

    func makeUIView(context: UIViewRepresentableContext<InformationWebView>) -> WKWebView {
        let wkWebView = AboutWebView()
        // Fix always white background on WKWebView https://forums.developer.apple.com/thread/121139
        wkWebView.isOpaque = false
        wkWebView.backgroundColor = .clear
        wkWebView.navigationDelegate = wkWebView
        return wkWebView
    }

    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<InformationWebView>) {
        let url = URL(fileURLWithPath: path)
        uiView.loadFileURL(url, allowingReadAccessTo: Bundle.main.bundleURL)
    }

}

class AboutWebView: WKWebView, WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
        }

        decisionHandler(.allow)
    }

}

struct MailComposeViewController: UIViewControllerRepresentable {
    var errorHandler: () -> Void

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailComposeViewController>) -> UIViewController {
        let mailService = AppDelegate.shared.context.mailService

        guard let mailComposer = mailService.makeMailComposer(subject: "[Feedback] CvSOTracker",
                                                              messageBody: "",
                                                              isHTML: false,
                                                              toRecipients: [mailService.supportEmailAddress],
                                                              attachments: nil,
                                                              toCcRecipients: nil) else {
                                                                errorHandler()
                                                                return UIViewController()
        }
        return mailComposer
    }

    func updateUIViewController(_ uiViewController: UIViewController,
                                context: UIViewControllerRepresentableContext<MailComposeViewController>) {
    }

}

struct AppInfo {
    static var appId: String {
        return "1501531365"
    }

    static var bundle: String {
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    }

    static var bundleName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    }

    static var appAppStoreReviewUrl: String {
        return "https://itunes.apple.com/app/id\(appId)?action=write-review"
    }

    static var appAppStoreRateUrl: String {
        return "itms-apps://itunes.apple.com/app/\(appId)"
    }

    static var appName: String {
        // CFBundleDisplayName
        return Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    }

    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

}

struct ResourcesPath {

    static var BSD3: String {
        return Bundle.main.path(forResource: "BSD3", ofType: "html") ?? ""
    }
    static var MIT: String {
        return Bundle.main.path(forResource: "MIT", ofType: "html") ?? ""
    }

    static var termOfUsePath: String {
        return Bundle.main.path(forResource: "ToU", ofType: "html") ?? ""
    }
    static var dataSourcePath: String {
        return Bundle.main.path(forResource: "DataSource", ofType: "html") ?? ""
    }

}
