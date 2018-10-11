import Foundation

//Reader-writer

var value = 0
let queue = DispatchQueue(label: "concurrent", attributes: .concurrent)
let group = DispatchGroup()



for _ in 1...120 {
  group.enter()
}

DispatchQueue.global().async {
  for _ in 1...100 {
    Thread.sleep(forTimeInterval: 0.002)
    queue.async {
      print("Read value \(value)")
      group.leave()
    }
  }
}

DispatchQueue.global().async {
  for _ in 1...20 {
    Thread.sleep(forTimeInterval: 0.01)
    queue.async(flags: .barrier) {
      let random = Int(arc4random() % 100)
      value = random
      print("Write value \(value)")
      group.leave()
    }
  }
}

group.wait()