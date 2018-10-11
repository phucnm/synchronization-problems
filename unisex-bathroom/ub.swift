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

class Bathroom {
  let bathroomMutex = DispatchSemaphore(value: 1)
  let maxPeople = 3
  let mCount = 0
  let wCount = 0
  let mSwitch = Lightswitch()
  let wSwitch = Lightswitch()
  let wCounterMutex = DispatchSemaphore(value: 1)
  let mMultiplex: DispatchSemaphore!
  let wMultiplex: DispatchSemaphore!
  init() {
    mMultiplex = DispatchSemaphore(value: maxPeople)
    wMultiplex = DispatchSemaphore(value: maxPeople)
  }

  func enter(person: Person) {
    if person is Man {
      mSwitch.lock(semaphore: bathroomMutex)
      mMultiplex.wait()
      print("A \(String(describing: person)) - \(person.id) is using bathroom")
      Thread.sleep(forTimeInterval: 0.05)
      print("A \(String(describing: person)) - \(person.id) end using bathroom")
      mMultiplex.signal()
      mSwitch.unlock(semaphore: bathroomMutex)
    } else {
      wSwitch.lock(semaphore: bathroomMutex)
      wMultiplex.wait()
      print("A \(String(describing: person)) - \(person.id) is using bathroom")
      Thread.sleep(forTimeInterval: 0.05)
      print("A \(String(describing: person)) - \(person.id) end using bathroom")
      wMultiplex.signal()
      wSwitch.unlock(semaphore: bathroomMutex)
    }
  }
}

class Person {
    var id: Int

    init(id: Int) {
        self.id = id
    }
}

class Man: Person {

}

class Woman: Person {

}
let bathroom = Bathroom()
let group = DispatchGroup()
for _ in 1...101 { group.enter() }
DispatchQueue.global().async {
    DispatchQueue.concurrentPerform(iterations: 101, execute: { (i) in
        if i % 2 == 0 {
            let man = Man(id: i)
            bathroom.enter(person: man)
        } else {
            let woman = Woman(id: i)
            bathroom.enter(person: woman)
        }
      group.leave()
    })
}
group.wait()