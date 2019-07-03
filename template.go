package slacker

import (
	"fmt"
	"path"
	"strings"

	"github.com/go-sql-driver/mysql"
	"github.com/lixiangzhong/log"
	"github.com/lixiangzhong/name"
)

type TemplateData struct {
	ProjectName string
	ProjectPath string
	MysqlConfig *mysql.Config
	DBName      string
	Tables      []Table
}

func (t TemplateData) HasUserTable() bool {
	for _, table := range t.Tables {
		if table.IsUserTable() {
			return true
		}
	}
	return false
}

func (t TemplateData) UserTable() Table {
	for _, table := range t.Tables {
		if table.IsUserTable() {
			return table
		}
	}
	return Table{Name: "user"}
}

type Table struct {
	Name           string
	CreateTableSQL string
	DBName         string
	Columns        []Column
}

//首字母
func (t Table) Initials() string {
	return strings.ToLower(string(t.Name[0]))
}

func (t Table) CamelCaseName() string {
	return name.CamelCase(t.Name)
}

func (t Table) CamelCaseNameWithDBName() string {
	return name.CamelCase(t.DBName) + name.CamelCase(t.Name)
}

func (t Table) LowerName() string {
	return strings.ToLower(t.CamelCaseName())
}

func (t Table) PrimaryKeyColumn() Column {
	for _, col := range t.Columns {
		if col.IsPrimaryKey() {
			return col
		}
	}
	return Column{ColumnName: "id"}
}

func (t Table) StateColumn() Column {
	for _, col := range t.Columns {
		if StringInSlice(col.ColumnName, StateFields) {
			return col
		}
	}
	return Column{ColumnName: "state"}
}

func (t Table) SQLColumns() string {
	var fields []string
	for _, col := range t.Columns {
		fields = append(fields, fmt.Sprintf("%v", col.ColumnName))
	}
	return strings.Join(fields, ",")
}

func (t Table) StdSQL() string {
	var fields []string
	for _, col := range t.Columns {
		if col.ColumnName == "id" || col.IsPrimaryKey() {
			continue
		}
		fields = append(fields, fmt.Sprintf("%v=?", col.ColumnName))
	}
	return strings.Join(fields, ",")
}

func (t Table) NamedSQL() string {
	var fields []string
	for _, col := range t.Columns {
		if col.ColumnName == "id" || col.IsPrimaryKey() {
			continue
		}
		fields = append(fields, fmt.Sprintf("%v=:%v", Quote(col.ColumnName), col.ColumnName))
	}
	return strings.Join(fields, ",")
}

func (t Table) SwitchCase() string {
	var fields []string
	for _, col := range t.Columns {
		fields = append(fields, fmt.Sprintf(`"%v"`, col.ColumnName))
	}
	return strings.Join(fields, ",")
}

func (t Table) ImportLibrary(dir string) string {
	return path.Join(ProjectPath(), dir)
}

func (t *Table) ShowCreateTable() {
	err := db.QueryRow("show create table "+t.Name).Scan(&t.Name, &t.CreateTableSQL)
	if err != nil {
		log.Error(err)
		return
	}
	t.CreateTableSQL = strings.Replace(t.CreateTableSQL, "CREATE TABLE", "CREATE TABLE IF NOT EXISTS", 1)
	fields := strings.Fields(t.CreateTableSQL)
	for i, v := range fields {
		if strings.Contains(v, "AUTO_INCREMENT=") {
			fields[i] = ""
			break
		}
	}
	t.CreateTableSQL = strings.Join(fields, " ")
}

func (t Table) AutomaticCreateUpdateExpression(obj string) string {
	var exp string
	fields := append(AutoAssignCreateFields, AutoAssignUpdateFields...)
	for _, col := range t.Columns {
		if StringInSlice(col.ColumnName, fields) {
			switch {
			case col.Type() == "time.Time":
				exp += fmt.Sprintf("%v.%v = %v\n", obj, col.CamelCaseName(), "timeNow")
			case strings.Contains(col.Type(), "int"):
				exp += fmt.Sprintf("%v.%v = %v\n", obj, col.CamelCaseName(), "timeNow.Unix()")
			}
		}
	}
	if exp != "" {
		exp = "var timeNow = time.Now()\n" + exp
	}
	return exp
}

func (t Table) AutomaticUpdateExpression(obj string) string {
	var exp string
	for _, col := range t.Columns {
		if StringInSlice(col.ColumnName, AutoAssignUpdateFields) {
			switch {
			case col.Type() == "time.Time":
				exp += fmt.Sprintf("%v.%v = %v\n", obj, col.CamelCaseName(), "timeNow")
			case strings.Contains(col.Type(), "int"):
				exp += fmt.Sprintf("%v.%v = %v\n", obj, col.CamelCaseName(), "timeNow.Unix()")
			}
		}
	}
	if exp != "" {
		exp = "var timeNow = time.Now()\n" + exp
	}
	return exp
}

func (t Table) AutomaticUpdateMapExpression() string {
	var exp string
	for _, col := range t.Columns {
		if StringInSlice(col.ColumnName, AutoAssignUpdateFields) {
			switch {
			case col.Type() == "time.Time":
				exp += fmt.Sprintf(`update["%v"] = %v`, col.ColumnName, "timeNow\n")
			case strings.Contains(col.Type(), "int"):
				exp += fmt.Sprintf(`update["%v"] = %v`, col.ColumnName, "timeNow.Unix()\n")
			}
		}
	}
	if exp != "" {
		exp = "var timeNow = time.Now()\n" + exp
	}
	return exp
}

func (t Table) HasStateColumn() bool {
	for _, col := range t.Columns {
		if StringInSlice(col.ColumnName, StateFields) {
			return true
		}
	}
	return false
}

func (t Table) MethodTake() string {
	var s = fmt.Sprintf("func (d *Dao) Take%v(id int64) (%v.%v,error) {\n",
		t.CamelCaseName(), t.LowerName(), t.CamelCaseName(),
	)
	s += fmt.Sprintf("var _%v %v.%v\n", t.LowerName(), t.LowerName(), t.CamelCaseName())
	if t.HasStateColumn() {
		s += fmt.Sprintf(`err:=d.db.Get(&_%v,"select * from %v where %v=? and %v!=? limit 1",id,%v.StateDel)`,
			t.LowerName(), t.Name, t.PrimaryKeyColumn().ColumnName, t.StateColumn().ColumnName, t.LowerName(),
		)
	} else {
		s += fmt.Sprintf(`err:=d.db.Get(&_%v,"select * from %v where %v=? limit 1",id)`,
			t.LowerName(), t.Name, t.PrimaryKeyColumn().ColumnName,
		)
	}
	s += fmt.Sprintf("\n return _%v,err", t.LowerName())
	s += "}"
	return s
}

func (t Table) MethodDelete() string {
	s := fmt.Sprintf("func (d *Dao) Delete%v(id int64) error {\n", t.CamelCaseName())
	s += fmt.Sprintf("var _%v %v.%v\n", t.LowerName(), t.LowerName(), t.CamelCaseName())
	s += fmt.Sprintf("_%v.%v=id\n", t.LowerName(), t.PrimaryKeyColumn().CamelCaseName())
	var updatedfields []string
	for _, col := range t.Columns {
		if StringInSlice(col.ColumnName, AutoAssignUpdateFields) {
			updatedfields = append(updatedfields, col.ColumnName)
		}
	}

	switch {
	case t.HasStateColumn() && updatedfields == nil,
		!t.HasStateColumn():
		s += fmt.Sprintf(` _,err := d.db.Exec("delete from %v where %v=?",id)`,
			t.Name, t.PrimaryKeyColumn().ColumnName,
		)
	case t.HasStateColumn() && updatedfields != nil:
		s += "var timeNow = time.Now()\n"
		var namedfields = make([]string, 0)
		for _, field := range updatedfields {
			namedfields = append(namedfields, fmt.Sprintf("`%v`=:%v", field, field))

			for _, col := range t.Columns {
				if col.ColumnName == field {
					switch col.Type() {
					case "time.Time":
						s += fmt.Sprintf("_%v.%v=timeNow\n", t.LowerName(), name.CamelCase(field))
					case "int64":
						s += fmt.Sprintf("_%v.%v=timeNow.Unix()\n", t.LowerName(), name.CamelCase(field))
					}
				}
			}
		}
		s += fmt.Sprintf("_%v.%v=%v.StateDel\n", t.LowerName(), t.StateColumn().CamelCaseName(), t.LowerName())
		s += fmt.Sprintf(` _,err := d.db.NamedExec("update %v set %v=:%v,`+strings.Join(namedfields, ",")+` where %v=:%v",_%v)`,
			t.Name,
			Quote(t.StateColumn().ColumnName), t.StateColumn().ColumnName,
			Quote(t.PrimaryKeyColumn().ColumnName), t.PrimaryKeyColumn().ColumnName,
			t.LowerName(),
		)
	}

	s += fmt.Sprintf("\n return err")
	s += "}"
	return s
}

func (t Table) IsUserTable() bool {
	var hasusername bool
	var haspassword bool
	for _, c := range t.Columns {
		if StringInSlice(c.ColumnName, UsernameFields) {
			hasusername = true
			continue
		}
		if StringInSlice(c.ColumnName, PasswordFields) {
			haspassword = true
			continue
		}
	}
	return hasusername && haspassword
}

func (t Table) UsernameColumn() Column {
	for _, c := range t.Columns {
		if StringInSlice(c.ColumnName, UsernameFields) {
			return c
		}
	}
	return Column{ColumnName: "username"}
}

func (t Table) PasswordColumn() Column {
	for _, c := range t.Columns {
		if StringInSlice(c.ColumnName, PasswordFields) {
			return c
		}
	}
	return Column{ColumnName: "password"}
}

type Column struct {
	ColumnName    string `json:"column_name" db:"column_name"`
	DataType      string `json:"data_type" db:"data_type"`
	ColumnType    string `json:"column_type" db:"column_type"`
	ColumnComment string `json:"column_comment" db:"column_comment"`
	ColumnKey     string `json:"column_key" db:"column_key"`
}

func (c Column) CamelCaseName() string {
	return name.CamelCase(c.ColumnName)
}

func (c Column) Tag() string {
	var index string
	if c.IsPrimaryKey() {
		index = "PRIMARY_KEY"
		c.ColumnType += " AUTO_INCREMENT"
	} else {
		switch c.ColumnKey {
		case "UNI":
			index = "UNIQUE"
		case "MUL":
			index = "index:idx_" + c.ColumnName
		}
	}
	return fmt.Sprintf("`%v`", fmt.Sprintf(`json:"%v" db:"%v" form:"%v" gorm:"column:%v;type:%v;not null%v"`,
		c.ColumnName, c.ColumnName, c.ColumnName,
		//gorm
		c.ColumnName, //column
		c.ColumnType, //type
		addSemicolonPrefixIfExist(index),
	))
}

func (c Column) Comment() string {
	if strings.TrimSpace(c.ColumnComment) == "" {
		return ""
	}
	return fmt.Sprintf("// %v", c.ColumnComment)
}

func (c Column) Type() string {
	name := strings.ToLower(c.ColumnName)
	t := c.ColumnType
	switch {
	case strings.Contains(t, "int"):
		if c.IsPrimaryKey() {
			return "int64"
		}
		return guessDataType(name)
	case strings.Contains(t, "char"), strings.Contains(t, "text"):
		return "string"
	case "timestamp" == t:
		return "time.Time"
	case strings.Contains(t, "float"):
		return "float64"
	}
	return "interface{}"
}

func guessDataType(name string) string {
	switch {
	case likeTimeUnix(name):
		return "int64"
	case strings.Contains(name, "id"):
		return "int64"
	case strings.Contains(name, "ip"):
		return "uint32"
	case strings.Contains(name, "net"):
		return "uint32"
	}
	return "int"
}

func likeTimeUnix(s string) bool {
	switch {
	case strings.Contains(s, "time"):
	case strings.Contains(s, "create"):
	case strings.Contains(s, "update"):
	default:
		return false
	}
	return true
}

func (c Column) IsPrimaryKey() bool {
	return c.ColumnKey == "PRI"
}

func addSemicolonPrefixIfExist(s string) string {
	if s == "" {
		return s
	}
	return ";" + s
}

var (
	AutoAssignFields []string

	AutoAssignCreateFields = []string{
		"ctime", "Ctime",
		"created", "Created",
		"create_time", "created_time",
		"created_at", "create_at", "createdAt", "createAt",
		"addtime", "AddTime",
	}

	AutoAssignUpdateFields = []string{
		"utime", "Utime",
		"updated", "Updated",
		"update_time", "updated_time",
		"updated_at", "update_at", "updatedAt", "updateAt",
	}

	AutoAssignDeleteFields = []string{
		"dtime", "Dtime",
		"deleted", "Deleted",
		"delete_time", "deleted_time",
		"deletetime", "DeleteTime",
		"deleted_at", "delete_at", "deletedAt", "deleteAt",
	}

	StateFields = []string{
		"state", "status",
	}

	UsernameFields = []string{
		"user", "username",
	}
	PasswordFields = []string{
		"passwd", "password",
	}
)

func init() {
	AutoAssignFields = append(AutoAssignFields, AutoAssignCreateFields...)
	AutoAssignFields = append(AutoAssignFields, AutoAssignUpdateFields...)
	AutoAssignFields = append(AutoAssignFields, AutoAssignDeleteFields...)
}
