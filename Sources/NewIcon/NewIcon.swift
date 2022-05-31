import ArgumentParser

@main
struct NewIcon: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "new-icon",
        abstract: "macOS icon customization",
        subcommands: [
            TextCommand.self,
            ResetCommand.self,
            TemplateCommand.self,
        ]
    )
}
