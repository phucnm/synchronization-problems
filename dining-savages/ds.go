package main

import (
	"fmt"
	"sync"
	"time"
)

var (
	potEmpty = make(chan bool)
	potFull  = make(chan bool)
	servings = 100
	mu       = sync.Mutex{}
	wg       = sync.WaitGroup{}
)

func cook() {
	for {
		<-potEmpty
		servings = 100
		potFull <- true
	}
}

func eat(savage int) {
	mu.Lock()
	if servings == 0 {
		potEmpty <- true
		// fmt.Printf("Savage %d, pot is empty, filling", savage)
		<-potFull
	}
	// fmt.Printf("Current servings: %d, savage %d is eating\n", servings, savage)
	servings--
	mu.Unlock()
	wg.Done()
}

func main() {
	start := time.Now()
	wg.Add(1000)
	go cook()
	for i := 1; i <= 1000; i++ {
		go eat(i)
	}
	wg.Wait()
	elapsed := time.Since(start)
	fmt.Printf("Total time %s", elapsed)
}
