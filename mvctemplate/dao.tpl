package dao

import (
sq	"github.com/Masterminds/squirrel"
"{{"gosrc/models"| .ImportLibrary}}/{{.Name}}"
)

func (d *Dao) List{{.CamelCaseName}}(offset,limit uint64) ([]{{.LowerName}}.{{.CamelCaseName}},int,error) {
    var data =make([]{{.LowerName}}.{{.CamelCaseName}},0)
    var total int
	var where sq.And
	{{if Contains .SwitchCase "state"}}
		where = append(where, sq.NotEq{"state":{{.LowerName}}.StateDel })
	{{end}}
	q, args, _ := sq.Select("count({{.PrimaryKeyColumn.ColumnName}})").From("{{.Name}}").Where(where).ToSql()
    err:=d.db.Get(&total,q,args...)
    if err!=nil{
        return data,total,err
    }
	builder:= sq.Select("*").From("{{.Name}}").Where(where).OrderBy("{{.PrimaryKeyColumn.ColumnName}} desc")
	if limit>0{
	builder=builder.Limit(limit)
	}
	if offset>0{
	builder=builder.Offset(offset)
	}
	q,args,_ = builder.ToSql()
    err=d.db.Select(&data,q,args...)
    return data,total,err
}

{{.MethodTake}}

func (d *Dao) Create{{.CamelCaseName}}({{.LowerName}} {{.LowerName}}.{{.CamelCaseName}})({{.LowerName}}.{{.CamelCaseName}}, error ){
 	{{.LowerName | .AutomaticCreateUpdateExpression}}


    result,err := d.db.NamedExec("insert into {{.Name}} set {{.NamedSQL}}",{{.LowerName}})
	if err!=nil{
		return {{.LowerName}},err
	}
	{{.LowerName}}.{{.PrimaryKeyColumn.CamelCaseName}},err=result.LastInsertId()
    return {{.LowerName}}, err
}

func (d *Dao) Update{{.CamelCaseName}}({{.LowerName}} {{.LowerName}}.{{.CamelCaseName}}) error {
	 {{.LowerName | .AutomaticUpdateExpression}}
    _,err := d.db.NamedExec("update {{.Name}} set {{.NamedSQL}} where {{.PrimaryKeyColumn.ColumnName}}=:{{.PrimaryKeyColumn.ColumnName}}",{{.LowerName}})
    return err
}

func (d *Dao) Patch{{.CamelCaseName}}(id int64,update map[string]interface{}) error {
  {{.AutomaticUpdateMapExpression}}
	var named []string
	for k := range update {
		switch k {
	   case {{.SwitchCase}}:
			named = append(named, fmt.Sprintf("`%s`=:%s", k, k))
		}
	}
	if len(named) == 0 {
		return nil
	}

	fields := strings.Join(named, ",")
	update["{{.PrimaryKeyColumn.ColumnName}}"] = id
	_, err := d.db.NamedExec("update {{.Name}} set "+ fields +" where {{.PrimaryKeyColumn.ColumnName}}=:{{.PrimaryKeyColumn.ColumnName}}", update)
	return err
}


{{.MethodDelete}}



{{if .IsUserTable}} 

func (d *Dao) Take{{.CamelCaseName}}ByName(username string) ({{.LowerName}}.{{.CamelCaseName}}, error) {
    var {{.LowerName}} {{.LowerName}}.{{.CamelCaseName}}
	username = strings.ToLower(username)
	SQL := "select * from {{.Name}} where {{.UsernameColumn.ColumnName }}=? limit 1"
	err := d.db.Get(&{{.LowerName}}, SQL, username)
	return {{.LowerName}}, err
}

func (d *Dao) {{.CamelCaseName}}IsExist(username string) bool {
	SQL := "select 1 from {{.Name}} where {{.UsernameColumn.ColumnName}}=? limit 1"
	var exist bool
	err := d.db.QueryRow(SQL,username).Scan(&exist)
	if err != nil && err != sql.ErrNoRows {
		return true
	}
	return exist
}

{{end}}