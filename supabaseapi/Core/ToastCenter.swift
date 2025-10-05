import SwiftUI
import Combine

final class ToastCenter: ObservableObject {
    @Published var successMessage: String = ""
    @Published var errorMessage: String = ""

    func flashSuccess(_ msg: String) {
        successMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.successMessage = ""
        }
    }

    func flashError(_ msg: String) {
        errorMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.errorMessage = ""
        }
    }
}
