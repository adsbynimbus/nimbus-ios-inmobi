//
//  NimbusError+InMobi.swift
//  NimbusInMobiKit
//
//  Created on 2/23/26.
//  Copyright © 2026 Nimbus Advertising Solutions Inc. All rights reserved.
//

import NimbusKit

extension NimbusError.Domain {
    static let inmobi = Self(rawValue: "inmobi")
}

extension NimbusError {
    static func inmobi(reason: Reason = .failure, stage: Stage, detail: String? = nil) -> NimbusError {
        NimbusError(reason: reason, domain: .inmobi, stage: stage, detail: detail)
    }
}
