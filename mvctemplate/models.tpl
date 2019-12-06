//Generated by slacker
//table {{.Name}}
//SQL
//{{.StdSQL}}
//NamedSQL -> github.com/jmoiron/sqlx
//{{.NamedSQL}}
//Columns
//{{.SQLColumns}}
package {{.LowerName}}

const(
	StateOK=0
	StateDel=1
)
 
type {{.CamelCaseName}} struct{
    {{range $i,$col:=.Columns}} {{$col.CamelCaseName}} {{$col.Type}} {{$col.Tag}} {{$col.Comment}}
    {{end}}
}

{{if .IsUserTable}}
func ({{.Initials}} {{.CamelCaseName}}) MarshalJSON() ([]byte, error) {
	type tmp {{.CamelCaseName}}
	{{.Initials}}.{{.PasswordColumn.CamelCaseName}} = ""
	return json.Marshal(tmp({{.Initials}}))
}
{{end}}

func ({{.Initials}} {{.CamelCaseName}}) TableName() string { 
	return "{{.Name}}"
}

 

 
 
 
  