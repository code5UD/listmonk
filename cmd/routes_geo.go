package main

import (
	"github.com/labstack/echo/v4"
)

// registerGeoRoutes registers all geographic and targeting routes
func (a *App) registerGeoRoutes(g *echo.Group) {
	// Geographic data routes
	g.GET("/departments", a.GetDepartments)
	g.GET("/communes", a.GetCommunes)
	g.GET("/communes/search", a.SearchCommunes)
	g.GET("/stats", a.GetGeoStats)
	
	// Targeting routes
	g.POST("/targeting/preview", a.TargetingPreview)
	g.POST("/targeting/count", a.TargetingCount)
	g.GET("/targeting/stats", a.GetTargetingStats)
	g.GET("/targeting/departments", a.GetDepartmentStats)
	g.GET("/targeting/population-ranges", a.GetPopulationRangeStats)
	
	// Campaign targeting routes
	g.POST("/campaigns/targeted", a.CreateTargetedCampaign)
	
	// Bulk operations
	g.POST("/subscribers/bulk-update", a.BulkSubscriberUpdate)
	
	// Import routes
	g.POST("/import", a.ImportMairies)
	
	// Subscriber-commune association routes
	g.GET("/subscribers/:id/communes", a.GetSubscriberCommunes)
	g.POST("/subscribers/:id/communes/:commune_id", a.AddSubscriberToCommune)
	g.DELETE("/subscribers/:id/communes/:commune_id", a.RemoveSubscriberFromCommune)
}