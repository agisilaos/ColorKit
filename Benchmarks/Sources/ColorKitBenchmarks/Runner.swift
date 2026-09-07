import Foundation

@main
enum Runner {
    struct Result: Codable {
        let scenario: ScenarioDescription
        let cacheMode: CacheMode
        let samples: [Sample]
    }

    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data: Data
        if arguments == ["--list"] {
            data = try encoder.encode(scenarios().map(\.description))
        } else {
            #if DEBUG
                throw BenchmarkError.debugBuild
            #else
                guard arguments.count == 4,
                      let scenario = scenarios().first(where: { $0.description.id == arguments[0] }),
                      let mode = CacheMode(rawValue: arguments[1]),
                      let samples = Int(arguments[2]), let iterations = Int(arguments[3])
                else {
                    throw BenchmarkError.invalidArguments
                }
                data = try encoder.encode(Result(
                    scenario: scenario.description,
                    cacheMode: mode,
                    samples: scenario.run(mode, samples, iterations)
                ))
            #endif
        }
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data([10]))
    }
}
