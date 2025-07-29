//
//  SettingView.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 9/7/25.
//

import SwiftUI
import StoreKit
import FirebaseCore
import FirebaseCrashlytics

struct SettingView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo, nombre y versión
                    VStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .foregroundColor(Color("AppPrimary"))
                            .padding(.top, 24)
                        Text("settings_app_name".localized)
                            .font(.title)
                            .fontWeight(.bold)
                        Text("\("settings_version".localized): \(viewModel.appVersion)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Sección Contacto
                    VStack(spacing: 16) {
                        Text("contact".localized)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        SettingActionButton(
                            icon: "envelope",
                            title: "Email",
                            action: viewModel.contactSupport
                        )
                    }
                    .padding(.horizontal)

                    // Sección Acerca de
                    VStack(spacing: 16) {
                        Text("about".localized)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        SettingActionButton(
                            icon: "square.and.arrow.up",
                            title: "share_whatsapp".localized,
                            action: viewModel.shareOnWhatsApp
                        )
                        SettingActionButton(
                            icon: "globe",
                            title: "website".localized,
                            action: viewModel.openWebsite
                        )
                        SettingActionButton(
                            icon: "doc.text",
                            title: "settings_privacy_policy".localized,
                            action: viewModel.openPrivacyPolicy
                        )
                        SettingActionButton(
                            icon: "star.fill",
                            title: "rate_me".localized,
                            action: viewModel.requestReview
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("settings_tab_title".localized)
        }
    }
}

struct SettingActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color("AccentColor"))
                    .frame(width: 28)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

#Preview {
    SettingView(viewModel: SettingsViewModel())
}
