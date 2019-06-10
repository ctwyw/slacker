package service

import (
	"github.com/jmoiron/sqlx"
	"{{"gosrc/models"| .ImportLibrary}}/{{.Name}}"
)


func (s *Service)Take{{.CamelCaseName}}(id int64)({{.LowerName}}.{{.CamelCaseName}},error){ 
	data, err := s.dao.Take{{.CamelCaseName}}(id) 
	return data, err 
}


func (s *Service)List{{.CamelCaseName}}(offset,limit uint64)([]{{.LowerName}}.{{.CamelCaseName}},int,error){ 
	data,total,err := s.dao.List{{.CamelCaseName}}(offset,limit) 
	return data,total, err 
}

func (s *Service)Create{{.CamelCaseName}}({{.LowerName}} {{.LowerName}}.{{.CamelCaseName}})({{.LowerName}}.{{.CamelCaseName}},error){ 
	{{if .IsUserTable}}
		{{.LowerName}}.{{.UsernameColumn.CamelCaseName}} = strings.ToLower({{.LowerName}}.{{.UsernameColumn.CamelCaseName}})
		{{.LowerName}}.{{.PasswordColumn.CamelCaseName}} = s.EncryptPassword({{.LowerName}}.{{.PasswordColumn.CamelCaseName}})
		if s.dao.{{.CamelCaseName}}IsExist({{.LowerName}}.{{.UsernameColumn.CamelCaseName}}) {
			return {{.LowerName}}, errcode.IsExist
		}
	{{end}}
	data, err := s.dao.Create{{.CamelCaseName}}({{.LowerName}}) 
	return data, err 
}

func (s *Service)Update{{.CamelCaseName}}({{.LowerName}} {{.LowerName}}.{{.CamelCaseName}})error{ 
	  return s.dao.Update{{.CamelCaseName}}({{.LowerName}}) 
	 
}

func (s *Service)Patch{{.CamelCaseName}}(id int64,update map[string]interface{})error{ 
	{{if .IsUserTable}}
		if val, ok := update["{{.PasswordColumn.ColumnName}}"]; ok {
			password, ok := val.(string)
			if ok {
				password = s.EncryptPassword(password)
				update["{{.PasswordColumn.ColumnName}}"] = password
			}
		}
	{{end}}
	 return s.dao.Patch{{.CamelCaseName}}(id,update) 
}

func (s *Service)Delete{{.CamelCaseName}}(id int64)error{ 
	return s.dao.Delete{{.CamelCaseName}}(id)  
}

{{if .IsUserTable}}
func (s *Service) Take{{.CamelCaseName}}ByName(username string) ({{.LowerName}}.{{.CamelCaseName}}, error) { 
	return 	s.dao.Take{{.CamelCaseName}}ByName(username)  
}


func (_ *Service)EncryptPassword(password string) string {
	hashd, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(hashd)
}

func (_ *Service)ValidPassword(password,encryptedpwd string) bool {
	return nil == bcrypt.CompareHashAndPassword([]byte(encryptedpwd), []byte(password))
} 
{{end}}