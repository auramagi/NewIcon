//
//  MachO.swift
//
//
//  Created by Mikhail Apurin on 08.05.2022.
//

import Foundation
import MachO

struct MachImage {
    let header: mach_header
    let baseAddress: UnsafeRawPointer
    let slide: Int
    let name: String
    let symbols: Set<SwiftSymbol>
    
    init?(name: String) {
        guard let i = (0..<_dyld_image_count()).first(where: { String(cString: _dyld_get_image_name($0)) == name })
        else { return nil }
        
        self.init(i: i)
    }
    
    init?(i: UInt32) {
        guard let header = _dyld_get_image_header(i),
              let name = _dyld_get_image_name(i)
        else { return nil }
        
        self.init(
            header: header.pointee,
            baseAddress: UnsafeRawPointer(header),
            slide: _dyld_get_image_vmaddr_slide(i),
            name: String(cString: name)
        )
    }
    
    init?(header: mach_header, baseAddress: UnsafeRawPointer, slide: Int, name: String) {
        var loadCommands: [UnsafePointer<load_command>] = []
        var loadCommandPtr = baseAddress.advanced(by: MemoryLayout<mach_header_64>.size)
        for _ in (0..<header.ncmds) {
            let loadCommand = loadCommandPtr.load(as: load_command.self)
            loadCommands.append(loadCommandPtr.assumingMemoryBound(to: load_command.self))
            loadCommandPtr = loadCommandPtr.advanced(by: Int(loadCommand.cmdsize))
        }
        let segments = loadCommands
            .filter { $0.pointee.cmd == LC_SEGMENT_64 }
            .map { UnsafeRawPointer($0).load(as: segment_command_64.self) }
        
        guard let symbolTableCommand = loadCommands.first(where: { $0.pointee.cmd == LC_SYMTAB }).map({ UnsafeRawPointer($0).load(as: symtab_command.self) }),
              let linkEditorSegment = segments.first(where: { $0.name == SEG_LINKEDIT }),
              let offset = UnsafeRawPointer(bitPattern: slide + Int(linkEditorSegment.vmaddr) - Int(linkEditorSegment.fileoff))
        else { return nil }
        
        let symbols = UnsafeBufferPointer<nlist_64>(
            start: offset.advanced(by: Int(symbolTableCommand.symoff)).assumingMemoryBound(to: nlist_64.self),
            count: Int(symbolTableCommand.nsyms)
        )
        let symbolStringsPtr = offset.advanced(by: Int(symbolTableCommand.stroff)).assumingMemoryBound(to: CChar.self)
        
        self.header = header
        self.baseAddress = baseAddress
        self.slide = slide
        self.name = name
        self.symbols = symbols
            .compactMap { SwiftSymbol(list: $0, strings: symbolStringsPtr, slide: slide, onlySwift: true) }
            .toSet()
    }
}

struct SwiftSymbol: Hashable {
    let name: String
    let address: UnsafeRawPointer
    
    init?(list: nlist_64, strings: UnsafePointer<CChar>, slide: Int, onlySwift: Bool) {
        guard Int32(list.n_type) & N_STAB == 0,
              Int32(list.n_type) & N_TYPE == N_SECT,
              list.n_sect != NO_SECT,
              case let name = String(cString: strings.advanced(by: Int(list.n_un.n_strx))),
              !name.isEmpty,
              !onlySwift || name.hasPrefix("_$s"),
              let address = UnsafeRawPointer(bitPattern: Int(list.n_value) + slide)
        else { return nil }
        
        self.name = name
        self.address = address
    }
}

extension segment_command_64 {
    var name: String {
        let n = segname
        var cString = [n.0, n.1, n.2, n.3, n.4, n.5, n.6, n.7, n.8, n.9, n.10, n.11, n.12, n.13, n.14, n.15]
        return String(cString: &cString)
    }
}
