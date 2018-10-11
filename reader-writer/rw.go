package main

import (
	"fmt"
	"math/rand"
	"sync"
	"time"
)

var (
	value     = 0
	rwlock    = sync.RWMutex{}
	readDone  = make(chan bool)
	writeDone = make(chan bool)
)

func read() {
	for i := 0; i < 100; i++ {
		time.Sleep(10 * time.Millisecond)
		rwlock.RLock()
		// fmt.Println("Read value ", value)
		rwlock.RUnlock()
	}
	readDone <- true
}

func write() {
	for i := 0; i < 100; i++ {
		time.Sleep(10 * time.Millisecond)
		rwlock.Lock()
		value = rand.Intn(100)
		// fmt.Println("Write value ", value)
		rwlock.Unlock()
	}
	writeDone <- true
}
func main() {
	var total float64
	rand.Seed(time.Now().UTC().UnixNano())
	start := time.Now()
	go read()
	go write()
	<-readDone
	<-writeDone
	elapsed := time.Since(start)
	total += elapsed.Seconds() * 1000.0
	fmt.Printf("Elapsed (ms): %s", elapsed)
}
