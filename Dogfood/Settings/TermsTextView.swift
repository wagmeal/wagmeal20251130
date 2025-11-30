//
//  TermsTextView.swift
//  WagMeal
//

import SwiftUI

struct TermsTextView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("WAGMEAL 利用規約")
                    .font(.title3)
                    .bold()
                    .padding(.bottom, 8)

                Text(wagmealTermsFullText)
                    .font(.footnote)
                    .foregroundColor(Color(white: 0.4))
                    .multilineTextAlignment(.leading)
            }
            .padding()
        }
        .navigationTitle("利用規約")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    TermsTextView()
}
