//
//  Test.swift
//  Toasty
//
//  Created by Carter Ewen on 8/31/25.
//
import SwiftUI

// MARK: - Preview / Example Usage

struct testView: View {
    @Environment(\.toastManager) private var toastManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Multi-Step Demo")
                .font(.headline)
            
            Button("Multi-Step Loading Demo") {
                Task {
                    // Step 1: show a loading toast with indefinite duration (0 means manual dismissal)
                    let handle = toastManager.show(Toast.loading("Step 1 / 3 – Starting…"), duration: 0)

                    // Pretend to do some work
                    try? await Task.sleep(for: .seconds(1))
                    
                    // Step 2: update message & keep loading style using handle
                    await handle.update(
                        style: LoadingToastStyle(),
                        message: "Step 2 / 3 – Processing…",
                        duration: 0
                    )

                    try? await Task.sleep(for: .seconds(1))

                    // Step 3: final success update using handle (auto-dismiss after 2s)
                    await handle.update(
                        style: DefaultToastStyle.success(),
                        message: "Completed!",
                        duration: 2
                    )
                }
            }
        }
    }
}

// MARK: - Modern Preview (Environment Injection)
struct ModernToastPreview: View {
    @Environment(\.toastManager) private var toastManager
    @State private var currentHandle: ToastHandle?
    
    var body: some View {
        TabView {
            VStack(spacing: 20) {
                
                Button("Show Success") {
                    toastManager.show(Toast.success("Saved!"), duration: 3)
                }
                Button("Show Error") {
                    toastManager.show(Toast.error("Something failed"), duration: 4.5)
                }
                Button("Show Controllable Toast") {
                    currentHandle = toastManager.show(Toast.info("Tap dismiss to remove"), duration: 0)
                }
                
                Button("Dismiss Current Toast") {
                    Task {
                        await currentHandle?.dismiss()
                        currentHandle = nil
                    }
                }
                .disabled(currentHandle == nil)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem {
                Label("Modern", systemImage: "1.circle")
            }
            
            NavigationStack{
                VStack(spacing: 20) {
                    Text("More Examples")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Button("Show Info") {
                        toastManager.show(Toast.info("Heads up"), duration: 3)
                    }
                    Button("Show Custom (No Icon)") {
                        toastManager.show(Toast.custom("Custom toast"), duration: 4.5)
                    }
                    Button("Show Custom (Icon)") {
                        toastManager.show(Toast.custom("Custom toast with star", iconName: "star.fill", iconColor: .purple), duration: 4.5)
                    }
                    Button("Simulate Async Task") {
                        Task {
                            ToastManager.showLoadingTask(
                                manager: toastManager,
                                loadingMessage: "Fetching…",
                                operation: {
                                    try await Task.sleep(for: .seconds(2))
                                    return "42"
                                },
                                success: { (result: String) in "Result: \(result)" },
                                failure: { (error: Error) in "Failed: \(error.localizedDescription)" }
                            )
                        }
                    }
                    Button("Simulate Failed Task") {
                        struct SampleError: Error {}
                        Task {
                            ToastManager.showLoadingTask(
                                manager: toastManager,
                                loadingMessage: "Processing…",
                                operation: {
                                    try await Task.sleep(for: .seconds(2))
                                    throw SampleError()
                                },
                                success: { _ in "Should not happen" },
                                failure: { _ in "Something went wrong" }
                            )
                        }
                    }
                    NavigationLink("Legacy Test", destination: testView())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tabItem {
                Label("Examples", systemImage: "2.circle")
            }
        }
        // Convenient API (recommended):
        .toasts()
        
        // Alternative explicit API for custom positioning:
        // .overlay(alignment: .top) { ToastHost(spacing: 12) }
    }
}

#Preview {
    ModernToastPreview()
        // Modern approach: inject ToastManager through environment
        .environment(\.toastManager, ToastManager())
}




