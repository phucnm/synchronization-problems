package main

import (
	"fmt"
	"math/rand"
	"sync"
	"time"
)

var (
	// done = make(chan bool)
	wg = sync.WaitGroup{}
)

type gender string

const (
	male   gender = "male"
	female gender = "female"
)

type person struct {
	Gender gender
	id     int
}

type bathroom struct {
	m       chan person
	f       chan person
	exit    chan person
	males   int
	females int
}

func (p person) UseBathroom(in, out chan person) {
	in <- p
	time.Sleep(time.Duration(250+rand.Intn(100)) * time.Millisecond)
	fmt.Printf("Person %+v exit\n", p)
	out <- p
}

func (b *bathroom) Service() {
	m := b.m
	f := b.f
	for {
		select {
		case p := <-m:
			fmt.Printf("Person %+v using the bathroom\n", p)
			b.males++
			// fmt.Println("Nil out females channel")
			f = nil
			if b.males == 3 {
				m = nil
			}
		case p := <-f:
			fmt.Printf("Person %+v using the bathroom\n", p)
			b.females++
			// fmt.Println("Nil out males channel")
			m = nil
			if b.females == 3 {
				f = nil
			}
		case p := <-b.exit:
			fmt.Printf("Person %+v done\n", p)
			switch p.Gender {
			case male:
				b.males--
				m = b.m
				if b.males == 0 {
					f = b.f
				}
			case female:
				b.females--
				f = b.f
				if b.females == 0 {
					m = b.m
				}
			}
		}
	}
}

func maleBath(count int, bath *bathroom) {
	for i := 0; i < count; i++ {
		m := person{male, i}
		go func() {
			m.UseBathroom(bath.m, bath.exit)
			wg.Done()
		}()
	}
}

func femaleBath(count int, bath *bathroom) {
	for i := 0; i < count; i++ {
		m := person{female, i}
		go func() {
			m.UseBathroom(bath.f, bath.exit)
			wg.Done()
		}()

	}
}

func main() {
	var bath = bathroom{}
	bath.m = make(chan person, 3)
	bath.f = make(chan person, 3)
	bath.exit = make(chan person, 3)
	wg.Add(20)
	go bath.Service()
	go maleBath(10, &bath)
	go femaleBath(10, &bath)
	wg.Wait()
}
