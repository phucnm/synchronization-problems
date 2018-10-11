//Source: https://gist.github.com/JadenGeller/92e980745e29c2a0aa43
/***
 *** This has been continued as a full project on GitHub project called Mailbox.
 *** I'd urge you to check it out instead as it is more full-featured and better
 *** documented. This Gist is still interesting for educational purposes though.
 *** Check out Mailbox here: https://github.com/JadenGeller/Mailbox
 ***/

import Foundation

class Channel<T> {

  // Signals--communicating delivery status between threads
  let valueDesired = DispatchSemaphore(value: 0)
  let valueAvailable = DispatchSemaphore(value: 0)
  let valueReceived = DispatchSemaphore(value: 0)

  // Locks--only one thread can send/receive at a time
  let valuePickup = DispatchSemaphore(value: 1)
  let valueDropoff = DispatchSemaphore(value: 1)

  var message: T!

  func send(_ message: T) {
    // Wait in line to deliver our message
    valueDropoff.wait()

    // Wait until someone is ready to recieve a value
    valueDesired.wait()

    // They're ready. Push the message through the window
    self.message = message

    // Let them know that the message is now availible--woot!
    valueAvailable.signal()

    // Wait until our recipient arrives and grabs their message
    valueReceived.wait()

    // Package dropoff successful, get out of line!
    valueDropoff.signal()
  }

  func receive() -> T? {
    // Wait in line to pick up our message
    valuePickup.wait()

    // Let the channel know that we actually want a value!
    valueDesired.signal()

    // Wait for some kind thread to actually send us a message
    valueAvailable.wait()

    // Grab the message!
    let message = self.message
    self.message = nil

    // Tell our delivery man, "Thank you, please have a nice day!"
    valueReceived.signal()

    // Get out of the line already; we already got our message!
    valuePickup.signal()

    return message
  }
}

prefix operator <-
infix operator <-

prefix func <-<T>(rhs: Channel<T>) -> T? { return rhs.receive() }
func <-<T>(lhs: Channel<T>, rhs: T) { return lhs.send(rhs) }

func dispatch(routine: @escaping () -> ()) {
  DispatchQueue.global().async(execute: routine)
}

func main(routine: @escaping () -> ()) {
  DispatchQueue.main.async(execute: routine)
}

// Let's test it out!
let c = Channel<String>()

dispatch {
    // Send data to our channels
    c <- "HELLO"
    c <- "WORLD"
}

dispatch {
    // Look ma, communication between threads!
    let m = <-c
    main { println(m) }
}

dispatch {
    // Note that receiving data from a channel blocks the thread until
    // some other thread has sent us data
    
    let (m, n) = (<-c, <-c)
    main { println(m) }
    main { println(n) }
}

// Executes first because "dispatch" waits for run loop
c <- "I DO SAY"


// Required to use async code in a command line application
dispatch_main()
