import Foundation
import SwiftUI

enum AppError: LocalizedError {
    case coreDataError(String)
    case validationError(String)
    case exportError(String)
    case importError(String)
    case imageProcessingError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .coreDataError(let message):
            return "Data Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .exportError(let message):
            return "Export Error: \(message)"
        case .importError(let message):
            return "Import Error: \(message)"
        case .imageProcessingError(let message):
            return "Image Error: \(message)"
        case .unknownError:
            return "An unexpected error occurred"
        }
    }
}

class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var showError = false
    
    func handle(_ error: Error) {
        if let appError = error as? AppError {
            currentError = appError
        } else {
            currentError = .coreDataError(error.localizedDescription)
        }
        showError = true
    }
    
    func handle(_ error: AppError) {
        currentError = error
        showError = true
    }
}

struct ErrorAlert: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorHandler.showError) {
                Button("OK", role: .cancel) {
                    errorHandler.currentError = nil
                }
            } message: {
                if let error = errorHandler.currentError {
                    Text(error.errorDescription ?? "Unknown error")
                }
            }
    }
}

extension View {
    func withErrorHandling(_ errorHandler: ErrorHandler) -> some View {
        modifier(ErrorAlert(errorHandler: errorHandler))
    }
}
