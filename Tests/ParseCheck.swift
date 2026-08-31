// Standalone check for the timer's time parsing:
//   swiftc -o /tmp/parsecheck Sources/Notchii/Models/FocusTimer.swift Tests/ParseCheck.swift && /tmp/parsecheck
import Foundation
let cases: [(String, TimeInterval?)] = [
    ("5", 300), ("25", 1500), ("5:30", 330), ("0:45", 45), ("1:05", 65),
    ("  7  ", 420), ("25:005", nil), ("5:75", nil), ("abc", nil), ("", nil),
    ("0", nil), ("0:00", nil), ("1:2:3", nil), (":30", 30), ("10:00", 600),
]
var failures = 0
for (input, expected) in cases {
    let got = FocusTimer.parse(input)
    let ok = got == expected
    if !ok { failures += 1 }
    print("\(ok ? "ok  " : "FAIL") parse(\"\(input)\") -> \(String(describing: got)), expected \(String(describing: expected))")
}
print(failures == 0 ? "all passed" : "\(failures) FAILED")
