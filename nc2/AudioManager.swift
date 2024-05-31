import AVFoundation

class AudioManager {
    var backgroundMusicPlayer: AVAudioPlayer?
    let humanSounds = ["humanSound1", "humanSound2", "humanSound3"]
    var audioPlayer: AVAudioPlayer?

    init() {
        playBackgroundMusic()
    }

    func playBackgroundMusic() {
        if let musicURL = Bundle.main.url(forResource: "backgroundMusic", withExtension: "mp3") {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
                backgroundMusicPlayer?.numberOfLoops = -1
                backgroundMusicPlayer?.play()
            } catch {
                print("Error playing background music: \(error.localizedDescription)")
            }
        }
    }

    func playRandomHumanSound() {
        if let randomSoundName = humanSounds.randomElement(),
           let soundURL = Bundle.main.url(forResource: randomSoundName, withExtension: "mp3") {
            playSound(from: soundURL)
        }
    }

    func playSurprisedHumanSound() {
        if let soundURL = Bundle.main.url(forResource: "humanSoundSurprised", withExtension: "mp3") {
            playSound(from: soundURL)
        }
    }

    private func playSound(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Could not load sound file: \(error)")
        }
    }
}
