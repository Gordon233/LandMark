

import SwiftUI

struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages Area
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.hasData {
                            ChatMessageView(
                                message: messageText,
                                response: viewModel.formattedResponse,
                                isLoading: viewModel.isLoading
                            )
                        } else {
                            ChatEmptyStateView()
                        }
                    }
                    .padding()
                }

                Divider()

                // Input Area
                ChatInputView(
                    text: $messageText,
                    isLoading: viewModel.isLoading,
                    onSend: sendMessage
                )
                .focused($isTextFieldFocused)
            }
            .navigationTitle("AI Chat")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear", systemImage: "trash") {
                        viewModel.clearAll()
                        messageText = ""
                    }
                    .disabled(!viewModel.hasData)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.hasError)) {
                Button("OK") {
                    // Error handling
                }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        Task {
            await viewModel.sendMessage(messageText)
        }

        isTextFieldFocused = false
    }
}

// MARK: - Chat Message View
struct ChatMessageView: View {
    let message: String
    let response: String
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Message
            HStack {
                Spacer()
                Text(message)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
            }

            // AI Response
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Thinking...")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(response)
                    }
                }
                .padding()
                .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))

                Spacer()
            }
        }
    }
}

// MARK: - Chat Input View
struct ChatInputView: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("Type your message...", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .onSubmit(onSend)

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canSend ? .blue : .gray)
            }
            .disabled(!canSend)
        }
        .padding()
        .background(.regularMaterial)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
}

// MARK: - Empty State View
struct ChatEmptyStateView: View {
    var body: some View {
        ContentUnavailableView(
            "Start a Conversation",
            systemImage: "bubble.left.and.bubble.right",
            description: Text("Ask me anything and I'll help you out!")
        )
    }
}

// MARK: - Previews
#Preview("Chat View") {
    ChatView()
}
