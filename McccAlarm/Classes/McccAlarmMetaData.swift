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
    public let createdAt: Date

    public init() {
        self.createdAt = Date.now
    }
}

@available(iOS 26.0, *)
public struct McccAlarmMetadata: AlarmMetadata {
    public let createdAt: Date
    public let title: String
    public let subTitle: String

    /// 闹钟业务 ID（关联到业务层的闹钟模型）
    public let alarmId: String
    /// 本次触发的预期时间
    public let fireDate: Date?
    /// 同组触发器的所有预期时间（用于 StopIntent 取消 sibling）
    public let siblingFireDates: [Date]

    public init(
        title: String,
        subTitle: String,
        alarmId: String = "",
        fireDate: Date? = nil,
        siblingFireDates: [Date] = []
    ) {
        self.createdAt = Date.now
        self.title = title
        self.subTitle = subTitle
        self.alarmId = alarmId
        self.fireDate = fireDate
        self.siblingFireDates = siblingFireDates
    }
}
