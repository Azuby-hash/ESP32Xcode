//
//  Storage.swift
//  ProjectII
//
//  Created by Azuby on 01/02/2023.
//

import UIKit

class Storage {
    private var temp: StorageValueCollection = .init(name: "Temperature", unit: "ºC")
    private var air: StorageValueCollection = .init(name: "Air", unit: "%")
    private var humi: StorageValueCollection = .init(name: "Humidity", unit: "%")
    private var light: StorageValueCollection = .init(name: "Light", unit: "Lux")
    
    func descriptObject(_ object: ModelJSON) {
        let feeds = object.feeds.sorted(by: { feeda, feedb in
            return feeda.entry_id < feedb.entry_id
        })
        
        for feed in feeds {
            var dateString = feed.created_at.replacingOccurrences(of: "T", with: " ")
            dateString.removeLast()
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            if let string = feed.field1,
               let value = Double(string),
               let date = dateFormatter.date(from: dateString)
            {
                temp.appendValue(value: value, date: date, entry: feed.entry_id)
            }
            
            if let string = feed.field2,
               let value = Double(string),
               let date = dateFormatter.date(from: dateString)
            {
                air.appendValue(value: value, date: date, entry: feed.entry_id)
            }
            
            if let string = feed.field3,
               let value = Double(string),
               let date = dateFormatter.date(from: dateString)
            {
                humi.appendValue(value: value, date: date, entry: feed.entry_id)
            }
            
            if let string = feed.field4,
               let value = Double(string),
               let date = dateFormatter.date(from: dateString)
            {
                light.appendValue(value: value, date: date, entry: feed.entry_id)
            }
        }
    }
    
    func getStorage(of value: String) -> StorageValueCollection? {
        let model = [
            "temp": temp,
            "air": air,
            "humi": humi,
            "light": light
        ]
        
        return model[value]
    }
}

class StorageValueCollection {
    private var values: [StorageValue] = []
    private var name: String = ""
    private var unit: String = ""
    
    init(name: String, unit: String) {
        self.name = name
        self.unit = unit
    }

    func getName() -> String {
        return name
    }
    
    func getUnit() -> String {
        return unit
    }
    
    func appendValue(value: CGFloat, date: Date, entry: Int) {
        if values.map({ value in return value.getEntry() }).contains(entry) {
            return
        }
        values.append(StorageValue(value: value, date: date, entry: entry, col: self))
        NotificationCenter.default.post(name: Notification.Name("storage.update"), object: nil)
    }
    
    func getValue(at index: Int? = nil) -> StorageValue? {
        if let index = index {
            return values[index]
        }
        return values.last
    }
    
    func getValues(timeRange: ClosedRange<CGFloat>) -> [StorageValue] {
        return values.filter { e in
            return timeRange.contains(e.getDate().timeIntervalSince1970)
        }
    }
    
    func getValues(valueRange: ClosedRange<CGFloat>) -> [StorageValue] {
        return values.filter { e in
            return valueRange.contains(e.getValue())
        }
    }
    
    func getUnloopValues() -> [StorageValue] {
        var values = [StorageValue]()
        
        for value in self.values.enumerated() {
            if value.offset > 0 {
                if abs(value.element.getValue() - self.values[value.offset - 1].getValue()) < 0.01 {
                    continue
                }
                values.append(value.element)
            } else {
                values.append(value.element)
            }
        }
        
        return values
    }
    
    func getTimeRangeToLast(in time: CGFloat = .greatestFiniteMagnitude) -> ClosedRange<CGFloat> {
        if let l = values.last?.getDate(),
           let f = values.first(where: { value in
            return value.getDate().distance(to: l) < time
           })?.getDate() {
            
            return f.timeIntervalSince1970...l.timeIntervalSince1970
        }
        if let l = values.last?.getDate().timeIntervalSince1970 {
            return l...l
        }
        return 0.0...0.0
    }
    func getTimeRangeToNow(in time: CGFloat = .greatestFiniteMagnitude) -> ClosedRange<CGFloat> {
        if let f = values.first(where: { value in
            return value.getDate().distance(to: Date()) < time
           })?.getDate() {
            
            return f.timeIntervalSince1970...Date().timeIntervalSince1970
        }
        return Date().timeIntervalSince1970...Date().timeIntervalSince1970
    }
    
    func getValueRange() -> ClosedRange<CGFloat> {
        let vs = values.sorted { a, b in
            return a.getValue() < b.getValue()
        }
        return (vs.first?.getValue() ?? 0.0)...(vs.last?.getValue() ?? 0.0)
    }
}

class StorageValue: Equatable {
    private var value: CGFloat
    private var date: Date
    private let entry: Int
    weak var col: StorageValueCollection!
    
    init(value: CGFloat, date: Date, entry: Int, col: StorageValueCollection) {
        self.value = value
        self.date = date
        self.entry = entry
        self.col = col
    }
    
    func getEntry() -> Int {
        return entry
    }
    
    func getDate() -> Date {
        return date
    }
    
    func getValue() -> CGFloat {
        return value
    }
    
    func getCol() -> StorageValueCollection {
        return col
    }
    
    static func == (lhs: StorageValue, rhs: StorageValue) -> Bool {
        return lhs.value == rhs.value && lhs.date == rhs.date && lhs.entry == rhs.entry
    }
}
