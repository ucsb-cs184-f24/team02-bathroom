//
//  ColorExtension.swift
//  ucsb-bathrooms
//
//  Created by Zheli Chen on 11/22/24.
//

import SwiftUI
import UIKit

extension Color {
    func adjustBrightness(_ amount: Double) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        brightness += CGFloat(amount)
        brightness = max(min(brightness, 1.0), 0.0)

        return Color(hue: hue, saturation: saturation, brightness: brightness, opacity: alpha)
    }

    func adjustSaturation(_ amount: Double) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        saturation += CGFloat(amount)
        saturation = max(min(saturation, 1.0), 0.0)

        return Color(hue: hue, saturation: saturation, brightness: brightness, opacity: alpha)
    }
}
