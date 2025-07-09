//
//  SettingView.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 9/7/25.
//

import SwiftUI

struct SettingView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Sección superior: logo, nombre y versión
                    VStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .foregroundColor(.accentColor)
                            .padding(.top, 24)
                        Text("settings_app_name".localized)
                            .font(.title)
                            .fontWeight(.bold)
                        Text("\("settings_version".localized): \(viewModel.appVersion)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Sección de acciones
                    VStack(spacing: 16) {
                        SettingActionButton(
                            icon: "square.and.arrow.up",
                            title: "settings_share_whatsapp".localized,
                            action: viewModel.shareOnWhatsApp
                        )
                        SettingActionButton(
                            icon: "doc.text",
                            title: "settings_privacy_policy".localized,
                            action: viewModel.openPrivacyPolicy
                        )
                        SettingActionButton(
                            icon: "envelope",
                            title: "settings_contact".localized,
                            action: viewModel.contactSupport
                        )
                    }
                    .padding(.horizontal)

                    // Sección premium
                    VStack(spacing: 16) {
                        Text("settings_section_premium".localized)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        if !viewModel.adsRemoved {
                            Button(action: viewModel.removeAds) {
                                HStack {
                                    Image(systemName: "nosign")
                                    Text("settings_remove_ads".localized)
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                            }
                            .padding(.horizontal)
                        } else {
                            Label("settings_ads_removed".localized, systemImage: "checkmark.circle")
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("settings_tab_title".localized)
        }
    }
}

// Botón reutilizable para acciones
struct SettingActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
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

