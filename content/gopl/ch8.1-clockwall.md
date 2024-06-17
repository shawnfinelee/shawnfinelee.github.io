---
title: "go语言圣经-练习题Ch8.1-Clockwall世界时钟大盘"
date: 2024-06-17T12:22:04+08:00
draft: false
---

## 题目

修改[clock2](https://books.studygolang.com/gopl-zh/ch8/ch8-02.html)来支持传入参数作为端口号，然后写一个clockwall的程序，这个程序可以同时与多个clock服务器通信，从多个服务器中读取时间，并且在一个表格中一次显示所有服务器传回的结果，类似于你在某些办公室里看到的时钟墙。如果你有地理学上分布式的服务器可以用的话，让这些服务器跑在不同的机器上面；或者在同一台机器上跑多个不同的实例，这些实例监听不同的端口，假装自己在不同的时区。

``` bash
$ TZ=US/Eastern    ./clock2 -port 8010 &
$ TZ=Asia/Tokyo    ./clock2 -port 8020 &
$ TZ=Europe/London ./clock2 -port 8030 &
$ clockwall NewYork=localhost:8010 Tokyo=localhost:8020 London=localhost:8030
```

## 分析
CS结构的网络
服务端接受参数 port, 可以用 golang flag 标准库
定时通过网络io吐出时间

客户端接受参数 [city]:[host] 可以用 golang os.Args处理
一对多建立tcp连接，客户端维护一份大盘数据，预计会遇到并发写问题
客户端定时刷新 => 周期性打印大盘数据

## 解答
代码注释即编码思路

### 服务端
``` golang
package main

import (
	"flag"
	"io"
	"log"
	"net"
	"time"
)

var port string

func init() {
	flag.StringVar(&port, "port", "8000", "input port of the server")
}

// TZ=US/Eastern go run clock2.go -port 8010 &
// TZ=Europe/London go run clock2.go -port 8030 &
// TZ=Asia/Tokyo go run clock2.go -port 8020 &
func main() {
	flag.Parse()

	listener, err := net.Listen("tcp", "localhost:"+port)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("started a server, port: %s\n", port)

	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Print(err)
		}

		// 作为服务端可以接受多个客户端同时连接，不阻塞
		go handleConn(conn)
	}
}

func handleConn(conn net.Conn) {
	// 处理结束则本 goroutine 关闭
	defer conn.Close()
	for {
		// 一种奇葩的时间格式化方式（1234567法），倒是够直观
		_, err := io.WriteString(conn, time.Now().Format("15:04:05\n"))
		if err != nil {
			log.Print(err)
			return
		}
		time.Sleep(1 * time.Second)
	}
}
```

### 客户端
``` golang
package main

import (
	"bufio"
	"fmt"
	"log"
	"net"
	"os"
	"strings"
	"sync"
	"time"
)

// 可执行文件启动参数 clockwall NewYork=localhost:8010 Tokyo=localhost:8020 London=localhost:8030
// 解释执行启动参数 go run clockwall.go NewYork=localhost:8010 Tokyo=localhost:8020 London=localhost:8030
func main() {
	cityKeys := make([]string, 0)
	m := make(map[string]string) //[city]host
	var wall sync.Map            //[city]time 大盘数据

	// 解释执行程序后面的参数 NewYork=localhost:8010 Tokyo=localhost:8020 London=localhost:8030
	for _, item := range os.Args[1:] {
		cityHost := strings.Split(item, "=")
		m[cityHost[0]] = cityHost[1]

		cityKeys = append(cityKeys, cityHost[0])
	}

	// golang的 map range是随机的，不保证元素出现概率一致
	// goang的range map 是不可预期命中key值的，所以这里多使用一个存储城市列表的数组，配合实现map的有序遍历
	// 参考文章 https://blog.twofei.com/847/
	for i := 0; i < len(cityKeys); i++ {
		go func(city string, addr string) {
			conn, err := net.Dial("tcp", addr)
			if err != nil {
				log.Fatal(err)
			}
			defer conn.Close()

			scaner := bufio.NewScanner(conn)
			for scaner.Scan() {
				// 普通map非线程安全
				// 会产生 并发写问题 concurrent map writes
				wall.Store(city, scaner.Text())
			}
		}(cityKeys[i], m[cityKeys[i]])

	}

	for {
		// 大盘按照固定间隔刷新
		time.Sleep(2 * time.Second)
		var result string
		// 这里range m 或者 wall.Range() 都是随机出，不符合世界时间大盘的要求
		for i := 0; i < len(cityKeys); i++ {
			v, _ := wall.Load(cityKeys[i])
			result += fmt.Sprintf("%s:%s", cityKeys[i], v) + " "
		}
		fmt.Println(result)
	}
}
```

## 其他
小小的练习题有大大的宇宙
