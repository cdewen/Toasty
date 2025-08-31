//
//  ToastyTest.swift
//  Toasty
//
//  Created by Carter Ewen on 8/31/25.
//

import XCTest
@testable import Toasty
import SwiftUI

@MainActor
final class ToastyTests: XCTestCase {
    
    // MARK: - Toast Creation Tests
    
    func testToastCreation() {
        let toast = Toast(style: DefaultToastStyle.success(), message: "Test Message")
        XCTAssertEqual(toast.message, "Test Message")
        XCTAssertNotNil(toast.id)
        XCTAssertNotNil(toast.createdAt)
    }
    
    func testToastConvenienceInitializers() {
        let success = Toast.success("Success")
        XCTAssertEqual(success.message, "Success")
        XCTAssertEqual(success.style.iconName, "checkmark.circle.fill")
        
        let error = Toast.error("Error")
        XCTAssertEqual(error.message, "Error")
        XCTAssertEqual(error.style.iconName, "xmark.circle.fill")
        
        let info = Toast.info("Info")
        XCTAssertEqual(info.message, "Info")
        XCTAssertEqual(info.style.iconName, "info.circle.fill")
        
        let loading = Toast.loading()
        XCTAssertEqual(loading.message, "Loading…")
        XCTAssertNil(loading.style.iconName)
    }
    
    // MARK: - ToastManager Tests
    
    func testManagerShowToast() {
        let manager = ToastManager()
        let toast = Toast.success("Test")
        
        manager.show(toast)
        XCTAssertEqual(manager.toasts.count, 1)
        XCTAssertEqual(manager.toasts.first?.message, "Test")
    }
    
    func testManagerMaxToasts() {
        var config = ToastConfiguration()
        config.maxToasts = 2
        let manager = ToastManager(configuration: config)
        
        manager.show(.info("Toast 1"))
        manager.show(.info("Toast 2"))
        manager.show(.info("Toast 3"))
        
        XCTAssertEqual(manager.toasts.count, 2)
        XCTAssertEqual(manager.toasts.first?.message, "Toast 2")
        XCTAssertEqual(manager.toasts.last?.message, "Toast 3")
    }
    
    func testManagerDismiss() {
        let manager = ToastManager()
        let toast = Toast.success("Test")
        
        manager.show(toast)
        XCTAssertEqual(manager.toasts.count, 1)
        
        manager.dismiss(toast)
        XCTAssertEqual(manager.toasts.count, 0)
    }
    
    func testManagerDismissAll() {
        let manager = ToastManager()
        
        manager.show(.info("Toast 1"))
        manager.show(.info("Toast 2"))
        manager.show(.info("Toast 3"))
        XCTAssertEqual(manager.toasts.count, 3)
        
        let currentToasts = manager.toasts
        currentToasts.forEach { manager.dismiss($0) }
        XCTAssertEqual(manager.toasts.count, 0)
    }
    
    // MARK: - ToastHandle Tests
    
    func testToastHandle() async {
        let manager = ToastManager()
        let handle = manager.show(.loading("Loading"))
        
        XCTAssertEqual(manager.toasts.count, 1)
        XCTAssertEqual(manager.toasts.first?.message, "Loading")
        
        await handle.dismiss()
        XCTAssertEqual(manager.toasts.count, 0)
    }
    
    func testToastHandleUpdate() async {
        let manager = ToastManager()
        let handle = manager.show(.loading("Loading"))
        
        XCTAssertEqual(manager.toasts.first?.message, "Loading")
        
        await handle.update(
            style: DefaultToastStyle.success(),
            message: "Complete",
            duration: 2
        )
        
        XCTAssertEqual(manager.toasts.first?.message, "Complete")
        XCTAssertEqual(manager.toasts.first?.style.iconName, "checkmark.circle.fill")
    }
    
    // MARK: - Configuration Tests
    
    func testCustomConfiguration() {
        var config = ToastConfiguration()
        config.maxToasts = 5
        config.defaultDuration = 3.0
        config.toastWidth = 250
        
        let manager = ToastManager(configuration: config)
        
        XCTAssertEqual(manager.configuration.maxToasts, 5)
        XCTAssertEqual(manager.configuration.defaultDuration, 3.0)
        XCTAssertEqual(manager.configuration.toastWidth, 250)
    }
    
    func testDefaultConfiguration() {
        let config = ToastConfiguration()
        
        XCTAssertEqual(config.maxToasts, 3)
        XCTAssertEqual(config.defaultDuration, 4.5)
        XCTAssertEqual(config.toastWidth, 220)
        XCTAssertEqual(config.animationDuration, 0.3)
    }
    
    // MARK: - Toast Styles Tests
    
    func testDefaultToastStyles() {
        let success = DefaultToastStyle.success()
        XCTAssertEqual(success.iconName, "checkmark.circle.fill")
        XCTAssertEqual(success.iconColor, .green)
        XCTAssertEqual(success.backgroundColor, .white)
        
        let error = DefaultToastStyle.error()
        XCTAssertEqual(error.iconName, "xmark.circle.fill")
        XCTAssertEqual(error.iconColor, .red)
        
        let info = DefaultToastStyle.info()
        XCTAssertEqual(info.iconName, "info.circle.fill")
        XCTAssertEqual(info.iconColor, .blue)
    }
    
    func testCustomToastStyle() {
        let custom = DefaultToastStyle.custom(
            iconName: "star.fill",
            iconColor: .yellow,
            backgroundColor: .purple
        )
        
        XCTAssertEqual(custom.iconName, "star.fill")
        XCTAssertEqual(custom.iconColor, .yellow)
        XCTAssertEqual(custom.backgroundColor, .purple)
    }
    
    func testLoadingToastStyle() {
        let loading = LoadingToastStyle()
        XCTAssertNil(loading.iconName)
        XCTAssertEqual(loading.iconColor, .primary)
        XCTAssertEqual(loading.backgroundColor, .white)
    }
    
    // MARK: - Expansion Tests
    
    func testToggleExpanded() {
        let manager = ToastManager()
        
        // Can't expand with only one toast
        manager.show(.info("Toast 1"))
        manager.toggleExpanded()
        XCTAssertFalse(manager.isExpanded)
        
        // Can expand with multiple toasts
        manager.show(.info("Toast 2"))
        manager.toggleExpanded()
        XCTAssertTrue(manager.isExpanded)
        
        // Can collapse
        manager.toggleExpanded()
        XCTAssertFalse(manager.isExpanded)
    }
    
    func testAutoCollapseWhenDismissing() {
        let manager = ToastManager()
        
        manager.show(.info("Toast 1"))
        manager.show(.info("Toast 2"))
        
        manager.toggleExpanded()
        XCTAssertTrue(manager.isExpanded)
        
        // Dismiss one toast - should remain expanded
        manager.dismiss(manager.toasts.first!)
        XCTAssertFalse(manager.isExpanded) // Auto-collapses when only 1 toast left
    }
    
    // MARK: - Async Loading Task Test
    
    func testShowLoadingTask() async {
        let manager = ToastManager()
        
        let task = ToastManager.showLoadingTask(
            manager: manager,
            loadingMessage: "Processing...",
            operation: {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                return "Success Data"
            },
            success: { result in "Completed: \(result)" },
            failure: { error in "Failed: \(error.localizedDescription)" }
        )
        
        // Initially should show loading toast
        XCTAssertEqual(manager.toasts.count, 1)
        XCTAssertEqual(manager.toasts.first?.message, "Processing...")
        
        // Wait for task to complete
        await task.value
        
        // Should update to success
        XCTAssertEqual(manager.toasts.count, 1)
        XCTAssertEqual(manager.toasts.first?.message, "Completed: Success Data")
    }
    
    func testShowLoadingTaskFailure() async {
        let manager = ToastManager()
        
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "Test error occurred" }
        }
        
        let task = ToastManager.showLoadingTask(
            manager: manager,
            operation: {
                try await Task.sleep(nanoseconds: 50_000_000)
                throw TestError()
            },
            success: { _ in "Success" },
            failure: { error in "Error: \(error.localizedDescription)" }
        )
        
        await task.value
        
        XCTAssertEqual(manager.toasts.count, 1)
        XCTAssertEqual(manager.toasts.first?.message, "Error: Test error occurred")
    }
    
    // MARK: - Duration Tests
    
    func testCustomDuration() {
        var config = ToastConfiguration()
        config.defaultDuration = 2.0
        let manager = ToastManager(configuration: config) To
        
        // Using default duration
        manager.show(.info("Test"))
        
        // Using custom duration
        manager.show(.info("Test 2"), duration: 5.0)
        
        XCTAssertEqual(manager.toasts.count, 2)
    }
    
    func testNoDismissDuration() {
        let manager = ToastManager()
        
        // Duration 0 means no auto-dismiss
        manager.show(.loading("Persistent"), duration: 0)
        
        XCTAssertEqual(manager.toasts.count, 1)
        // Toast should remain until manually dismissed
    }
    
    // MARK: - Environment Tests
    
    func testEnvironmentKey() {
        let defaultManager = ToastManagerKey.defaultValue
        XCTAssertNotNil(defaultManager)
        XCTAssertEqual(defaultManager.toasts.count, 0)
    }
    
    // MARK: - Update Toast Tests
    
    func testUpdateToast() {
        let manager = ToastManager()
        let toast = Toast.loading("Loading")
        
        manager.show(toast)
        XCTAssertEqual(manager.toasts.first?.message, "Loading")
        
        manager.updateToast(
            toast,
            style: DefaultToastStyle.success(),
            message: "Updated",
            duration: 2
        )
        
        XCTAssertEqual(manager.toasts.first?.message, "Updated")
        XCTAssertEqual(manager.toasts.first?.id, toast.id)
    }
}
