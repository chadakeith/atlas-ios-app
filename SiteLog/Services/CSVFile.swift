import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// Lets a CSV string flow straight into `ShareLink` as a named .csv attachment.
struct CSVFile: Transferable {
    let fileName: String
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { file in
            Data(file.text.utf8)
        }
        .suggestedFileName { $0.fileName }
    }
}
