//
//  ContentView.swift
//  WordGarden
//
//  Created by Linda Samsinger on 21.03.2025.
//

import SwiftUI
import AVFAudio

struct ContentView: View {
    private static let maximumGuesses = 8 // need to refer to this constant with self.maximumGuesses
    
    @State private var wordsGuessed = 0
    @State private var wordsMissed = 0
    
    @State private var gameStatusMessage = "How Many Guesses to Uncover the Hidden Word?"
    @State private var currentWordIndex = 0
    @State private var wordToGuess = ""
    @State private var revealedWord = ""
    @State private var lettersGuessed = ""
    @State private var guessedLetter = ""
    @State private var imageName = "flower8"
    @State private var playAgainHidden = true
    @State private var guessesRemaining = maximumGuesses
    @State private var playAgainButtonLabel = "Another Word?"
    @State private var audioPlayer : AVAudioPlayer!
    @FocusState private var textFieldIsFocused: Bool
    private let wordsToGuess = ["SWIFT", "BANANA", "CHERRY"]
    var body: some View {
        VStack {
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Words Guessed: \(wordsGuessed)")
                    Text("Words Missed: \(wordsMissed)")
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Words to Guess: \(wordsToGuess.count - (wordsGuessed + wordsMissed))")
                    Text("Words in Game: \(wordsToGuess.count)")
                }
            }
            .padding(.horizontal)
            Spacer()
            Text(gameStatusMessage)
                .font(.title)
                .multilineTextAlignment(.center)
                .frame(height: 80)
                .minimumScaleFactor(0.5)
                .padding()
            //TODO: switch to wordsToGuess[currentWordIndex]
            Text(revealedWord)
                .font(.title)
            
            
            if playAgainHidden {
                HStack {
                    TextField("", text: $guessedLetter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 30)
                        .overlay {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.gray, lineWidth: 2)
                        }
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done) // done button on the keyboard
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .onChange(of: guessedLetter) {
                            guessedLetter = guessedLetter.trimmingCharacters(in: .letters.inverted)
                            guard let lastChar = guessedLetter.last else {
                                return
                            }
                           
                            guessedLetter = String(lastChar).uppercased()
                        }
                        .focused($textFieldIsFocused) // after keyboard input the keyboard is dismissed when the button is pressed
                        .onSubmit {
                            guard guessedLetter != "" else { return }
                            guessALetter()
                            updateGamePlay()
                        }
                    Button("Guess a Letter") {
                        guessALetter()
                        updateGamePlay()
                    }
                    .buttonStyle(.bordered)
                    .tint(.mint)
                    .disabled(guessedLetter.isEmpty)
                }
            } else {
                Button(playAgainButtonLabel) {
                    //if all the words have been guessed
                    if currentWordIndex == wordsToGuess.count {
                        currentWordIndex = 0
                        wordsGuessed = 0
                        wordsMissed = 0
                        playAgainButtonLabel = "Another word?"
                    }
                    wordToGuess = wordsToGuess[currentWordIndex]
                    revealedWord = "_" + String(repeating: " _", count: wordToGuess.count-1)
                    lettersGuessed = ""
                    guessesRemaining = Self.maximumGuesses // instead of Self.maximum Guesses you can use ContentView.maximumGuesses
                    imageName = "flower\(guessesRemaining)"
                    gameStatusMessage = "How Many Guesses to Uncover the Hidden Word?"
                    playAgainHidden = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
                
            }
            
            
            Spacer()
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .animation(.easeIn(duration: 0.75), value: imageName)
        }
    
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            wordToGuess = wordsToGuess[currentWordIndex]
            revealedWord = "_" + String(repeating: " _", count: wordToGuess.count-1)
        } // dynamic
    }
    
    
    func guessALetter() {
        textFieldIsFocused = false
         
        lettersGuessed = lettersGuessed + guessedLetter
        revealedWord = wordToGuess.map {
            letter in lettersGuessed.contains(letter) ? "\(letter)" : "_"
        }.joined(separator: " ")
        
    }
    
    func updateGamePlay() {
        //TODO: Redo this with locallizedStringKey & inflect
       
        if !wordToGuess.contains(guessedLetter) {
            guessesRemaining -= 1
            // wilt image - animate crumbling leaf and play the incorrect sound
            imageName = "wilt\(guessesRemaining)"
            playSound(soundName: "incorrect")
            //delay change to flower image after wilt animation is done
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                imageName = "flower\(guessesRemaining)"
            }
            
        }  else {
            playSound(soundName: "correct")
        }
        guessedLetter = ""
        
        //When Do We Play Another Word
        if !revealedWord.contains("_") { // Guessed when no "_" in revealed word
            gameStatusMessage = "You Guessed It! It Took You \(lettersGuessed.count) Guesses to Guess the Word."
            playSound(soundName: "word-guessed")
            wordsGuessed += 1
            currentWordIndex += 1
            playAgainHidden = false
            
        } else if guessesRemaining == 0 { //Word missed
            gameStatusMessage = "So Sorry, You Are All Out of Guesses"
            playSound(soundName: "word-not-guessed")
            wordsMissed += 1
            currentWordIndex += 1
            playAgainHidden = false
            
        } else { // Keep guessing
            gameStatusMessage = "You have made \(lettersGuessed.count) guess\(lettersGuessed.count == 1 ? "" : "es") so far."
        }
        
        if currentWordIndex == wordsToGuess.count {
            playAgainButtonLabel = "Restart Game?"
            gameStatusMessage = "\nYou've Tried All of the Words. Restart from the beginning?"
        }
    }
    func playSound(soundName: String) {
        if audioPlayer != nil && audioPlayer.isPlaying {
            audioPlayer.stop()
        }
        // guard let for variables
        guard let soundFile = NSDataAsset(name: soundName) else {
            print("😡 Error loading \(soundName) creating sound")
            return
        }
        // do-try-catch if an object throws an error
        do {
            audioPlayer = try AVAudioPlayer(data: soundFile.data)
            audioPlayer.play()
        } catch {
            print("😡 Error \(error.localizedDescription) from creating the Audio Player")
        }
    }
}

#Preview {
    ContentView()
}
