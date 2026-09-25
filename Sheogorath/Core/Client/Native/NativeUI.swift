//
//  NativeUI.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import SwiftUI

struct ChatUI: View {
    @State private var input = ""
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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sheogorath")
                        .font(.title2.weight(.semibold))

                    Text("The Madgod is listening.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }

            Divider()

            HStack(alignment: .bottom, spacing: 12) {
                TextField("Message Sheogorath…", text: $input, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...6)

                Button {
                    input = ""
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
