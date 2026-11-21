import SwiftUI
import AVFoundation
import UIKit

private let ink = Color(red: 0.045, green: 0.055, blue: 0.105)
private let glow = Color(red: 0.56, green: 0.39, blue: 1.0)
private let aqua = Color(red: 0.31, green: 0.95, blue: 0.86)

@main
struct MysteryFiveApp: App {
    var body: some Scene {
        WindowGroup {
            MysteryHome()
                .preferredColorScheme(.dark)
        }
    }
}

struct MysteryHome: View {
    @State private var selected: Int?
    @State private var opened: Set<Int> = Set(UserDefaults.standard.array(forKey: "openedDoors") as? [Int] ?? [])
    private let symbols = ["✦","◈","⌘","◎","❖"]
    private let shades: [Color] = [.purple,.cyan,.pink,.orange,.green]
    var body: some View {
        NavigationView {
            ZStack {
                ink.ignoresSafeArea()
                VStack(spacing: 12) {
                    HStack {
                        Text("UNKNOWN_05").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(aqua)
                        Spacer()
                        Text("OFFLINE // ACTIVE").font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
                    }.padding(.horizontal, 24).padding(.top, 16)
                    Spacer(minLength: 5)
                    Text("THE BOX").font(.system(size: 46, weight: .black, design: .rounded)).tracking(3)
                    Text("five doors • no instructions").font(.system(size: 13, design: .monospaced)).foregroundColor(.gray)
                    Text("TAP A DOOR TO DISCOVER WHAT'S INSIDE")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(aqua).padding(.top, 8)
                    VStack(spacing: 14) {
                        HStack(spacing: 14) {
                            door(0); door(1)
                        }
                        HStack(spacing: 14) {
                            door(2); door(3)
                        }
                        door(4).frame(maxWidth: 170)
                    }.padding(.horizontal, 22).padding(.top, 15)
                    Spacer(minLength: 8)
                    Text("DISCOVERED: \(opened.count) / 5")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(aqua)
                    HStack(spacing: 7) {
                        ForEach(0..<5) { i in
                            Capsule().fill(opened.contains(i) ? aqua : Color.white.opacity(0.15))
                                .frame(width: 26, height: 5)
                        }
                    }.padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: Binding(
                get: { selected.map { DoorID(value: $0) } },
                set: { selected = $0?.value }
            )) { value in
                DoorScreen(number: value.value, close: { selected = nil })
                    .preferredColorScheme(.dark)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    private func door(_ i: Int) -> some View {
        Button {
            opened.insert(i)
            UserDefaults.standard.set(Array(opened), forKey: "openedDoors")
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            selected = i
        } label: {
            VStack(spacing: 10) {
                Text(symbols[i]).font(.system(size: 43, weight: .thin))
                    .foregroundColor(shades[i])
                Text(String(format: "DOOR %02d", i + 1))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(opened.contains(i) ? "DISCOVERED" : "???")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(opened.contains(i) ? aqua : .gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 132)
            .background(Color.white.opacity(0.055))
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(shades[i].opacity(0.6), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
private struct DoorID: Identifiable {
    let value: Int
    var id: Int { value }
}

struct DoorScreen: View {
    let number: Int
    let close: () -> Void
    var body: some View {
        NavigationView {
            ZStack {
                ink.ignoresSafeArea()
                Group {
                    switch number {
                    case 0: PixelRoom()
                    case 1: VoiceRoom()
                    case 2: ReflexRoom()
                    case 3: CipherRoom()
                    default: MemoryRoom()
                    }
                }.padding(.horizontal, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("← BOX") { close() }.foregroundColor(aqua)
                }
                ToolbarItem(placement: .principal) {
                    Text(String(format: "CHAMBER %02d", number + 1))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct PixelRoom: View {
    @State private var pixels: [Int] = {
        let stored = UserDefaults.standard.array(forKey: "pixels12") as? [Int]
        return stored?.count == 144 ? stored! : Array(repeating: 0, count: 144)
    }()
    @State private var color = 1
    private let palette: [Color] = [ink, .white, .cyan, .pink, .yellow, .purple, .green, .orange]
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("PIXEL DIMENSION").font(.system(size: 23, weight: .black, design: .rounded)).padding(.top, 18)
                Text("Draw something impossible.").foregroundColor(.gray)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 12), spacing: 2) {
                    ForEach(0..<144, id: \.self) { i in
                        Button {
                            pixels[i] = color
                            UserDefaults.standard.set(pixels, forKey: "pixels12")
                        } label: {
                            Rectangle()
                                .fill(palette[pixels[i]])
                                .aspectRatio(1, contentMode: .fit)
                                .cornerRadius(2)
                        }.buttonStyle(PlainButtonStyle())
                    }
                }.padding(5).background(Color.white.opacity(0.09)).cornerRadius(12)
                HStack(spacing: 10) {
                    ForEach(0..<8, id: \.self) { i in
                        Button { color = i } label: {
                            Circle().fill(palette[i])
                                .frame(width: 30, height: 30)
                                .overlay(Circle().stroke(color == i ? .white : .clear, lineWidth: 3))
                        }
                    }
                }
                HStack {
                    Button("CLEAR") {
                        pixels = Array(repeating: 0, count: 144)
                        UserDefaults.standard.set(pixels, forKey: "pixels12")
                    }
                    Spacer()
                    Text("AUTO SAVED").foregroundColor(aqua)
                }.font(.system(size: 11, weight: .bold, design: .monospaced)).padding(.top, 10)
            }.padding(.bottom, 30)
        }
    }
}

final class Speaker: ObservableObject {
    private let synth = AVSpeechSynthesizer()
    func say(_ message: String, speed: Float, pitch: Float) {
        synth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: message)
        utterance.rate = speed
        utterance.pitchMultiplier = pitch
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(utterance)
    }
    func stop() { synth.stopSpeaking(at: .immediate) }
}
struct VoiceRoom: View {
    @StateObject private var speaker = Speaker()
    @State private var phrase = "I have escaped the mystery box!"
    @State private var speed = 0.48
    @State private var pitch = 1.0
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("VOICE MUTATOR").font(.system(size: 26, weight: .black)).padding(.top, 22)
                Text("Make the machine speak.").foregroundColor(.gray)
                TextEditor(text: $phrase).frame(height: 120).padding(9)
                    .background(Color.white.opacity(0.06)).cornerRadius(14)
                Text("SPEED").font(.system(size: 12, design: .monospaced)).foregroundColor(aqua)
                Slider(value: $speed, in: 0.1...0.65).accentColor(aqua)
                Text("PITCH").font(.system(size: 12, design: .monospaced)).foregroundColor(aqua)
                Slider(value: $pitch, in: 0.5...2).accentColor(aqua)
                Button {
                    speaker.say(phrase, speed: Float(speed), pitch: Float(pitch))
                } label: {
                    Label("ACTIVATE VOICE", systemImage: "waveform")
                        .frame(maxWidth: .infinity).padding(17)
                        .background(glow).cornerRadius(14)
                }.disabled(phrase.isEmpty)
                Button("STOP AUDIO") { speaker.stop() }
                    .foregroundColor(aqua)
                Text("Uses the iPhone's offline speech engine. Turn up your volume.")
                    .font(.footnote).foregroundColor(.gray)
            }
        }
    }
}

struct ReflexRoom: View {
    @State private var stage = 0
    @State private var started: Date?
    @State private var result = "TAP START"
    @State private var best: Int = UserDefaults.standard.integer(forKey: "bestReflex")
    @State private var ticket = 0
    var body: some View {
        VStack(spacing: 20) {
            Text("REFLEX PROTOCOL").font(.system(size: 25, weight: .black)).padding(.top, 20)
            Text("Wait for green. Tap instantly.").foregroundColor(.gray)
            Spacer()
            Button {
                switch stage {
                case 0, 3:
                    ticket += 1
                    let current = ticket
                    stage = 1
                    result = "WAIT..."
                    let delay = Double.random(in: 1.8...4.5)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        if ticket == current && stage == 1 {
                            started = Date()
                            stage = 2
                            result = "TAP!"
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                    }
                case 1:
                    ticket += 1
                    stage = 3
                    result = "TOO EARLY!"
                case 2:
                    let ms = Int((Date().timeIntervalSince(started ?? Date())) * 1000)
                    result = "\(ms) ms"
                    if best == 0 || ms < best {
                        best = ms
                        UserDefaults.standard.set(best, forKey: "bestReflex")
                    }
                    stage = 3
                default: break
                }
            } label: {
                VStack(spacing: 15) {
                    Text(stage == 0 || stage == 3 ? "▶" : stage == 1 ? "…" : "⚡")
                        .font(.system(size: 70))
                    Text(result).font(.system(size: 34, weight: .black, design: .monospaced))
                    Text(stage == 3 ? "TAP TO RETRY" : "TOUCH THE ZONE")
                        .font(.system(size: 12, design: .monospaced))
                }.foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 310)
                    .background(stage == 1 ? Color.red.opacity(0.8) :
                                stage == 2 ? Color.green.opacity(0.75) : glow.opacity(0.6))
                    .cornerRadius(28)
            }
            Spacer()
            Text(best == 0 ? "NO RECORD YET" : "BEST: \(best) ms")
                .font(.system(size: 17, weight: .bold, design: .monospaced))
                .foregroundColor(aqua).padding(.bottom, 38)
        }
    }
}

func shiftCipher(_ text: String, by steps: Int) -> String {
    let normalized = ((steps % 26) + 26) % 26
    return String(text.unicodeScalars.map { scalar -> Character in
        let n = Int(scalar.value)
        if n >= 65 && n <= 90 {
            return Character(UnicodeScalar(65 + (n - 65 + normalized) % 26)!)
        }
        if n >= 97 && n <= 122 {
            return Character(UnicodeScalar(97 + (n - 97 + normalized) % 26)!)
        }
        return Character(scalar)
    })
}
struct CipherRoom: View {
    @State private var input = ""
    @State private var rotate = 7.0
    @State private var reverse = false
    @State private var copied = false
    private var output: String { shiftCipher(input, by: reverse ? -Int(rotate) : Int(rotate)) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("SECRET SIGNAL").font(.system(size: 26, weight: .black)).padding(.top, 22)
                Text("Hide a message in plain sight.").foregroundColor(.gray)
                Text("INPUT").font(.system(size: 12, design: .monospaced)).foregroundColor(aqua)
                TextEditor(text: $input).frame(height: 110).padding(8)
                    .background(Color.white.opacity(0.07)).cornerRadius(12)
                Toggle("DECODE MODE", isOn: $reverse).tint(aqua)
                Text("KEY: \(Int(rotate))").font(.system(size: 12, design: .monospaced)).foregroundColor(aqua)
                Slider(value: $rotate, in: 1...25, step: 1).accentColor(glow)
                Text("RESULT").font(.system(size: 12, design: .monospaced)).foregroundColor(aqua)
                Text(output.isEmpty ? "Your secret appears here…" : output)
                    .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                    .padding(15).background(Color.white.opacity(0.07)).cornerRadius(12)
                    .textSelection(.enabled)
                Button {
                    UIPasteboard.general.string = output
                    copied = true
                } label: {
                    Label(copied ? "COPIED" : "COPY MESSAGE", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity).padding(15)
                        .background(glow).cornerRadius(14)
                }.disabled(output.isEmpty)
                Text("Hint: decoding requires the same key. This is a puzzle cipher, not secure encryption.")
                    .font(.footnote).foregroundColor(.gray)
            }
        }
    }
}

struct MemoryRoom: View {
    private let colors: [Color] = [.red, .blue, .green, .yellow]
    @State private var sequence: [Int] = []
    @State private var index = 0
    @State private var active: Int? = nil
    @State private var phase = 0
    @State private var status = "READY TO TEST YOUR MEMORY?"
    @State private var round = 0
    @State private var best = UserDefaults.standard.integer(forKey: "memoryHigh")
    @State private var runID = 0
    var body: some View {
        VStack(spacing: 24) {
            Text("ECHO MATRIX").font(.system(size: 26, weight: .black)).padding(.top, 20)
            Text(status).font(.system(size: 12, design: .monospaced))
                .foregroundColor(aqua).multilineTextAlignment(.center)
                .frame(height: 45)
            HStack {
                Text("ROUND \(round)")
                Spacer()
                Text("BEST \(best)")
            }.font(.system(size: 13, weight: .bold, design: .monospaced))
            Spacer()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(0..<4, id: \.self) { i in
                    Button { tap(i) } label: {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(colors[i].opacity(active == i ? 1 : 0.4))
                            .frame(height: 145)
                            .overlay(Text(["◆","●","▲","■"][i])
                                .font(.system(size: 40)).foregroundColor(.white))
                            .overlay(RoundedRectangle(cornerRadius: 25).stroke(colors[i], lineWidth: 2))
                    }.disabled(phase != 2)
                }
            }
            Spacer()
            Button {
                runID += 1
                sequence = []
                round = 0
                nextRound()
            } label: {
                Text(phase == 0 || phase == 3 ? "START NEW GAME" : "RESTART")
                    .frame(maxWidth: .infinity).padding(16).background(glow).cornerRadius(14)
            }.padding(.bottom, 28)
        }
    }
    private func nextRound() {
        sequence.append(Int.random(in: 0..<4))
        round = sequence.count
        index = 0
        phase = 1
        status = "WATCH CLOSELY…"
        let run = runID
        for (i, item) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.8 + 0.45) {
                guard run == runID else { return }
                active = item
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.8 + 0.95) {
                guard run == runID else { return }
                active = nil
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(sequence.count) * 0.8 + 0.55) {
            guard run == runID else { return }
            phase = 2
            status = "REPEAT THE PATTERN"
        }
    }
    private func tap(_ choice: Int) {
        guard phase == 2, index < sequence.count else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if choice != sequence[index] {
            phase = 3
            status = "SIGNAL LOST — TRY AGAIN"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        index += 1
        if index == sequence.count {
            phase = 1
            status = "CORRECT!"
            if round > best {
                best = round
                UserDefaults.standard.set(best, forKey: "memoryHigh")
            }
            let run = runID
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                guard run == runID else { return }
                nextRound()
            }
        }
    }
}
