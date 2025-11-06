//
//  McccAlarmMetaData.swift
//  McccAlarm
//
//  Created by qixin on 2025/10/21.
//

import Foundation
import AlarmKit

@available(iOS 26.0, *)
public struct McccEmptyMetadata: AlarmMetadata {
    let createdAt: Date
    
    public init() {
        self.createdAt = Date.now
    }
}



@available(iOS 26.0, *)
public struct McccAlarmMetadata: AlarmMetadata {
    public let createdAt: Date
    public let title: String
    public let subTitle: String
    
    public init(title: String, subTitle: String) {
        self.createdAt = Date.now
        self.title = title
        self.subTitle = subTitle
    }
}
