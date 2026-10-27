import AVFoundation
import Foundation
import Testing
@testable import AetherEngine

/// Snug PL4: the native select suspends (pre-fill, 100 ms deselect gap, 700 ms retries), so it must
/// re-check that its track is still wanted on the same item, and a select refused for an empty
/// rendition retries when the first cue lands.
@MainActor
struct NativeSubtitleSelectRecheckTests {

    @Test("a select proceeds only for the last requested ordinal on the same item")
    func stillWanted() {
        let item = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/a.mp4"))
        let other = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/b.mp4"))
        #expect(AetherEngine.nativeSubtitleStillWanted(wanted: 1, ordinal: 1, current: item, item: item))
        #expect(!AetherEngine.nativeSubtitleStillWanted(wanted: nil, ordinal: 1, current: item, item: item))
        #expect(!AetherEngine.nativeSubtitleStillWanted(wanted: 0, ordinal: 1, current: item, item: item))
        #expect(!AetherEngine.nativeSubtitleStillWanted(wanted: 1, ordinal: 1, current: other, item: item))
        #expect(!AetherEngine.nativeSubtitleStillWanted(wanted: 1, ordinal: 1, current: nil, item: item))
    }

    @Test("the cue wait resolves when a cue lands and gives up on timeout")
    func awaitCues() async {
        let store = NativeSubtitleCueStore()
        let late = Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            store.appendCues([SubtitleCue(id: 1, startTime: 0, endTime: 1, body: .text("t"))])
        }
        #expect(await AetherEngine.awaitNativeSubtitleCues(in: store, timeout: 5, interval: 20_000_000))
        await late.value
        #expect(await AetherEngine.awaitNativeSubtitleCues(in: NativeSubtitleCueStore(), timeout: 0.1, interval: 20_000_000) == false)
    }
}
