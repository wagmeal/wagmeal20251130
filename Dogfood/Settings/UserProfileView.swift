//
//  UserProfileView.swift
//  Dogfood
//
//  Created by takumi kowatari on 2025/11/23.
//
import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var username: String = ""
    @State private var email: String = ""
    @State private var birthday: Date = Date()
    @State private var gender: String = ""
    @State private var isSaving = false
    @State private var saveMessage: String?

    var body: some View {
        NavigationStack {
            List {
                // MARK: - プロフィール
                Section(header: Text("プロフィール")) {
                    // ユーザー名
                    TextField("ユーザー名", text: $username)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)

                    // メールアドレス（読み取り専用）
                    HStack {
                        Text("メールアドレス")
                        Spacer()
                        Text(email.isEmpty ? "未設定" : email)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // 誕生日
                    DatePicker("誕生日", selection: $birthday, displayedComponents: .date)

                    // 性別
                    Picker("性別", selection: $gender) {
                        Text("未選択").tag("")
                        Text("男性").tag("男性")
                        Text("女性").tag("女性")
                        Text("その他").tag("その他")
                    }
                    .pickerStyle(.menu)
                }

                // MARK: - アクション
                Section {
                    Button {
                        saveProfile()
                    } label: {
                        if isSaving {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("変更を保存")
                                Spacer()
                            }
                        }
                    }
                }

                if let message = saveMessage {
                    Section {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("ユーザー情報")
            .onAppear {
                // Xcode プレビュー時は Firebase にアクセスせず MocData を使用
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                    let mock = PreviewMockData.userProfile
                    self.username = mock.username
                    self.email = mock.email
                    self.birthday = mock.birthday
                    self.gender = mock.gender
                } else {
                    loadFromAuth()
                }
            }
        }
    }

    /// AuthViewModel から初期値をロード
    private func loadFromAuth() {
        authViewModel.loadUserProfile { username, email, birthday, gender in
            self.username = username ?? ""
            self.email = email ?? ""
            if let birthday = birthday {
                self.birthday = birthday
            }
            self.gender = gender ?? ""
        }
    }

    /// プロフィール保存処理
    private func saveProfile() {
        isSaving = true
        saveMessage = nil

        authViewModel.updateProfile(username: username, birthday: birthday, gender: gender) { success, error in
            isSaving = false
            if let error = error {
                saveMessage = "保存に失敗しました：\(error.localizedDescription)"
            } else if success {
                saveMessage = "プロフィールを保存しました"
            } else {
                saveMessage = "保存に失敗しました"
            }
        }
    }
}

#Preview {
    // プレビュー用のダミー
    let authVM = AuthViewModel()
    // 必要ならここで authVM.currentUser 的なものをモックセット

    return UserProfileView()
        .environmentObject(authVM)
}
