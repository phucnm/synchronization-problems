//Source: https://gist.github.com/kainosnoema/dc8b8db0007412244b4a

import Foundation

func go(routine: @escaping () -> ()) {
  DispatchQueue.global().async(execute: routine)
}

class Chan {
  class Waiter : NSObject {
    enum Direction : Int {
      case Receive = 0
      case Send
    }

    let direction : Direction
    var fulfilled : Bool = false
    let sema : DispatchSemaphore = DispatchSemaphore(value: 0)

    var value : AnyObject? {
      get {
        if direction == .Receive {
          fulfilled = true
          sema.signal()
        } else if !fulfilled {
          sema.wait()
        }
        return _value
      }
      set(newValue) {
        _value = newValue
        if direction == .Send {
          fulfilled = true
          sema.signal()
        } else if !fulfilled {
          sema.wait()
        }
      }
    }
    var _value : AnyObject?

    init(direction : Direction) {
      self.direction = .Send
    }
  }

  var lock : NSLock = NSLock()

  var capacity : Int = Int.max
  var buffer : [AnyObject?] = []
  var sendQ : [Waiter] = []
  var recvQ : [Waiter] = []

  init (buffer:Int) {
    self.capacity = buffer
  }

  var count : Int {
    return buffer.count
  }

  func send(value: AnyObject?) {
    lock.lock()

    // see if we can immediately pair with a waiting receiver
    if let recvW = removeWaiter(waitQ: &recvQ) {
      recvW.value = value
      lock.unlock()
      return
    }

    // if not, use the buffer if there's space
    if self.buffer.count < self.capacity {
      self.buffer.append(value)
      lock.unlock()
      return
    }

    // otherwise block until we can send
    let sendW = Waiter(direction: .Send)
    sendQ.append(sendW)
    lock.unlock()
    sendW.value = value
  }

  func recv() -> AnyObject? {
    lock.lock()

    // see if there's oustanding messages in the buffer
    if buffer.count > 0 {
      let value : AnyObject? = buffer.remove(at: 0)

      // unblock waiting senders using buffer
      if let sendW = removeWaiter(waitQ: &sendQ) {
        buffer.append(sendW.value)
      }

      lock.unlock()
      return value
    }

    // if not, pair with any waiting senders
    if let sendW = removeWaiter(waitQ: &sendQ) {
      lock.unlock()
      return sendW.value
    }

    // otherwise, block until a message is available
    let recvW = Waiter(direction: .Receive)
    recvQ.append(recvW)
    lock.unlock()

    return recvW.value
  }

  func removeWaiter(waitQ : inout Array<Waiter>) -> Waiter? {
    if waitQ.count > 0 {
      return waitQ.remove(at: 0)
    }
    return nil
  }
}

prefix operator <-
infix operator <-

prefix func <-<T>(rhs: Chan) -> T? { return rhs.recv() as? T }
func <-<T>(lhs: Chan, rhs: T) { return lhs.send(value: rhs as AnyObject) }