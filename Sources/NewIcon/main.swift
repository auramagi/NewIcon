import ArgumentParser

struct EveryIcon: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "everyicon",
        abstract: "macOS icon customization",
        subcommands: [TextCommand.self, ResetCommand.self]
    )
}

EveryIcon.main()
