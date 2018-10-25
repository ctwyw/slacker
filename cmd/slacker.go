package main

import (
	"github.com/lixiangzhong/slacker"
	"github.com/urfave/cli"
	"os"
)

func main() {
	app := cli.NewApp()

	app.Commands = []cli.Command{
		slacker.New(),
	}

	app.Run(os.Args)
}
