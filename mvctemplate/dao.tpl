//Generated by slacker
package dao

import (
//sq	"github.com/Masterminds/squirrel"
"{{"gosrc/models"| .ImportLibrary}}/{{.Name}}" 
)

func (d *Dao) List{{.CamelCaseName}}(where  ...func(*gorm.DB)*gorm.DB) ([]{{.LowerName}}.{{.CamelCaseName}},int,error) {
    var data =make([]{{.LowerName}}.{{.CamelCaseName}},0)
    var total int
	err :=d.gorm.Model({{.LowerName}}.{{.CamelCaseName}}{}).Count(&total).Scopes(where...).Find(&data).Error
    return data,total,err
}

{{.MethodTake}}

func (d *Dao) Create{{.CamelCaseName}}(data *{{.LowerName}}.{{.CamelCaseName}}) error{
 	
    return d.gorm.Create(data).Error
}

func (d *Dao) Update{{.CamelCaseName}}({{.LowerName}} {{.LowerName}}.{{.CamelCaseName}}) error {

   // _,err := d.db.NamedExec("update {{.Name}} set {{.NamedSQL}} where {{.PrimaryKeyColumn.ColumnName}}=:{{.PrimaryKeyColumn.ColumnName}}",{{.LowerName}}) 
    return  d.gorm.Save(&{{.LowerName}}).Error
}

func (d *Dao) Patch{{.CamelCaseName}}(id int64,update map[string]interface{}) error {
  
  	var data {{.LowerName}}.{{.CamelCaseName}}
  	data.{{.PrimaryKeyColumn.CamelCaseName}}=id 
	return d.gorm.Model(data).Updates(update).Error
}


{{.MethodDelete}}



{{if .IsUserTable}} 

func (d *Dao) Take{{.CamelCaseName}}ByName(data *{{.LowerName}}.{{.CamelCaseName}}) error { 
	data.{{.UsernameColumn.CamelCaseName }} = strings.ToLower(data.{{.UsernameColumn.CamelCaseName }})  
	err := d.gorm.Where("{{.UsernameColumn.ColumnName }}=?","data.{{.UsernameColumn.CamelCaseName }}").First(data).Error
	return  err
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