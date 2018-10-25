package controllers

import (
	"github.com/gin-gonic/gin"
	"github.com/lixiangzhong/base64Captcha"
	"net/http"
)

var CaptchaConfig = base64Captcha.ConfigCharacter{
	Height:             40,
	Width:              120,
	Mode:               base64Captcha.CaptchaModeNumber,
	ComplexOfNoiseText: base64Captcha.CaptchaComplexLower,
	ComplexOfNoiseDot:  base64Captcha.CaptchaComplexLower,
	IsUseSimpleFont:    true,
	IsShowHollowLine:   true,
	IsShowNoiseDot:     true,
	IsShowNoiseText:    false,
	IsShowSlimeLine:    false,
	IsShowSineLine:     false,
	CaptchaLen:         4,
}

type Captcha struct {
}

func (_ Captcha) Get(c *gin.Context) {
	id, catpcha := base64Captcha.GenerateCaptcha("", CaptchaConfig)
	c.JSON(http.StatusOK, JSON.OK(gin.H{
		"captcha_id":   id,
		"captcha_data": base64Captcha.CaptchaWriteToBase64Encoding(catpcha),
	}))
}
