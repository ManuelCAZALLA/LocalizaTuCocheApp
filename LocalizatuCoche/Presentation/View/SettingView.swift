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
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled: Bool = false
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
                                    Text(isPro ? "settings_pro_active_title".localized : "settings_pro_upgrade_title".localized)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Text(isPro ? "settings_pro_active_subtitle".localized : "settings_pro_upgrade_subtitle".localized)
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
                    
                    // Sección Apariencia (modo oscuro Pro)
                    VStack(spacing: 10) {
                        HStack {
                            Text("settings_appearance_title".localized)
                                .font(.headline)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle("settings_dark_mode_title".localized, isOn: $isDarkModeEnabled)
                                .tint(Color("AccentColor"))
                                .onChange(of: isDarkModeEnabled) { enabled in
                                    guard enabled, !isPro else { return }
                                    isDarkModeEnabled = false
                                    showPaywall = true
                                }
                            
                            Text(isPro ? "settings_dark_mode_pro_enabled_subtitle".localized : "settings_dark_mode_pro_only_subtitle".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Sección Siri Shortcuts (solo Pro)
                    if isPro {
                        VStack(spacing: 10) {
                            HStack {
                                Text("Siri & Atajos")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "mic.fill")
                                        .foregroundColor(Color("AccentColor"))
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Controla tu app con Siri")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("Guarda tu aparcamiento o navega a tu coche con un simple comando de voz.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    ShortcutStep(number: "1", text: "Abre la app Atajos de iPhone")
                                    ShortcutStep(number: "2", text: "Pulsa + para crear un nuevo atajo")
                                    ShortcutStep(number: "3", text: "Busca \"Localiza tu Coche\" y elige la acción")
                                    ShortcutStep(number: "4", text: "Asígnale una frase de Siri y guárdalo")
                                }
                                
                                Divider()
                                
                                Button {
                                    if let url = URL(string: "shortcuts://") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.up.right.square")
                                            .foregroundColor(Color("AccentColor"))
                                            .frame(width: 28)
                                        Text("Abrir app Atajos")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
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
                    
                    // Botón debug para activar Pro (solo en Debug)
#if DEBUG
                    Button("🔧 Toggle Pro (Debug)") {
                        isPro.toggle()
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 8)
#endif
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

// MARK: - Paso de Shortcut
struct ShortcutStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color("AccentColor"))
                .clipShape(Circle())
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Botón de acción
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
