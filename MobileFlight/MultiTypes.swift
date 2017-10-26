//
//  MultiTypes.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 07/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

class MultiTypes {
    static let label = [ "Tricopter", "Quad +", "Quad X", "Bicopter", "Gimbal", "Y6", "Hex +", "Flying Wing", "Y4", "Hex X", "Octo X8", "Octo Flat +", "Octo Flat X", "Airplane", "Heli 120", "Heli 90", "V-tail Quad", "Hex H", "PPM to SERVO", "Dualcopter", "Singlecopter", "A-tail Quad", "Custom", "Custom Airplane", "Custom Tricopter", "Quad X 1234" ]
    static let custom = "custom"
    static let drawings = [ "tri", "quad_p", "quad_x", "bicopter", custom, "y6", "hex_p", "flying_wing", "y4", "hex_x", "octo_x8", "octo_flat_p", "octo_flat_x", "airplane", custom, custom, "vtail_quad", custom, custom, custom, custom, "atail_quad", custom, custom, custom, "quad_x_1234" ]
    
    static func getDescription(_ multiType: Int) -> String {
        if multiType < 1 || multiType > label.count {
            return "Unknown"
        }
        return label[multiType - 1];
    }
    static func getImage(_ multiType: Int) -> UIImage {
        if multiType < 1 || multiType > label.count {
            return UIImage(named: custom)!
        }
        return UIImage(named: drawings[multiType - 1])!
    }
}
