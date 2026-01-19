package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type Product struct {
	gorm.Model
	ID     uint   `gorm:"primaryKey" json:"id"`
	Name   string `json:"name"`
	Price  uint   `json:"price"`
	UserID string `gorm:"column:user_id" json:"userId"`
}

// AIRequest はAIへのリクエストボディの構造体
type AIRequest struct {
	Items []string `json:""items`
}

func main() {
	// ローカル環境用に.envファイルを読み込む
	err := godotenv.Load()
	if err != nil {
		log.Println(".env file not found. Using system environment variables.")
	}

	// --- ポート番号の取得(Render) ---
	appPort := os.Getenv("PORT")
	if appPort == "" {
		appPort = "8000"
	}
	// --- DB接続設定 で、クラウド環境とローカル環境の両方に対応 ---
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		host := os.Getenv("DB_HOST")
		user := os.Getenv("DB_USER")
		password := os.Getenv("DB_PASSWORD")
		dbname := os.Getenv("DB_NAME")
		dbPort := os.Getenv("DB_PORT")
		dsn = fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
			host, user, password, dbname, dbPort)
	}

	// --- GORMでPostgreSQLに接続 ---
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		panic("DB接続失敗: " + err.Error())
	}

	fmt.Println("✅ DB接続成功")
	db.AutoMigrate(&Product{})

	// --- Ginのルーター設定 ---
	r := gin.Default()

	// --- ルーティング設定 ---
	r.StaticFS("/static", http.Dir("static"))
	r.StaticFile("/", "static/index.html")

	// --- APIエンドポイント設定 ---
	r.GET("/products", func(c *gin.Context) {
		userID := c.Query("userId")
		var products []Product

		fmt.Println("Searching for userID:", userID)

		if userID != "" {
			db.Where("user_id = ?", userID).Find(&products)
		} else {
			products = []Product{}
		}
		c.JSON(http.StatusOK, products)
	})

	r.POST("/products", func(c *gin.Context) {
		var newProduct Product

		// 1. 送られてきたJSONデータを Go の構造体に変換（Bind）
		if err := c.ShouldBindJSON(&newProduct); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// 2. DBに保存
		result := db.Create(&newProduct)
		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
			return
		}

		// 3. 保存したデータをレスポンスとして返す
		c.JSON(http.StatusOK, newProduct)
	})

	// --- /ask-recipe エンドポイント ---
	/**
		r.POST("/ask-recipe", func(c *gin.Context) {
			var aiRequest []AIRequest
			if err := c.Query()
		}
	**/

	r.DELETE("/products/:id", func(c *gin.Context) {
		id := c.Param("id")
		if err := db.Delete(&Product{}, id).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "削除に失敗しました"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "削除完了"})
	})

	// --- サーバー起動 (ポート8000で待ち受け) ---
	fmt.Printf("🚀 サーバーをポート %s で起動します...\n", appPort)
	r.Run(":" + appPort)
}
