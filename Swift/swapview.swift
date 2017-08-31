import Foundation

typealias Swap = (pid: String, size: Int, command: String)

func chopNull(_ s: String) -> String {
    let ss = s.last == "\0" ? String(s.dropLast()) : s
    return String(ss.map { $0 == "\0" ? " " : $0 })
}

func filesize(_ size: Int) -> String {
    if size <= 1100 {
        return "\(size)B"
    } else {
        let units = ["KiB", "MiB", "GiB", "TiB"]
        var left = Double(size)
        var unit = -1
        while left > 1100 && unit < 3 {
            left /= 1024
            unit += 1
        }
        return String(format: "%.1f\(units[unit])", left)
    }
}

func readFile(_ path: String) -> [String]? {
    let content = try? String(contentsOfFile: path, encoding: .utf8)
    return content?.components(separatedBy: "\n")
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
                let trim = CharacterSet(charactersIn: "Swap: kB")
                let size = line.trimmingCharacters(in: trim)
                return Int(size) ?? 0
            }
            .reduce(0, +)
        return (pid, size * 1024, getCommFor(pid))
    } else {
        return (pid, 0, "")
    }
}

func getSwaps() -> [Swap] {
    let manager = FileManager.default
    if let files = try? manager.contentsOfDirectory(atPath: "/proc") {
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

    func printSwapWithFormat(_ pid: String, _ size: String, _ command: String) {
        print("\(pad(pid, 5)) \(pad(size, 9)) \(command)")
    }

    printSwapWithFormat("PID", "SWAP", "COMMAND")
    let swaps = getSwaps()
    var total = 0
    for swap in swaps {
        total += swap.size
        printSwapWithFormat(swap.pid, filesize(swap.size), swap.command)
    }
    print("Total: \(pad(filesize(total), 8))")
}
