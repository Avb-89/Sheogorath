//
//  NativeUI.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import SwiftUI
import AppKit

struct ChatUI: View {
    @State private var input = ""
    @State private var transcript: [String] = []
    @State private var consoleMode = false
    @EnvironmentObject private var core: SheoCore

    var body: some View {
        Group {
            switch core.state {
            case .sovngarde(let diagnostic):
                sovngardeView(diagnostic: diagnostic)
            case .booting, .ready:
                chatView
            }
        }
        .frame(minWidth: 620, minHeight: 440)
    }

    private var chatView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sheogorath")
                            .font(.title2.weight(.semibold))

                        Text("The Madgod is listening.")
                            .foregroundStyle(.secondary)

                        ForEach(Array(transcript.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }

                        Color.clear
                            .frame(height: 1)
                            .id("transcript-bottom")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                }
                .onChange(of: transcript.count) {
                    withAnimation {
                        proxy.scrollTo("transcript-bottom", anchor: .bottom)
                    }
                }
            }

            Divider()

            HStack(alignment: .bottom, spacing: 12) {
                ChatInput(text: $input, onSubmit: submitInput)

                Button {
                    submitInput()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(16)
        }
    }

    private func submitInput() {
        let command = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }

        transcript.append("> \(command)")

        if command == "/sheoexit" || command == "/sheoquit" {
            core.terminate()
            return
        }

        if command == "/console" {
            consoleMode = true
            transcript.append("Console mode enabled.")
            input = ""
            return
        }

        if consoleMode {
            if command == "exit" || command == "quit" {
                consoleMode = false
                transcript.append("Console mode disabled.")
                input = ""
                return
            }

            let output = core.shell.execute(command)
            if !output.isEmpty {
                transcript.append(output)
            }
        } else if command.hasPrefix("/") {
            let shellCommand = String(command.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !shellCommand.isEmpty else {
                input = ""
                return
            }

            let output = core.shell.execute(shellCommand)
            if !output.isEmpty {
                transcript.append(output)
            }
        } else {
            transcript.append("No conversational handler is available yet.")
        }

        input = ""
    }

    private func sovngardeView(diagnostic: CoreDiagnostic) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sovngarde")
                .font(.title2.weight(.semibold))

            Text("Sheogorath survived Oblivion.")
                .foregroundStyle(.secondary)

            Divider()

            Text("Diagnostic")
                .font(.headline)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !diagnostic.failures.isEmpty {
                        Text("\(diagnostic.failures.count) critical failure\(diagnostic.failures.count == 1 ? "" : "s") detected.")
                            .font(.headline)

                        ForEach(Array(diagnostic.failures.enumerated()), id: \.offset) { _, failure in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(failure.step)
                                    .font(.system(.body, design: .monospaced).bold())
                                    .foregroundStyle(.red)

                                Text("FAILED — \(failure.detail)")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.red)
                                    .textSelection(.enabled)
                            }
                        }
                    }

                    if !diagnostic.skipped.isEmpty {
                        Text("\(diagnostic.skipped.count) check\(diagnostic.skipped.count == 1 ? "" : "s") skipped.")
                            .font(.headline)

                        ForEach(Array(diagnostic.skipped.enumerated()), id: \.offset) { _, item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.step)
                                    .font(.system(.body, design: .monospaced).bold())

                                Text("SKIPPED — \(item.detail)")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            Text("Reconcile is required before normal operation can resume.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}

private struct ChatInput: NSViewRepresentable {
    @Binding var text: String
    let onSubmit: () -> Void
    @State private var contentHeight: CGFloat = 22

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSScrollView, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? nsView.intrinsicContentSize.width, height: bodyHeight)
    }

    var bodyHeight: CGFloat {
        min(max(contentHeight, 22), 120)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, contentHeight: $contentHeight, onSubmit: onSubmit)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = ChatTextView()
        textView.delegate = context.coordinator
        textView.onSubmit = onSubmit
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.drawsBackground = false
        textView.font = NSFont.preferredFont(forTextStyle: .body)
        textView.textContainerInset = NSSize(width: 0, height: 2)
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.onHeightChange = context.coordinator.updateHeight

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? ChatTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        textView.onSubmit = onSubmit
        textView.onHeightChange = context.coordinator.updateHeight
        context.coordinator.updateHeight(textView.contentHeight)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        @Binding var contentHeight: CGFloat
        let onSubmit: () -> Void

        init(text: Binding<String>, contentHeight: Binding<CGFloat>, onSubmit: @escaping () -> Void) {
            _text = text
            _contentHeight = contentHeight
            self.onSubmit = onSubmit
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
        }

        func updateHeight(_ height: CGFloat) {
            let height = min(max(height, 22), 120)
            if contentHeight != height {
                DispatchQueue.main.async {
                    self.contentHeight = height
                }
            }
        }
    }
}

private final class ChatTextView: NSTextView {
    var onSubmit: (() -> Void)?
    var onHeightChange: ((CGFloat) -> Void)?

    var contentHeight: CGFloat {
        guard let layoutManager, let textContainer else { return 22 }
        layoutManager.ensureLayout(for: textContainer)
        return layoutManager.usedRect(for: textContainer).height + textContainerInset.height * 2
    }

    override func didChangeText() {
        super.didChangeText()
        onHeightChange?(contentHeight)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 76 {
            if event.modifierFlags.contains(.shift) {
                insertNewline(nil)
            } else {
                onSubmit?()
            }
            return
        }

        super.keyDown(with: event)
    }
}
