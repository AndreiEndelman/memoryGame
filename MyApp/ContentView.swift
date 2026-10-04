import SwiftUI

struct ContentView: View {
    private let allSymbols = ["🐶", "🐱", "🦊", "🐻", "🐼", "🦁", "🐸", "🐵", "🐙", "🐧", "🦄", "🐝"]
    private let pairOptions = [2, 4, 6, 8]

    @State private var selectedPairs = 4
    @State private var cards: [Card] = []
    @State private var firstFlippedIndex: Int?
    @State private var lockBoard = false
    @State private var moves = 0

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.15), Color.red.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    header

                    Picker("Pairs", selection: $selectedPairs) {
                        ForEach(pairOptions, id: \.self) { count in
                            Text("\(count) pairs").tag(count)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedPairs) { _, _ in
                        resetGame()
                    }

                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 10)], spacing: 10) {
                            ForEach(cards) { card in
                                CardView(card: card)
                                    .onTapGesture {
                                        handleTap(on: card)
                                    }
                            }
                        }
                        .padding(.vertical, 6)
                    }

                    Button("Reset Game") {
                        resetGame()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
                .padding()
            }
            .navigationTitle("Memory Game")
        }
        .onAppear {
            if cards.isEmpty {
                resetGame()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Moves: \(moves)")
                .font(.headline)
            Spacer()
            Text("Matches: \(cards.filter { $0.isMatched }.count / 2)/\(selectedPairs)")
                .font(.headline)
        }
    }

    private func resetGame() {
        let symbols = Array(allSymbols.shuffled().prefix(selectedPairs))
        var newCards: [Card] = []

        for symbol in symbols {
            newCards.append(Card(symbol: symbol))
            newCards.append(Card(symbol: symbol))
        }

        cards = newCards.shuffled()
        firstFlippedIndex = nil
        lockBoard = false
        moves = 0
    }

    private func handleTap(on card: Card) {
        guard !lockBoard else { return }
        guard let tappedIndex = cards.firstIndex(where: { $0.id == card.id }) else { return }
        guard !cards[tappedIndex].isFaceUp, !cards[tappedIndex].isMatched else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            cards[tappedIndex].isFaceUp = true
        }

        if let firstIndex = firstFlippedIndex {
            moves += 1

            if cards[firstIndex].symbol == cards[tappedIndex].symbol {
                withAnimation(.easeOut(duration: 0.25)) {
                    cards[firstIndex].isMatched = true
                    cards[tappedIndex].isMatched = true
                }
            } else {
                lockBoard = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        cards[firstIndex].isFaceUp = false
                        cards[tappedIndex].isFaceUp = false
                    }
                    lockBoard = false
                }
            }

            firstFlippedIndex = nil
        } else {
            firstFlippedIndex = tappedIndex
        }
    }
}

private struct Card: Identifiable {
    let id = UUID()
    let symbol: String
    var isFaceUp = false
    var isMatched = false
}

private struct CardView: View {
    let card: Card

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(card.isFaceUp ? Color.white : Color.purple)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.85), lineWidth: 2)
                )

            if card.isFaceUp {
                Text(card.symbol)
                    .font(.system(size: 36))
            } else {
                Image(systemName: "questionmark")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }
        }
        .frame(height: 90)
        .opacity(card.isMatched ? 0 : 1)
        .scaleEffect(card.isMatched ? 0.8 : 1)
        .rotation3DEffect(.degrees(card.isFaceUp ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .accessibilityLabel(card.isFaceUp ? "\(card.symbol) card" : "Face down card")
    }
}

#Preview {
    ContentView()
}
