import SwiftUI

struct RankingView: View {
    @EnvironmentObject var foodVM: DogFoodViewModel
    @EnvironmentObject var dogVM: DogProfileViewModel
    
    @Namespace private var namespace
    @State private var selectedDogFood: DogFood? = nil
    @State private var showDetail = false
    @State private var selectedSizeCategory: String? = nil // nil = 全体
    
    // 👇 モック使用フラグを外から渡す
    var useMockData: Bool = false
    @StateObject private var rankingVM: RankingViewModel
    
    init(useMockData: Bool = false) {
        self.useMockData = useMockData
        _rankingVM = StateObject(wrappedValue: RankingViewModel(useMockData: useMockData))
    }
    
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // タイトル
                Text(rankingTitle())
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 16)
                
                // フィルター
                sizeCategoryFilterIcons()
                
                // ランキング一覧だけスクロール
                ScrollView {
                    if rankingVM.isLoading {
                        ProgressView("読み込み中...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if rankingVM.rankedDogFoods.isEmpty {
                        VStack {
                            Spacer().frame(height: 80)
                            Text("評価されたドッグフードがありません")
                                .foregroundColor(.gray)
                                .font(.body)
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        // ★ 型推論を軽くするために一度ローカル変数に落とす
                        let items = rankingVM.rankedDogFoods
                        
                        LazyVGrid(columns: columns, spacing: 10) {
                            // ★ indices で回すとコンパイラが楽になる
                            ForEach(items.indices, id: \.self) { idx in
                                let item = items[idx]
                                // ★ 安定ID（id がなければ index ベースで生成）
                                let matchedID = item.dogFood.id ?? "rank-\(idx)"
                                let rank = idx + 1                      // ← 追加
                                
                                dogFoodCard(item.dogFood,
                                            averageRating: item.averageRating,
                                            matchedID: matchedID,
                                            rank: rank) {
                                    withAnimation(.spring()) {
                                        selectedDogFood = item.dogFood
                                        showDetail = true
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
                .padding(.top, 8)
                
            }
            
            // ✅ ドッグフード詳細画面（ZStackで上に重ねる）
            if let dogFood = selectedDogFood, showDetail {
                DogFoodDetailView(
                    dogFood: dogFood,
                    dogs: dogVM.dogs,
                    namespace: namespace,
                    matchedID: dogFood.id ?? UUID().uuidString,
                    isPresented: $showDetail
                )
                .environmentObject(foodVM)
                .zIndex(1)
                .transition(.move(edge: .trailing))
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width > 100 {
                                withAnimation {
                                    showDetail = false
                                    selectedDogFood = nil
                                }
                            }
                        }
                )
            }
        }
        .onChange(of: selectedSizeCategory) { newValue in
            rankingVM.refresh(sizeCategory: newValue)
        }
        .onAppear {
            rankingVM.refresh(sizeCategory: selectedSizeCategory)
        }
        
        .background(Color.white)
        .edgesIgnoringSafeArea(.bottom)
        
    }
    
    
    // MARK: - フィルターUI（アイコン切替式）
    private func sizeCategoryFilterIcons() -> some View {
        HStack(spacing: 0) {
            ForEach(["小型犬", "中型犬", "大型犬"], id: \.self) { size in
                Button {
                    withAnimation {
                        if selectedSizeCategory == size {
                            selectedSizeCategory = nil // 選択解除で全体に戻す
                        } else {
                            selectedSizeCategory = size
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(filterIconName(for: size))
                            .resizable()
                            .scaledToFit()
                            .frame(height: 48)
                        
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 最後の要素以外に区切り線を追加
                if size != "大型犬" {
                    Divider()
                        .frame(width: 1, height: 50)
                        .background(Color.gray.opacity(0.3))
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func filterIconName(for category: String) -> String {
        switch category {
        case "小型犬":
            return selectedSizeCategory == "小型犬" ? "smalldogselected" : "smalldogunselected"
        case "中型犬":
            return selectedSizeCategory == "中型犬" ? "middledogselected" : "middledogunselected"
        case "大型犬":
            return selectedSizeCategory == "大型犬" ? "bigdogselected" : "bigdogunselected"
        default:
            return "smalldogunselected"
        }
    }
    
    // MARK: - ドッグフードカード
    // ドッグフードカード（変更）
    private func dogFoodCard(_ dogFood: DogFood,
                             averageRating: Double,
                             matchedID: String,
                             rank: Int,
                             onTap: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            DogFoodImageView(
                imagePath: dogFood.imagePath,
                matchedID: matchedID,
                namespace: namespace
            )
            .overlay(alignment: .topLeading) {
                RankBadge(rank: rank)
                    .padding(6)
                    .allowsHitTesting(false)
            }
            
            Text(dogFood.name)
                .font(.caption)
                .lineLimit(1)
                .padding(.leading, 8)
            
            // ★ 評価(平均) + 件数 + ハート
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", averageRating))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "ellipsis.message")
                    let cnt = foodVM.evaluationCount(for: dogFood.id)
                    Text("\(cnt.map(String.init) ?? "—")")
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
            .padding(.leading, 8)   // 星の左に少しスペース
            .padding(.trailing, 8)  // ハートの右に少しスペース
        }
        .contentShape(Rectangle())     // セル全体をタップ可能に
        .onTapGesture { onTap() }      // 詳細へ遷移
        .onAppear {
            foodVM.loadEvaluationCountIfNeeded(for: dogFood.id) // 件数を取得（キャッシュ）
        }
    }
    
    
    // MARK: - タイトル
    private func rankingTitle() -> String {
        if let selected = selectedSizeCategory {
            return "\(selected)ランキング"
        } else {
            return "総合ランキング"
        }
    }
}

// MARK: -
// 左上の順位リボン（追加）
private struct RankBadge: View {
    let rank: Int
    var body: some View {
        VStack(spacing: 0) {
            Text("\(rank)")
                .font(.caption2.bold())
                .foregroundColor(.white)
                .padding(.vertical, 3)
                .padding(.horizontal, 6)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            
            // リボンの三角しっぽ
            Triangle()
                .fill(color)
                .frame(width: 16, height: 6)
        }
        .shadow(radius: 1, y: 1)
    }
    
    private var color: Color {
        switch rank {
        case 1: return .yellow   // お好みで色を調整
        case 2: return .gray
        case 3: return .brown
        default: return Color.gray.opacity(0.4)
        }
    }
}

// 三角形シェイプ（追加）
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: .zero)
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        p.addLine(to: CGPoint(x: rect.width/2, y: rect.height))
        p.closeSubpath()
        return p
    }
}


struct RankingView_Previews: PreviewProvider {
    static var previews: some View {
        RankingView(useMockData: true)
            .environmentObject(DogFoodViewModel())
            .environmentObject(DogProfileViewModel())
    }
}
