package main

import (
	"fmt"
	"time"
)

var (
	channel = make(chan int)
	done    = make(chan bool)
	times   = 1000
)

func produce() {
	for i := 1; i <= times; i++ {
		fmt.Println("Produce item ", i)
		channel <- i
	}
	done <- true
}

func consume() {
	for {
		item := <-channel
		fmt.Println("Consume item ", item)
	}
}

func main() {
	var total float64
	for i := 0; i < 1; i++ {
		start := time.Now()
		go produce()
		go consume()
		<-done
		elapsed := time.Since(start)
		fmt.Printf("Total time avg %s", elapsed)
		total += elapsed.Seconds() * 1000.0
	}
}
