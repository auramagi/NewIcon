import ArgumentParser

struct NewIcon: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "new-icon",
        abstract: "macOS icon customization",
        subcommands: [TextCommand.self, ResetCommand.self]
    )
}

NewIcon.main()
