package slacker

import (
	"fmt"
	"github.com/go-sql-driver/mysql"
	"github.com/jmoiron/sqlx"
	"github.com/lixiangzhong/slacker/bindata"
	"github.com/urfave/cli"
	"os"
	"time"
)

var (
	db *sqlx.DB
)

func New() cli.Command {
	return cli.Command{
		Name:  "new",
		Usage: "create new project",
		Flags: []cli.Flag{
			DBAddrFlags,
			DBUserFlags,
			DBPasswdFlags,
			DBNameFlags,
		},
		Action: func(c *cli.Context) error {
			projectname := c.Args().First()
			if projectname == "" {
				return cli.NewExitError("missing project name", 0)
			}
			if InGOPATH() == false {
				return cli.NewExitError("current workdir is not inside $GOPATH/src", 0)
			}
			if err := Mkdir(projectname); err != nil {
				return cli.NewExitError(err, 1)
			}
			if err := os.Chdir(projectname); err != nil {
				return cli.NewExitError(err, 1)
			}
			var mysqlconfig = MysqlConfig(c)
			if err := ConnectDB(mysqlconfig); err != nil {
				return cli.NewExitError(err, 1)
			}
			tables := Tables(mysqlconfig.DBName)
			var tpldata TemplateData
			tpldata.ProjectName = projectname
			tpldata.ProjectPath = ProjectPath()
			tpldata.MysqlConfig = mysqlconfig
			tpldata.Tables = tables
			fmt.Printf("Creating %v Project...\n", projectname)
			if err := bindata.Restore(tpldata); err != nil {
				return cli.NewExitError(err, 1)
			}
			for _, table := range tables {
				table.ExecTemplate("m")
				table.ExecTemplate("v")
				table.ExecTemplate("c")
				table.ExecTemplate("js")
				// table.ExecTemplate("sql")
			}
			fmt.Printf("\nProject %v Successfully Created !!!\n\n", projectname)
			fmt.Println("Install npm dependency packages:")
			fmt.Println("\tcd", projectname)
			fmt.Println("\tnpm install")
			fmt.Println("How to run:")
			fmt.Println("\tnpm run dev")
			fmt.Printf("\tgo run %v.go\n", projectname)
			fmt.Println("How to build")
			fmt.Println("\tnpm run build")
			fmt.Println("\tmake build")

			return nil
		},
	}

}

func MysqlConfig(c *cli.Context) *mysql.Config {
	var cfg = mysql.NewConfig()
	cfg.Addr = c.String("addr")
	cfg.User = c.String("user")
	cfg.Passwd = c.String("passwd")
	cfg.DBName = c.String("db")
	cfg.Net = "tcp"
	cfg.Loc = time.Local
	// cfg.ParseTime = true
	return cfg
}

func ConnectDB(cfg *mysql.Config) error {
	var err error
	db, err = sqlx.Connect("mysql", cfg.FormatDSN())
	return err
}
