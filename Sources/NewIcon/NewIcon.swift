import ArgumentParser

@main
struct NewIcon: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "new-icon",
        abstract: "macOS icon customization",
        subcommands: [TextCommand.self, ResetCommand.self, EditCommand.self]
    )
}
