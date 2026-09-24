//
//  NativeUI.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import SwiftUI

struct ChatUI: View {
    @State private var input = ""

    var body: some View {
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
        .frame(minWidth: 620, minHeight: 440)
    }
}
