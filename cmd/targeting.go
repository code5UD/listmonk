package main

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/knadh/listmonk/internal/geo"
	"github.com/labstack/echo/v4"
)

// handleCreateTargetedCampaign creates a campaign with geographic targeting
func (a *App) CreateTargetedCampaign(c echo.Context) error {
	var req struct {
		Name            string                `json:"name" validate:"required"`
		Subject         string                `json:"subject" validate:"required"`
		Body            string                `json:"body" validate:"required"`
		TemplateID      int                   `json:"template_id"`
		ListIDs         []int                 `json:"list_ids"`
		TargetingFilter geo.TargetingFilter   `json:"targeting_filter"`
		Type            string                `json:"type" validate:"required"`
		ContentType     string                `json:"content_type"`
		Tags            []string              `json:"tags"`
		Headers         []map[string]string   `json:"headers"`
		SendAt          *string               `json:"send_at"`
	}

	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, 
			fmt.Sprintf("Invalid request: %v", err))
	}

	if err := a.validator.Struct(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, 
			fmt.Sprintf("Validation error: %v", err))
	}

	// Get targeted subscribers
	targetedSubscribers, err := a.geoSvc.GetTargetedSubscribers(req.TargetingFilter)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, 
			fmt.Sprintf("Error getting targeted subscribers: %v", err))
	}

	if len(targetedSubscribers) == 0 {
		return echo.NewHTTPError(http.StatusBadRequest, 
			"No subscribers match the targeting criteria")
	}

	// Create a temporary list for targeted subscribers
	listName := fmt.Sprintf("Targeted_%s_%d", req.Name, len(targetedSubscribers))
	tempList, err := a.createTemporaryList(listName, targetedSubscribers)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, 
			fmt.Sprintf("Error creating temporary list: %v", err))
	}

	// Create campaign with the temporary list
	campaign := struct {
		Name        string              `json:"name"`
		Subject     string              `json:"subject"`
		Body        string              `json:"body"`
		TemplateID  int                 `json:"template_id"`
		ListIDs     []int               `json:"list_ids"`
		Type        string              `json:"type"`
		ContentType string              `json:"content_type"`
		Tags        []string            `json:"tags"`
		Headers     []map[string]string `json:"headers"`
		SendAt      *string             `json:"send_at"`
	}{
		Name:        req.Name,
		Subject:     req.Subject,
		Body:        req.Body,
		TemplateID:  req.TemplateID,
		ListIDs:     []int{tempList.ID},
		Type:        req.Type,
		ContentType: req.ContentType,
		Tags:        append(req.Tags, "geo-targeted"),
		Headers:     req.Headers,
		SendAt:      req.SendAt,
	}

	// Use existing campaign creation logic
	return a.handleCreateCampaign(c, campaign)
}

// handleGetTargetingStats returns statistics for geographic targeting
func (a *App) GetTargetingStats(c echo.Context) error {
	// Parse query parameters for filtering
	var filter geo.TargetingFilter
	
	if deptCodes := c.QueryParam("department_codes"); deptCodes != "" {
		filter.DepartmentCodes = parseStringArray(deptCodes)
	}
	
	if regions := c.QueryParam("regions"); regions != "" {
		filter.Regions = parseStringArray(regions)
	}
	
	if popMinStr := c.QueryParam("population_min"); popMinStr != "" {
		if popMin, err := strconv.Atoi(popMinStr); err == nil {
			filter.PopulationMin = &popMin
		}
	}
	
	if popMaxStr := c.QueryParam("population_max"); popMaxStr != "" {
		if popMax, err := strconv.Atoi(popMaxStr); err == nil {
			filter.PopulationMax = &popMax
		}
	}

	stats, err := a.geoSvc.GetTargetingStats(filter)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, 
			fmt.Sprintf("Error fetching targeting stats: %v", err))
	}

	return c.JSON(http.StatusOK, okResp{stats})
}

// handleGetDepartmentStats returns statistics by department
func (a *App) GetDepartmentStats(c echo.Context) error {
	stats, err := a.geoSvc.GetDepartmentStats()
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, 
			fmt.Sprintf("Error fetching department stats: %v", err))
	}

	return c.JSON(http.StatusOK, okResp{stats})
}

// handleGetPopulationRangeStats returns statistics by population ranges
func (a *App) GetPopulationRangeStats(c echo.Context) error {
	stats, err := a.geoSvc.GetPopulationRangeStats()
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, 
			fmt.Sprintf("Error fetching population range stats: %v", err))
	}

	return c.JSON(http.StatusOK, okResp{stats})
}

// handleBulkSubscriberUpdate updates multiple subscribers with geographic data
func (a *App) BulkSubscriberUpdate(c echo.Context) error {
	var req struct {
		SubscriberIDs []int               `json:"subscriber_ids" validate:"required"`
		Filter        geo.TargetingFilter `json:"filter"`
		Action        string              `json:"action" validate:"required"` // "add_to_list", "remove_from_list", "update_status"
		ListID        *int                `json:"list_id"`
		Status        *string             `json:"status"`
	}

	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, 
			fmt.Sprintf("Invalid request: %v", err))
	}

	if err := a.validator.Struct(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, 
			fmt.Sprintf("Validation error: %v", err))
	}

	// Get subscribers based on filter if no specific IDs provided
	var subscriberIDs []int
	if len(req.SubscriberIDs) > 0 {
		subscriberIDs = req.SubscriberIDs
	} else {
		subscribers, err := a.geoSvc.GetTargetedSubscribers(req.Filter)
		if err != nil {
			return echo.NewHTTPError(http.StatusInternalServerError, 
				fmt.Sprintf("Error getting targeted subscribers: %v", err))
		}
		
		for _, sub := range subscribers {
			subscriberIDs = append(subscriberIDs, sub.ID)
		}
	}

	if len(subscriberIDs) == 0 {
		return echo.NewHTTPError(http.StatusBadRequest, 
			"No subscribers found for the given criteria")
	}

	// Perform bulk action
	result, err := a.performBulkSubscriberAction(req.Action, subscriberIDs, req.ListID, req.Status)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, 
			fmt.Sprintf("Error performing bulk action: %v", err))
	}

	return c.JSON(http.StatusOK, okResp{result})
}

// Helper functions

func (a *App) createTemporaryList(name string, subscribers []geo.CommuneWithSubscriber) (*List, error) {
	// Create list
	list := List{
		Name:        name,
		Type:        "private",
		Description: "Temporary list for geographic targeting",
		Tags:        []string{"temporary", "geo-targeted"},
	}

	// Insert list
	query := `INSERT INTO lists (uuid, name, type, description, tags) 
			  VALUES (gen_random_uuid(), $1, $2, $3, $4) RETURNING id, uuid, created_at, updated_at`
	
	err := a.db.QueryRow(query, list.Name, list.Type, list.Description, pq.Array(list.Tags)).
		Scan(&list.ID, &list.UUID, &list.CreatedAt, &list.UpdatedAt)
	if err != nil {
		return nil, err
	}

	// Add subscribers to list
	for _, sub := range subscribers {
		if sub.SubscriberID > 0 {
			_, err := a.db.Exec(`INSERT INTO subscriber_lists (subscriber_id, list_id, status) 
								VALUES ($1, $2, 'confirmed') ON CONFLICT DO NOTHING`, 
								sub.SubscriberID, list.ID)
			if err != nil {
				a.log.Printf("Error adding subscriber %d to list %d: %v", sub.SubscriberID, list.ID, err)
			}
		}
	}

	return &list, nil
}

func (a *App) handleCreateCampaign(c echo.Context, campaign interface{}) error {
	// This would integrate with the existing campaign creation logic
	// For now, return a placeholder response
	return c.JSON(http.StatusOK, okResp{map[string]interface{}{
		"message": "Campaign creation with geographic targeting",
		"campaign": campaign,
	}})
}

func (a *App) performBulkSubscriberAction(action string, subscriberIDs []int, listID *int, status *string) (map[string]interface{}, error) {
	result := map[string]interface{}{
		"action": action,
		"affected_subscribers": len(subscriberIDs),
	}

	switch action {
	case "add_to_list":
		if listID == nil {
			return nil, fmt.Errorf("list_id is required for add_to_list action")
		}
		
		for _, subID := range subscriberIDs {
			_, err := a.db.Exec(`INSERT INTO subscriber_lists (subscriber_id, list_id, status) 
								VALUES ($1, $2, 'confirmed') ON CONFLICT DO NOTHING`, 
								subID, *listID)
			if err != nil {
				a.log.Printf("Error adding subscriber %d to list %d: %v", subID, *listID, err)
			}
		}
		result["list_id"] = *listID

	case "remove_from_list":
		if listID == nil {
			return nil, fmt.Errorf("list_id is required for remove_from_list action")
		}
		
		_, err := a.db.Exec(`DELETE FROM subscriber_lists 
							WHERE subscriber_id = ANY($1) AND list_id = $2`, 
							pq.Array(subscriberIDs), *listID)
		if err != nil {
			return nil, err
		}
		result["list_id"] = *listID

	case "update_status":
		if status == nil {
			return nil, fmt.Errorf("status is required for update_status action")
		}
		
		_, err := a.db.Exec(`UPDATE subscribers SET status = $1 WHERE id = ANY($2)`, 
							*status, pq.Array(subscriberIDs))
		if err != nil {
			return nil, err
		}
		result["new_status"] = *status

	default:
		return nil, fmt.Errorf("unknown action: %s", action)
	}

	return result, nil
}

// parseStringArray parses a comma-separated string into a slice
func parseStringArray(s string) []string {
	if s == "" {
		return nil
	}
	
	parts := strings.Split(s, ",")
	result := make([]string, 0, len(parts))
	
	for _, part := range parts {
		if trimmed := strings.TrimSpace(part); trimmed != "" {
			result = append(result, trimmed)
		}
	}
	
	return result
}