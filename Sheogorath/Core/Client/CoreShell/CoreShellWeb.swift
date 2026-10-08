//
//  CoreShellWeb.swift
//  Sheogorath
//
//  Created by SITIS on 10/8/26.
//

import Foundation

@MainActor
extension CoreShell {
    func curl(arguments: [String]) async -> (text: String, success: Bool) {
        enum DisplayMode: String {
            case status = "-status"
            case response = "-response"
            case headers = "-headers"
            case body = "-body"
            case all = "-all"
        }

        var mode: DisplayMode = .response
        var selectedMode = false
        var timeout: TimeInterval = 10
        var outputPath: String?
        var address: String?
        var index = 0

        while index < arguments.count {
            let argument = arguments[index]
            if let requestedMode = DisplayMode(rawValue: argument) {
                guard !selectedMode else {
                    return ("curl: specify only one output mode", false)
                }
                mode = requestedMode
                selectedMode = true
            } else if argument == "-timeout" || argument == "-save" {
                guard index + 1 < arguments.count else {
                    return ("curl: missing value for \(argument)", false)
                }
                index += 1
                if argument == "-save" {
                    guard outputPath == nil else {
                        return ("curl: duplicate -save", false)
                    }
                    outputPath = arguments[index]
                } else {
                    guard let value = TimeInterval(arguments[index]), value > 0, value.isFinite else {
                        return ("curl: invalid timeout", false)
                    }
                    timeout = value
                }
            } else {
                guard !argument.hasPrefix("-"), address == nil else {
                    return ("curl: unexpected argument: \(argument)", false)
                }
                address = argument
            }
            index += 1
        }

        guard let address, let url = URL(string: address),
              let scheme = url.scheme?.lowercased(),
              (scheme == "http" || scheme == "https"), url.host != nil else {
            return ("usage: curl [-status|-response|-headers|-body|-all] [-save file] [-timeout seconds] <http(s)://url>", false)
        }

        let destination = outputPath.map { resolvedURL(for: $0) }
        if let destination, !core.canAccess(destination) {
            return ("permission denied: \(destination.path)", false)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let start = ProcessInfo.processInfo.systemUptime
        do {
            let (data, response) = try await session.data(for: request)
            let duration = Int((ProcessInfo.processInfo.systemUptime - start) * 1000)
            guard let http = response as? HTTPURLResponse else {
                return ("curl: non-HTTP response", false)
            }

            if let destination {
                guard core.canAccess(destination) else {
                    return ("permission denied: \(destination.path)", false)
                }
                do {
                    try data.write(to: destination, options: .atomic)
                } catch {
                    return ("curl: cannot save response: \(error.localizedDescription)", false)
                }
            }

            let statusLine = "HTTP \(http.statusCode)"
            let headers = http.allHeaderFields
                .map { "\($0.key): \($0.value)" }
                .sorted()
                .joined(separator: "\n")
            let summary = "HTTP:       \(http.statusCode)\nConnection: successful\nDuration:   \(duration) ms\nSize:       \(data.count) bytes"
            let body = String(decoding: data, as: UTF8.self)
            let output: String

            switch mode {
            case .status:
                output = String(http.statusCode)
            case .response:
                output = summary
            case .headers:
                output = statusLine + (headers.isEmpty ? "" : "\n" + headers)
            case .body:
                output = body
            case .all:
                var sections = ["> GET \(url.absoluteString)", statusLine]
                if !headers.isEmpty { sections.append(headers) }
                if !body.isEmpty { sections.append(body) }
                sections.append(summary)
                output = sections.joined(separator: "\n\n")
            }

            if let destination {
                return (output + "\nSaved: \(destination.path)", true)
            }
            return (output, true)
        } catch {
            let duration = Int((ProcessInfo.processInfo.systemUptime - start) * 1000)
            let detail = error.localizedDescription
            return ("HTTP:       —\nConnection: failed\nError:      \(detail)\nDuration:   \(duration) ms", false)
        }
    }
}
