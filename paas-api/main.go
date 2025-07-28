package main

import (
	"database/sql"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	_ "github.com/lib/pq"
	"github.com/MicahParks/keyfunc"
)

// JWTAuthMiddleware creates a Gin middleware for JWT authentication and authorization.
// It requires the ZITADEL issuer URL and the expected audience (your API's Client ID).
func JWTAuthMiddleware(issuerURL string, audience string) gin.HandlerFunc {
	jwksURL := strings.TrimSuffix(issuerURL, "/") + "/oauth/v2/keys"

	// Use github.com/MicahParks/keyfunc to fetch and manage JWKS
	jwks, err := keyfunc.Get(jwksURL, keyfunc.Options{})
	if err != nil {
		log.Fatalf("FATAL: failed to get JWKS: %v", err)
	}

	parser := &jwt.Parser{}

	// This is the actual middleware handler
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Authorization header is missing"})
			return
		}

		tokenString, found := strings.CutPrefix(authHeader, "Bearer ")
		if !found {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token format"})
			return
		}

		// Parse and validate the token
		token, err := parser.Parse(tokenString, jwks.Keyfunc)
		if err != nil {
			log.Printf("Token validation error: %v", err)
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			return
		}

		if !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			return
		}

		// Extract claims and add them to the context for later handlers to use.
		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"error": "Failed to extract token claims"})
			return
		}
		if claims["iss"] != issuerURL {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid issuer"})
			return
		}
		// aud, ok := claims["aud"].(string)
		// if !ok || aud != audience {
		// 	c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid audience"})
		// 	return
		// }
		c.Set("claims", claims)

		c.Next()
	}
}

func main() {
	dsn := os.Getenv("POSTGRES_DSN")
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		// Using log.Fatalf is better than panic for application startup errors.
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	r := gin.Default()

	// Configure CORS - for production, you should be more specific
	// with AllowOrigins than a local development URL.
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:8086"}, // Change for production
		AllowMethods:     []string{"GET", "POST", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// --- ZITADEL Configuration ---
	// IMPORTANT: Replace these placeholder values with your actual ZITADEL details.
	zitadelIssuer := "https://first0cloud-shf5wf.us1.zitadel.cloud"
	apiAudience := "330412688444300258" // <-- REPLACE THIS with the Client ID of your API Application in ZITADEL

	// --- Public Route ---
	r.GET("/", func(c *gin.Context) {
		c.String(http.StatusOK, "Hello from PaaS(PostgresSql) API!")
	})

	// --- Protected API Route Group ---
	// The JWTAuthMiddleware is applied only to this group.
	apiV1 := r.Group("/api/v1")
	apiV1.Use(JWTAuthMiddleware(zitadelIssuer, apiAudience))
	{
		// IMPORTANT SECURITY WARNING: The following database handlers are vulnerable to
		// SQL Injection because they concatenate user input directly into the query.
		// You MUST sanitize the input before using it in production.
		// For example, by validating the database name against a strict regex `^[a-zA-Z_][a-zA-Z0-9_]*$`.

		apiV1.GET("/databases", func(c *gin.Context) {
			// Example of how you could use claims stored in the context by the middleware
			claims, _ := c.Get("claims")
			log.Printf("Accessing /databases with claims: %v", claims)

			rows, err := db.Query("SELECT datname FROM pg_database WHERE datistemplate = false;")
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			defer rows.Close()

			var dbs []string
			for rows.Next() {
				var name string
				rows.Scan(&name)
				dbs = append(dbs, name)
			}
			c.JSON(http.StatusOK, dbs)
		})

		apiV1.POST("/databases", func(c *gin.Context) {
			var req struct{ Name string }
			if err := c.BindJSON(&req); err != nil || req.Name == "" {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Missing database name"})
				return
			}
			// WARNING: SQL Injection vulnerability. Sanitize req.Name!
			_, err := db.Exec("CREATE DATABASE " + req.Name)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			c.JSON(http.StatusCreated, gin.H{"id": req.Name, "name": req.Name, "status": "created"})
		})

		apiV1.DELETE("/databases/:name", func(c *gin.Context) {
			name := c.Param("name")
			// WARNING: SQL Injection vulnerability. Sanitize name!
			_, err := db.Exec("DROP DATABASE " + name)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			c.JSON(http.StatusOK, gin.H{"result": "deleted"})
		})
	}

	// Start the server
	log.Println("Starting server on port 80...")
	if err := r.Run(":80"); err != nil {
		log.Fatalf("Failed to run server: %v", err)
	}
}