import Foundation

typealias Swap = (pid: String, size: Int, cmd: String)

func chopNull(_ s: String) -> String {
    /* var ss = s.last == "\0" ? s.dropLast() : s */
    /* return ss.map { $0 == "\0" ? " " : $0 } */
    let c1 = s.characters
    let c2 = c1.last == "\0" ? c1.dropLast() : c1
    let c3 = c2.map { $0 == "\0" ? " " : $0 }
    return String(c3)
}

func filesize(_ size: Int) -> String {
    let units = ["KiB", "MiB", "GiB", "TiB"]
    var left = Double(size)
    var unit = -1
    while left > 1100.0 && unit < 3 {
        left /= 1024.0
        unit += 1
    }
    if unit == -1 {
        return "\(size)B"
    } else {
        return String(format: "%.1f%@", left, units[unit])
    }
}

func readDir(_ dir: String) -> [String]? {
    let manager = FileManager.default
    do {
        let files = try manager.contentsOfDirectory(atPath: dir)
        return files
    } catch {
        return nil
    }
}

func readFile(_ path: String) -> [String]? {
    do {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        return content.components(separatedBy: "\n")
    } catch {
        return nil
    }
}

func getCommFor(_ pid: String) -> String {
    let cmdline = "/proc/\(pid)/cmdline"
    if let content = readFile(cmdline) {
        if content.isEmpty {
            return ""
        } else {
            return chopNull(content[0])
        }
    } else {
        return ""
    }
}

func getSwapFor(_ pid: String) -> Swap {
    let smaps = "/proc/\(pid)/smaps"
    if let content = readFile(smaps) {
        let size = content
            .filter { $0.hasPrefix("Swap:") }
            .map { line in
                let size = line.trimmingCharacters(in: CharacterSet(charactersIn: "Swap: kB"))
                return Int(size) ?? 0
            }
            .reduce(0, +)
        return (pid, size * 1024, getCommFor(pid))
    } else {
        return (pid, 0, "")
    }
}

func getSwaps() -> [Swap] {
    if let files = readDir("/proc") {
        return files
            .filter { "0" ... "9" ~= $0 }
            .map(getSwapFor)
            .filter { $0.size != 0 }
            .sorted { $0.size > $1.size }
    } else {
        return []
    }
}

func main() {
    func pad(_ s: String, _ len: Int) -> String {
        let ss = String(repeating: " ", count: len) + s
        return ss[ss.index(ss.endIndex, offsetBy: -len) ..< ss.endIndex]
    }

    print("\(pad("PID", 5)) \(pad("SWAP", 9)) COMMAND")
    let swaps = getSwaps()
    var total = 0
    for swap in swaps {
        total += swap.size
        print("\(pad(swap.pid, 5)) \(pad(filesize(swap.size), 9)) \(swap.cmd)")
    }
    print("Total: \(pad(filesize(total), 8))")
}

