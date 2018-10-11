let group = DispatchGroup()
group.enter()
let queue = DispatchQueue(label: "consumer-queue",
                          qos: .default,
                          attributes: [],
                          autoreleaseFrequency: .inherit,
                          target: nil)
let start = Date()
DispatchQueue.global().async {
    for i in 1...1000 {
        print("Produce item \(i)")
        queue.async {
            print("Consume item \(i)")
            if i == 1000 {
                print(Date().timeIntervalSince(start) * 1000)
                group.leave()
            }
        }
    }
}
group.wait()