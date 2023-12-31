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
// UUID: 219A2018-8848-44D0-BFE4-8CF06016EBE8

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

fileprivate let thisYear = {
    String(Calendar.current.dateComponents([.year], from: Date.now).year!)
}

fileprivate let copyrightNotice = """
// -*- mode: swift; coding: utf-8-unix; -*- vi:ai:et:sw=4
//
// Package: fdbclient-swift
//
// © \(thisYear()) GLVI Gesellschaft für Luftverkehrsinformatik mbH, Hamburg, DE
// ALL RIGHTS RESERVED.
//
// This file was automatically generated. DO NOT EDIT.
//
// UUID: \(UUID())
"""

fileprivate let endOfFile = """
// End of file

// Local Variables:
// indent-tabs-mode: nil
// swift-mode:basic-offset: 4
// End:
"""

fileprivate let `deprecated` = AttributeSyntax(
    TypeSyntax(IdentifierTypeSyntax(name: .identifier("available"))),
    argumentList: {
        LabeledExprSyntax(expression: BinaryOperatorExprSyntax(text: "*"))
        LabeledExprSyntax(expression: DeclReferenceExprSyntax(baseName: .keyword(.deprecated)))
    })

fileprivate let `public` = DeclModifierSyntax(name: .keyword(.public))

fileprivate let `static` = DeclModifierSyntax(name: .keyword(.static))

fileprivate let `import` = {
    ImportDeclSyntax(path: [
        ImportPathComponentSyntax(name: TokenSyntax.identifier($0))
    ])
}

fileprivate func construct(function f: TokenSyntax, with arg: TokenSyntax) -> ExprSyntax {
    let fref = DeclReferenceExprSyntax(baseName: f)
    let aref = DeclReferenceExprSyntax(baseName: arg)
    return ExprSyntax(
        FunctionCallExprSyntax(
            calledExpression: fref,
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax {
                LabeledExprSyntax(
                    label: .identifier("rawValue"),
                    colon: .colonToken(),
                    expression: aref)
            },
            rightParen: .rightParenToken()))
}

fileprivate func generateStatements(_ scope: Scope, options: [String: FDBOption]) -> CodeBlockItemListSyntax {
    let (extends, short) = switch scope {
    case .network: ("NetworkOption", "NET")
    case .database: ("DatabaseOption", "DB")
    case .transaction: ("TransactionOption", "TR")
    }
    return CodeBlockItemListSyntax {
        for module in ["Clibfdb", "Foundation"] {
            `import`(module)
        }
        ExtensionDeclSyntax(leadingTrivia: [.newlines(2)], extendedType: IdentifierTypeSyntax(name: .identifier(extends))) {
            for (name, option) in options.sorted(by: {$0.0 < $1.0}) {
                let mainDescription = [option]
                    .compactMap { $0.description }
                    .filter { !$0.isEmpty }
                    .filter { $0.lowercased() != "deprecated" }
                    .map { TriviaPiece.docLineComment("/// \($0)") }
                    .flatMap { [$0, .newlines(1)] }
                let paramDescriptionn = [option]
                    .compactMap { $0.parameter }
                    .map { $0.type.lowercased() == "bytes" ? FDBOptionParameter(type: "Data", description: $0.description) : $0 }
                    .map { TriviaPiece.docLineComment("/// Parameter type: \($0.type); \($0.description ?? "")")}
                    .flatMap { [$0, .newlines(1)] }
                let attributes = AttributeListSyntax {
                    if let description = option.description.map({$0.lowercased()}), description == "deprecated" {
                        `deprecated`
                    }
                }
                VariableDeclSyntax(
                    leadingTrivia: Trivia(pieces: [[.newlines(2)], mainDescription, paramDescriptionn].joined()),
                    attributes: attributes,
                    modifiers: [`public`, `static`],
                    bindingSpecifier: .keyword(.let))
                {
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(identifier: .identifier(name.camelCased())),
                        initializer: InitializerClauseSyntax(
                            value: construct(
                                function: .identifier(extends),
                                with: .identifier("FDB_\(short)_OPTION_\(name.uppercased())"))))
                }
            }
        }
    }
}

func generateSourceFile(_ scope: Scope, options: [String: FDBOption], validate: Bool = false) throws -> SourceFileSyntax {
    let source = SourceFileSyntax(
        leadingTrivia: [.lineComment(copyrightNotice), .newlines(2)],
        statements: generateStatements(scope, options: options),
        endOfFileToken: .endOfFileToken(),
        trailingTrivia: [.newlines(2), .lineComment(endOfFile), .newlines(1)])
    return validate ? try SourceFileSyntax(validating: source) : source
}

func emit(_ source: SourceFileSyntax, to stream: OutputStream) {
    stream.write(source.formatted().description)
}

func emit(_ source: SourceFileSyntax, to file: FileHandle) {
    file.write(source.formatted().description)
}

extension String {
    fileprivate func camelCased() -> String {
        var result = String()
        var current = startIndex
        var usIndex = self[current...].firstIndex(of: "_") ?? endIndex
        result.append(self[current..<usIndex].lowercased())
        while usIndex < endIndex {
            current = index(after: usIndex)
            usIndex = self[current...].firstIndex(of: "_") ?? endIndex
            result.append(self[current..<usIndex].capitalized)
        }
        return result
    }
}

// End of file

// Local Variables:
// indent-tabs-mode: nil
// swift-mode:basic-offset: 4
// End:
