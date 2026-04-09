//
//  SettingView.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 9/7/25.
//

import SwiftUI
import StoreKit
import RevenueCat
import RevenueCatUI

struct SettingView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @AppStorage("isPro") private var isPro: Bool = false
    @State private var showPaywall = false

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
                        
                        Text("\("settings_version".localized): \(viewModel.appVersion)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Seccion Pro (RevenueCat)
                    VStack(spacing: 12) {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: isPro ? "checkmark.seal.fill" : "crown.fill")
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isPro ? "Sin publicidad activa" : "Quitar publicidad")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Text(isPro ? "Tu compra Pro esta activa" : "Desbloquea la version Pro")
                                        .font(.subheadline)
                                        .opacity(0.9)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 18)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color("AccentColor"), Color("AppPrimary")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color("AccentColor").opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

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
            .task {
                await refreshProStatus()
            }
            .sheet(isPresented: $showPaywall, onDismiss: {
                Task { await refreshProStatus() }
            }) {
                PaywallView(displayCloseButton: true)
            }
        }
    }

    private func refreshProStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            let hasPremium = info.entitlements["Premium"]?.isActive == true
            await MainActor.run {
                isPro = hasPremium
            }
        } catch {
            // Si falla la consulta mantenemos el estado actual sin bloquear la UI.
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
