import SwiftUI

/// DogDetailView の上部に表示する、犬情報＋記録数の行。
/// DogCard 相当の見た目（プロフィール画像の枠色＝性別、犬種タグ、年齢タグ、記録数ピル）。
///
/// - 依存: DogProfile, DogAvatarView
/// - 注意: 同名の TagView / StatPill と衝突しないよう、このファイルでは固有名にしています。
struct HeaderCountRow: View {
    let dog: DogProfile
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            // プロフィール画像（丸）＋ 性別で枠線色
            DogAvatarView(dog: dog, size: 56)
                .frame(width: 56, height: 56)
                .overlay(
                    Circle()
                        .stroke(_headerGenderBorderColor(dog.gender), lineWidth: 2)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(dog.name)
                    .font(.title3.weight(.semibold))

                HStack(spacing: 8) {
                    _HeaderTag(text: dog.breed)
                    if let age = _headerAgeString(from: dog.birthDate) {
                        _HeaderTag(text: age)
                    }
                }
            }
            Spacer()

            _HeaderStatPill(title: "記録数", value: "\(count)")
        }
    }
}

// MARK: - 内部専用の小物（衝突回避のためプレフィックス `_` 付き）
private struct _HeaderTag: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color(.systemGray6)))
    }
}

private struct _HeaderStatPill: View {
    let title: String
    let value: String
    var body: some View {
        HStack(spacing: 6) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color(.systemGray6)))
    }
}

private func _headerGenderBorderColor(_ gender: String) -> Color {
    let isFemale = gender.contains("女") || gender.contains("メス")
    return isFemale
        ? Color(red: 0.55, green: 0.11, blue: 0.10) // えんじ
        : Color(red: 0.05, green: 0.12, blue: 0.23) // 紺
}

private func _headerAgeString(from birth: Date) -> String? {
    let comp = Calendar.current.dateComponents([.year, .month], from: birth, to: Date())
    guard let y = comp.year, let m = comp.month else { return nil }
    if y <= 0 { return "\(m)か月" }
    return m == 0 ? "\(y)歳" : "\(y)歳\(m)か月"
}



// MARK: - Preview
#Preview("HeaderCountRow – Mock") {
    let dog = DogProfile(
        id: "dog_001",
        name: "ココ",
        birthDate: Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date(),
        gender: "メス",
        breed: "トイプードル",
        sizeCategory: "小型犬",
        createdAt: Date(),
        imagePath: nil
    )
    HeaderCountRow(dog: dog, count: 12)
        .padding()
}
