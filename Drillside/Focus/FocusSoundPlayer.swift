import AVFoundation
import Foundation

enum FocusSound: String, CaseIterable, Identifiable {
    case off, rain, waves, campfire, brown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off: return "Off"
        case .rain: return "Rain"
        case .waves: return "Ocean waves"
        case .campfire: return "Campfire"
        case .brown: return "Brown noise"
        }
    }

    var icon: String {
        switch self {
        case .off: return "speaker.slash"
        case .rain: return "cloud.rain"
        case .waves: return "water.waves"
        case .campfire: return "flame"
        case .brown: return "waveform"
        }
    }
}

/// Real-time sample generator. Everything is procedural, so no audio assets are bundled.
/// Lives on the audio render thread; the main thread only flips a few scalar fields.
final class SoundSynth {
    var kind: FocusSound = .off
    var targetGain: Float = 0
    var chimeGain: Float = 0.6
    var chimeT: Double = -1
    var sampleRate: Double = 44_100

    private var gain: Float = 0
    private var rng: UInt32 = 0x2545_F491
    private var brown: Float = 0
    private var lp: Float = 0
    private var lp2: Float = 0
    private var drop: Float = 0
    private var crackle: Float = 0
    private var t: Double = 0

    @inline(__always) private func white() -> Float {
        rng ^= rng << 13
        rng ^= rng >> 17
        rng ^= rng << 5
        return Float(Int32(bitPattern: rng)) / Float(Int32.max)
    }

    func next() -> Float {
        let dt = 1 / sampleRate
        t += dt
        gain += (targetGain - gain) * 0.0004
        let w = white()
        var s: Float = 0
        switch kind {
        case .off:
            s = 0
        case .brown:
            brown = (brown + 0.02 * w) / 1.02
            s = brown * 3.5
        case .rain:
            lp += 0.25 * (w - lp)
            let hiss = (w - lp) * 0.35
            if white() > 0.9992 { drop = 0.4 + 0.6 * abs(white()) }
            drop *= 0.996
            lp2 += 0.08 * (white() * drop - lp2)
            s = hiss * 0.6 + lp2 * 1.4
        case .waves:
            brown = (brown + 0.02 * w) / 1.02
            lp += 0.05 * (w - lp)
            let lfo = 0.5 + 0.5 * sin(2 * Double.pi * 0.075 * t)
            let amp = Float(0.12 + 0.88 * lfo * lfo)
            s = (brown * 3 + lp * 0.6) * amp
        case .campfire:
            brown = (brown + 0.02 * w) / 1.02
            s = brown * 2.2
            if white() > 0.99955 { crackle = 0.6 + 0.4 * abs(white()) }
            if crackle > 0.001 {
                s += white() * crackle * 0.6
                crackle *= 0.982
            }
        }
        s *= gain
        if chimeT >= 0 {
            let env = exp(-chimeT * 2.6)
            let tone = 0.18 * sin(2 * Double.pi * 880 * chimeT) + 0.10 * sin(2 * Double.pi * 1320 * chimeT) + 0.05 * sin(2 * Double.pi * 1760 * chimeT)
            s += Float(env * tone) * chimeGain
            chimeT += dt
            if chimeT > 2.5 { chimeT = -1 }
        }
        return max(-1, min(1, s))
    }
}

/// Plays ambient focus sounds and the phase-change chime through a tiny AVAudioEngine graph.
/// Uses the `.playback` category mixed with other audio, so music apps keep playing.
@MainActor
final class FocusSoundPlayer {
    static let shared = FocusSoundPlayer()

    private var engine: AVAudioEngine?
    private let synth = SoundSynth()
    private var stopTask: Task<Void, Never>?
    private(set) var current: FocusSound = .off

    func play(_ kind: FocusSound, volume: Double) {
        current = kind
        synth.kind = kind
        synth.targetGain = kind == .off ? 0 : Float(max(0, min(1, volume)))
        if kind == .off {
            scheduleStop(after: 0.6)
        } else {
            stopTask?.cancel()
            startEngine()
        }
    }

    func setVolume(_ volume: Double) {
        if current != .off { synth.targetGain = Float(max(0, min(1, volume))) }
    }

    func stop() {
        current = .off
        synth.targetGain = 0
        scheduleStop(after: 0.6)
    }

    func chime(volume: Double) {
        stopTask?.cancel()
        startEngine()
        synth.chimeGain = Float(max(0.35, min(1, volume)))
        synth.chimeT = 0
        if current == .off { scheduleStop(after: 3) }
    }

    private func scheduleStop(after seconds: Double) {
        stopTask?.cancel()
        stopTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.engine?.stop()
            self?.engine = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private func startEngine() {
        if let e = engine, e.isRunning { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        let e = AVAudioEngine()
        let outRate = e.outputNode.outputFormat(forBus: 0).sampleRate
        synth.sampleRate = outRate > 0 ? outRate : 44_100
        guard let mono = AVAudioFormat(standardFormatWithSampleRate: synth.sampleRate, channels: 1) else { return }
        let gen = synth
        let node = AVAudioSourceNode(format: mono) { _, _, frameCount, audioBufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let v = gen.next()
                for buffer in buffers {
                    let out = UnsafeMutableBufferPointer<Float>(buffer)
                    if frame < out.count { out[frame] = v }
                }
            }
            return noErr
        }
        e.attach(node)
        e.connect(node, to: e.mainMixerNode, format: mono)
        do {
            try e.start()
            engine = e
        } catch {
            engine = nil
        }
    }
}
