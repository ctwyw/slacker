package service

import (
	"errors"
	"{{.ProjectPath}}/gosrc/dao"
	"github.com/jmoiron/sqlx"
)

 
type Service struct {
	dao *dao.Dao
}

func New(db *sqlx.DB) *Service {
	return &Service{
		dao: dao.New(db),
	}
}
