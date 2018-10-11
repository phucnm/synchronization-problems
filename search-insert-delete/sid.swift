import Foundation

class Lightswitch {
    var counter = 0
    let mutex = DispatchSemaphore(value: 1)

    func lock(semaphore: DispatchSemaphore) {
        mutex.wait()
        counter += 1
        if counter == 1 {
            semaphore.wait()
        }
        mutex.signal()
    }

    func unlock(semaphore: DispatchSemaphore) {
        mutex.wait()
        counter -= 1
        if counter == 0 {
            semaphore.signal()
        }
        mutex.signal()
    }
}

class List {
 private let insertMutex = DispatchSemaphore(value: 1)
 private let noSearcher = DispatchSemaphore(value: 1)
 private let noInserter = DispatchSemaphore(value: 1)
 private let searchSwitch = Lightswitch()
 private let insertSwitch = Lightswitch()
 var list: [Int] = []
 func search(for element: Int) -> Bool {
   var found = false
   searchSwitch.lock(semaphore: noSearcher)
//    print("Trying to search for \(element)")
//    Thread.sleep(forTimeInterval: 0.1)
//    print("Searching for \(element)")
   found = self.list.contains(element)
//    print("Searching for \(element) done")
   searchSwitch.unlock(semaphore: noSearcher)
   return found
 }
 func insert(element: Int) {
   insertSwitch.lock(semaphore: noInserter)
   insertMutex.wait()
//    print("Inserting \(element)")
   self.list.append(element)
//    print("Inserting \(element) done")
   insertMutex.signal()
   insertSwitch.unlock(semaphore: noInserter)
 }
 func delete(at index: Int) {
   noSearcher.wait()
   noInserter.wait()
//    print("Delete at \(index)")
   if index >= 0 && index < self.list.count {
     self.list.remove(at: index)
   }
//    print("Delete at \(index) done")
   noInserter.signal()
   noSearcher.signal()
 }
}

class ListQueue {
 private let queue = DispatchQueue(label: "MyInternalQueue", attributes: .concurrent)
 private let mutex = DispatchSemaphore(value: 1)
 var list: [Int] = []
 func search(for element: Int) -> Bool {
   var found = false
   queue.sync {
//      print("Trying to search for \(element)")
//      Thread.sleep(forTimeInterval: 0.1)
//      print("Searching for \(element)")
     found = self.list.contains(element)
//      print("Searching for \(element) done")
   }
   return found
 }
 func insert(element: Int) {
   queue.async {
     self.mutex.wait()
//      print("Inserting \(element)")
     self.list.append(element)
//      print("Inserting \(element) done")
     self.mutex.signal()
   }
 }
 func delete(at index: Int) {
   queue.async(flags: .barrier) {
//      print("Delete at \(index)")
     if index >= 0 && index < self.list.count {
       self.list.remove(at: index)
     }
//      print("Delete at \(index) done")
   }
 }
}

let list = List()
//for _ in 1...10 {
//  list.insert(element: Int.random(in: 1...100))
//}
let nSearchers = 3000
let nInserters = 3000
let nDeleters = 3000
let group = DispatchGroup()
for _ in 1...(nSearchers + nInserters + nDeleters) {
 group.enter()
}
let start = Date()

let totalN = nInserters + nSearchers + nDeleters
let searcherRate = Float(nSearchers) / Float(totalN)
let insertRate = Float(nInserters) / Float(totalN)
let deleteRate = Float(nDeleters) / Float(totalN)

let searchQueue = DispatchQueue(label: "Search")
searchQueue.async {
   for _ in 1...nSearchers {
     let random = Int.random(in: 1...100)
     _ = list.search(for: random)
     group.leave()
   }
}

let insertQueue = DispatchQueue(label: "Insert")
insertQueue.async {
   for _ in 1...nInserters {
     list.insert(element: Int.random(in: 1...100))
//      Thread.sleep(forTimeInterval: 0.08)
     group.leave()
   }
}

let deleteQueue = DispatchQueue(label: "Delete")
deleteQueue.async {
   for _ in 1...nDeleters {
     list.delete(at: Int.random(in: 0...(list.list.count)))
//      Thread.sleep(forTimeInterval: 0.09)
     group.leave()
   }
}
group.wait()
print("Done. Final list count \(list.list.count)")
let elapsed = Date().timeIntervalSince(start) * 1000
print("Total time \(elapsed)")