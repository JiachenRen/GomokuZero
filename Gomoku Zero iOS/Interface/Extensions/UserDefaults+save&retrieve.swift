//
//  UserDefaults+save&retrieve.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/9/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

extension UserDefaults {
    public static func save(obj: Any, key: String) {
        UserDefaults.standard.set(obj, forKey: key)
        print("saved: \(obj) with key: \(key)")
    }

    public static func retrieve(key: String) -> Any? {
        let obj = UserDefaults.standard.object(forKey: key)
        print("retrieved \(String(describing: obj)) for key: \(key)")
        return obj
    }
}
