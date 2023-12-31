// -*- mode: swift; coding: utf-8-unix; -*- vi:ai:et:sw=4
//
// Generate Swift bindings for FoundationDB's fdb.option file format
//
// Copyright © 2023 GLVI Gesellschaft für Luftverkehrsinformatik mbH, Hamburg, DE
//
// This program is free software: you can redistribute it and/or
// modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see
// <https://www.gnu.org/licenses/>.
//
// Package: fdb-option-generator-swift
//
// Author(s): Kai Lothar John
//
// UUID: 441168FC-864E-4F48-AF65-E02D5F554685

import ArgumentParser
import Foundation

fileprivate var standardOutput = FileHandle.standardOutput
fileprivate var standardError = FileHandle.standardError

fileprivate let discussion = "Parses fdb.options from <file> and generates Swift bindings depending on the generator options. If none of the generator options are given, parses the fdb.options file, and then quits. Use either of --output-directory or --stdout to control where the generated Swift bindings go."

@main struct fdboptgen: ParsableCommand {

    static let configuration = CommandConfiguration(
        abstract: "Generate Swift bindings from FoundationDB's fdb.options file",
        discussion: discussion)

    @Argument(help: ArgumentHelp("Path to FoundationDB fdb.options file", valueName: "file"))
    var inputFile = "/usr/local/include/foundationdb/fdb.options"

    @Option(name: .shortAndLong)
    var outputDirectory = FileManager.default.currentDirectoryPath

    @OptionGroup(title: "Generator options")
    var generators: GeneratorOptions

    @Flag(name: .long, help: ArgumentHelp("Write generated files to standard output", discussion: "Ignores --output-directory"))
    var stdout: Bool = false

    func validate() throws {
        guard !generators.options.isEmpty else {
            throw ValidationError("Error: At least one of the generator options (\(GeneratorOption.allCases.map {"--\($0.rawValue)"})) must be given")
        }
    }

    mutating func run() throws {
        let url = URL(filePath: inputFile, directoryHint: .checkFileSystem)
        let stream = InputStream(url: url)!
        let parser = FDBOptionsParser(stream: stream)
        let delegate = MyFDBOptionsParserDelegate()
        parser.delegate = delegate
        let parseResult = parser.parse()
        guard parseResult else {
            if let parseError = parser.parserError {
                print(parseError, to: &standardError)
            }
            return
        }
        for generator in generators.options {
            let (scope, store) = switch generator {
            case .network: (Scope.network, delegate.networkOptions)
            case .database: (Scope.database, delegate.databaseOptions)
            case .transaction: (Scope.transaction, delegate.transactionOptions)
            }
            if let source = try? generateSourceFile(scope, options: store, validate: true) {
                if stdout {
                    emit(source, to: standardOutput)
                } else {
                    let name = "\(generator.rawValue.capitalized)Option.gen.swift"
                    let srcs = URL(filePath: outputDirectory, directoryHint: .checkFileSystem)
                    let file: URL = srcs.appending(path: name)
                    let stream = OutputStream(url: file, append: false)!
                    stream.open()
                    defer {stream.close()}
                    emit(source, to: stream)
                }
            }
        }
    }
}

struct GeneratorOptions: ParsableArguments {
    @Flag var options: [GeneratorOption] = []
}

enum GeneratorOption: String, EnumerableFlag {
    case network
    case database
    case transaction

    private static let helpText = { (option:GeneratorOption) in
        "Generate Swift bindings for the FoundationDB \(option.rawValue) options"
    }

    static func help(for value: Self) -> ArgumentHelp? {
        ArgumentHelp(helpText(value))
    }

    static func name(for value: Self) -> NameSpecification {
        .shortAndLong
    }
}

// End of file

// Local Variables:
// indent-tabs-mode: nil
// swift-mode:basic-offset: 4
// End:
