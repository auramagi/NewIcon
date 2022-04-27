# NewIcon

A command line tool to overlay text over file and directory icons on macOS.

### Installation

Install using [Mint](https://github.com/yonaskolb/Mint).
```sh
$ mint install auramagi/NewIcon
```

### Usage

- Overlay text over the original icon for a file or directory
  ```sh
  $ new-icon text FILE TEXT
  
  # Add version number to Xcode app icon
  $ new-icon text /Applications/Xcode.app 13.3.1
  ```

- Revert file or directory icon to the original
  ```sh
  $ new-icon reset FILE
  ```

Run `json5tojson --help` to see all options.
