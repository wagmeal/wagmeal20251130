import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FavoritesView: View {
    @EnvironmentObject var foodVM: DogFoodViewModel
    @EnvironmentObject var dogVM: DogProfileViewModel

    @Namespace private var namespace
    @State private var selectedDogFood: DogFood? = nil
    @State private var selectedMatchedID: String? = nil   // 👈 追加：アニメ用に安定ID保持
    @State private var showDetail = false

    // Preview でもVMを差し替えられるように StateObject をイニシャライザで用意
    @StateObject private var favoritesVM: FavoritesViewModel
    private let useMockData: Bool

    init(useMockData: Bool = false) {
        self.useMockData = useMockData
        _favoritesVM = StateObject(wrappedValue: FavoritesViewModel(useMockData: useMockData))
    }

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Text("お気に入り一覧")
                    .font(.title2).bold()
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)

                Group {
                    if favoritesVM.isLoading {
                        ProgressView("読み込み中...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if favoritesVM.favoriteDogFoods.isEmpty {
                        Text("お気に入りがまだありません")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            // ★ 型推論を軽くするためにローカル変数に落とす
                            let items = favoritesVM.favoriteDogFoods

                            LazyVGrid(columns: columns, spacing: 10) {
                                // ★ indices で回すとコンパイラが楽
                                ForEach(items.indices, id: \.self) { idx in
                                    let dogFood = items[idx]
                                    let matchedID = dogFood.id ?? dogFood.imagePath  // 安定ID

                                    dogFoodCard(dogFood, matchedID: matchedID) {
                                        withAnimation(.spring()) {
                                            selectedDogFood = dogFood
                                            selectedMatchedID = matchedID
                                            showDetail = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(.systemBackground))
            .allowsHitTesting(!showDetail)

            // 上層：詳細オーバーレイ
            if let dogFood = selectedDogFood, showDetail {
                DogFoodDetailView(
                    dogFood: dogFood,
                    dogs: dogVM.dogs,
                    namespace: namespace,
                    matchedID: selectedMatchedID ?? (dogFood.id ?? dogFood.imagePath),
                    isPresented: $showDetail
                )
                .environmentObject(foodVM)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .zIndex(1)
                .transition(.move(edge: .trailing))
                .gesture(
                    DragGesture().onEnded { value in
                        if value.translation.width > 100 {
                            withAnimation(.spring()) {
                                showDetail = false
                                selectedDogFood = nil
                                selectedMatchedID = nil
                            }
                        }
                    }
                )
            }
        }
        .onAppear { favoritesVM.start() }
    }

    private func dogFoodCard(_ dogFood: DogFood,
                             matchedID: String,
                             onTap: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            DogFoodImageView(
                imagePath: dogFood.imagePath,
                matchedID: matchedID,
                namespace: namespace
            )

            Text(dogFood.name)
                .font(.caption)
                .lineLimit(1)
                .padding(.leading, 10)

            // ★ 評価件数 + お気に入り
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "ellipsis.message")

                    let cnt = foodVM.evaluationCount(for: dogFood.id)
                    Text(" \(cnt.map(String.init) ?? "—")")
                        .redacted(reason: cnt == nil ? .placeholder : [])
                }
                .font(.caption2)
                .foregroundColor(.secondary)

                Spacer()

                Button {
                    if let id = dogFood.id { foodVM.toggleFavorite(dogFoodID: id) } // SSOT想定
                } label: {
                    Image(systemName: foodVM.isFavorite(dogFood.id) ? "heart.fill" : "heart")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 10)   // 星の左
            .padding(.trailing, 10)  // ハートの右

        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onAppear {
            foodVM.loadEvaluationCountIfNeeded(for: dogFood.id) // 件数キャッシュ取得
        }
    }

}

// MARK: -


#Preview("Favorites – Mock") {
    FavoritesPreviewContainer()
}

private struct FavoritesPreviewContainer: View {
    @StateObject private var dogVM: DogProfileViewModel
    @StateObject private var foodVM: DogFoodViewModel

    init() {
        let d = DogProfileViewModel()
        d.dogs = PreviewMockData.dogs
        let f = DogFoodViewModel(mockData: true)
        _dogVM = StateObject(wrappedValue: d)
        _foodVM = StateObject(wrappedValue: f)
    }

    var body: some View {
        FavoritesView(useMockData: true)
            .environmentObject(foodVM)
            .environmentObject(dogVM)
    }
}
