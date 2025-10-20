import SwiftUI

// Modelo para un paso del tutorial. Ahora usa una clave de localización.
struct CoachMark: Identifiable, Equatable {
    let id: String
    let textKey: String // Clave para buscar en Localizable
}

// PreferenceKey para comunicar la posición de las vistas hijas a la vista contenedora.
struct CoachMarkTargetsKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    /// Marca una vista como un objetivo para un CoachMark usando su ID.
    func coachMarkTarget(id: String) -> some View {
        self.anchorPreference(key: CoachMarkTargetsKey.self, value: .bounds) { anchor in
            [id: anchor]
        }
    }
}

// Vista de superposición que muestra el tutorial (Coach Marks).
struct CoachMarksOverlay: View {
    let step: CoachMark
    let targets: [String: Anchor<CGRect>]
    let onNext: () -> Void
    let onSkip: () -> Void

    // Constantes para un posicionamiento más claro
    private let tooltipMaxWidth: CGFloat = 320
    private let tooltipVerticalPadding: CGFloat = 70
    private let highlightPadding: CGFloat = 12
    private let highlightLineWidth: CGFloat = 3
    
    var body: some View {
        GeometryReader { proxy in
            if let anchor = targets[step.id] {
                let frame = proxy[anchor]
                
                // Asegurarse de que el frame tenga un tamaño válido antes de mostrar el overlay
                if frame.width > 1 && frame.height > 1 {
                    ZStack {
                        // Fondo oscurecido
                        Rectangle()
                            .fill(.black.opacity(0.45))
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.25), value: step)
                        
                        // Resaltado del elemento
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: max(44, frame.width + highlightPadding), height: max(44, frame.height + highlightPadding))
                            .overlay(
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: highlightLineWidth)
                            )
                            .position(x: frame.midX, y: frame.midY)
                            .transition(.opacity)

                        // Tooltip con el texto y botones
                        tooltipView
                            .frame(maxWidth: tooltipMaxWidth)
                            .position(
                                x: tooltipX(in: proxy.size, frame: frame),
                                y: tooltipY(in: proxy.size, frame: frame)
                            )
                            .transition(.opacity.combined(with: .scale))
                    }
                    .animation(.easeInOut(duration: 0.3), value: step)
                }
            }
        }
    }
    
    private var tooltipView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Usa la clave de localización directamente
            Text(LocalizedStringKey(step.textKey))
                .font(.body)
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                // Las claves "skip" y "next" deben estar en tu archivo de localizables
                Button(String(localized: "skip", defaultValue: "Omitir")) { onSkip() }
                    .buttonStyle(.bordered)
                Button(String(localized: "next", defaultValue: "Siguiente")) { onNext() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(radius: 6)
    }

    /// Calcula la posición horizontal del tooltip para que no se salga de la pantalla.
    private func tooltipX(in container: CGSize, frame: CGRect) -> CGFloat {
        // Centra el tooltip con el objetivo y lo ajusta para que no se salga de los bordes.
        let centerX = frame.midX
        let tooltipHalfWidth = tooltipMaxWidth / 2
        return min(max(centerX, tooltipHalfWidth + 20), container.width - tooltipHalfWidth - 20)
    }
    
    /// Calcula la posición vertical del tooltip, prefiriendo colocarlo debajo del elemento.
    private func tooltipY(in container: CGSize, frame: CGRect) -> CGFloat {
        let spaceBelow = container.height - frame.maxY
        let requiredSpace: CGFloat = 150 // Espacio estimado que necesita el tooltip

        if spaceBelow >= requiredSpace {
            return frame.maxY + tooltipVerticalPadding
        } else {
            return frame.minY - tooltipVerticalPadding
        }
    }
}
