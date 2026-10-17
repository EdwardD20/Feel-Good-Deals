import SwiftUI  // import SwiftUI
import SafariServices  // import SafariServices

struct SafariView: UIViewControllerRepresentable {  // struct SafariView: UIViewControllerRepresentable
    let url: URL  // let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {  // func makeUIViewController(context: Context) -> SFSafariViewController
        let config = SFSafariViewController.Configuration()  // let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false  // config.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: config)  // let vc = SFSafariViewController(url: url, configuration: config)
        return vc  // return vc
    }  // func makeUIViewController(context: Context) -> SFSafariViewController
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {  // func updateUIViewController(...)
        // No updates needed  // comment
    }  // func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context)
}  // struct SafariView: UIViewControllerRepresentable
