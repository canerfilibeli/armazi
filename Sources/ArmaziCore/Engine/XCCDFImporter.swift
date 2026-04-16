import Foundation
import Yams

/// Converts CIS XCCDF (XML) benchmark files to Armazi YAML format.
public final class XCCDFImporter: NSObject, XMLParserDelegate {
    private var rules: [ParsedRule] = []
    private var currentElement = ""
    private var currentRule: ParsedRule?
    private var textBuffer = ""
    private var inCheckContent = false
    private var inFixText = false
    private var currentProfileLevel = 1

    private struct ParsedRule {
        var id: String = ""
        var title: String = ""
        var description: String = ""
        var checkContent: String = ""
        var fixText: String = ""
        var level: Int = 1
        var scored: Bool = true
    }

    /// Import an XCCDF XML file and produce Armazi YAML.
    public static func importFile(at url: URL, name: String? = nil, platform: String = "macOS") throws -> String {
        let data = try Data(contentsOf: url)
        let importer = XCCDFImporter()
        let rules = importer.parseXML(data)

        guard !rules.isEmpty else {
            throw BenchmarkError.invalidFormat("No rules found in XCCDF file")
        }

        return importer.generateYAML(rules: rules, name: name ?? url.deletingPathExtension().lastPathComponent, platform: platform)
    }

    private func parseXML(_ data: Data) -> [ParsedRule] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return rules
    }

    // MARK: - XMLParserDelegate

    public func parser(_ parser: XMLParser, didStartElement elementName: String,
                       namespaceURI: String?, qualifiedName: String?,
                       attributes: [String: String]) {
        currentElement = elementName
        textBuffer = ""

        switch elementName {
        case "Rule", "xccdf:Rule", "cdf:Rule":
            currentRule = ParsedRule()
            currentRule?.id = attributes["id"] ?? ""
            if let selected = attributes["selected"], selected == "false" {
                currentRule?.scored = false
            }

        case "check-content", "xccdf:check-content", "cdf:check-content":
            inCheckContent = true
            textBuffer = ""

        case "fixtext", "xccdf:fixtext", "cdf:fixtext",
             "fix", "xccdf:fix", "cdf:fix":
            inFixText = true
            textBuffer = ""

        case "Profile", "xccdf:Profile", "cdf:Profile":
            let profileId = (attributes["id"] ?? "").lowercased()
            if profileId.contains("level_2") || profileId.contains("level2") {
                currentProfileLevel = 2
            } else {
                currentProfileLevel = 1
            }

        default:
            break
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        textBuffer += string
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String,
                       namespaceURI: String?, qualifiedName: String?) {
        let text = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "title", "xccdf:title", "cdf:title":
            if currentRule != nil && !text.isEmpty {
                currentRule?.title = text
            }

        case "description", "xccdf:description", "cdf:description":
            if currentRule != nil && !text.isEmpty {
                // Strip HTML tags if present
                let cleaned = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                currentRule?.description = cleaned
            }

        case "check-content", "xccdf:check-content", "cdf:check-content":
            if currentRule != nil {
                currentRule?.checkContent = text
            }
            inCheckContent = false

        case "fixtext", "xccdf:fixtext", "cdf:fixtext",
             "fix", "xccdf:fix", "cdf:fix":
            if currentRule != nil {
                currentRule?.fixText = text
            }
            inFixText = false

        case "Rule", "xccdf:Rule", "cdf:Rule":
            if var rule = currentRule, !rule.title.isEmpty {
                rule.level = currentProfileLevel
                rules.append(rule)
            }
            currentRule = nil

        default:
            break
        }
    }

    // MARK: - YAML Generation

    private func generateYAML(rules: [ParsedRule], name: String, platform: String) -> String {
        var yaml = """
        name: "\(name)"
        version: "1.0.0"
        platform: "\(platform)"
        description: "Imported from XCCDF benchmark file."

        checks:
        """

        for (index, rule) in rules.enumerated() {
            let id = simplifyID(rule.id, index: index)
            let category = guessCategory(from: rule.title)
            let command = rule.checkContent.isEmpty ? "echo 'MANUAL: check not automated'" : rule.checkContent

            yaml += """

              - id: "\(id)"
                title: "\(escapeYAML(rule.title))"
                description: "\(escapeYAML(rule.description))"
                category: "\(category)"
                level: \(rule.level)
                scored: \(rule.scored)
                audit:
                  command: |
            \(indentCommand(command, spaces: 8))
                  match:
                    type: "contains"
                    value: "PASS"
            """

            if !rule.fixText.isEmpty {
                yaml += "        remediation: \"\(escapeYAML(rule.fixText))\"\n"
            }

            yaml += "        frameworks: []\n"
        }

        return yaml
    }

    private func simplifyID(_ raw: String, index: Int) -> String {
        // Try to extract a numeric ID like "1.1.1" from the XCCDF rule ID
        let pattern = #"(\d+(?:\.\d+)+)"#
        if let match = raw.range(of: pattern, options: .regularExpression) {
            return String(raw[match])
        }
        return "\(index + 1)"
    }

    private func guessCategory(from title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("firewall") || lower.contains("sharing") || lower.contains("remote") ||
           lower.contains("airdrop") || lower.contains("airplay") || lower.contains("bluetooth") {
            return "firewall_sharing"
        }
        if lower.contains("update") || lower.contains("patch") || lower.contains("software") {
            return "updates"
        }
        if lower.contains("filevault") || lower.contains("gatekeeper") || lower.contains("sip") ||
           lower.contains("integrity") || lower.contains("boot") || lower.contains("encrypt") {
            return "system_integrity"
        }
        return "access_security"
    }

    private func escapeYAML(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
    }

    private func indentCommand(_ command: String, spaces: Int) -> String {
        let indent = String(repeating: " ", count: spaces)
        return command.components(separatedBy: "\n")
            .map { indent + $0 }
            .joined(separator: "\n")
    }
}
