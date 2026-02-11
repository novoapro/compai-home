import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        #if targetEnvironment(macCatalyst)
        if let titlebar = windowScene.titlebar {
            titlebar.toolbarStyle = .unified
        }
        // Prevent the window from being fully released on close so it can be restored
        windowScene.sizeRestrictions?.minimumSize = CGSize(width: 480, height: 400)
        #endif
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        // Ensure the window is visible when the scene activates
        windowScene.windows.forEach { $0.makeKeyAndVisible() }
    }
}
