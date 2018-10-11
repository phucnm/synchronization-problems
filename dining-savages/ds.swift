//
//  main.swift
//  SwiftConcurrency
//
//  Created by TonyNguyen on 9/19/18.
//  Copyright © 2018 TonyNguyen. All rights reserved.
//

import Foundation

class Pot {
  var size: Int
  var servings: Int

  init(size: Int) {
    self.size = size
    self.servings = size
  }

  func fill() {
    self.servings = size
  }

  func isEmpty() -> Bool {
    return self.servings == 0
  }
}

let savages = DispatchQueue(label: "savages")
let pot = Pot(size: 10)
let group = DispatchGroup()

for i in 1...100 {
  group.enter()
  DispatchQueue.global().async {
    savages.sync {
      if pot.isEmpty() {
        print("Pot is empty, filling to \(pot.size)")
        pot.fill()
      }
      print("Current servings: \(pot.servings) - Savage \(i) is eating")
      pot.servings -= 1
      group.leave()
    }
  }
}
group.wait()
print("Done")

