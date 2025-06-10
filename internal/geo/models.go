package geo

import (
	"time"

	"github.com/lib/pq"
	null "gopkg.in/volatiletech/null.v6"
)

// Department represents a French department
type Department struct {
	ID        int       `db:"id" json:"id"`
	Code      string    `db:"code" json:"code"`
	Name      string    `db:"name" json:"name"`
	Region    string    `db:"region" json:"region"`
	CreatedAt null.Time `db:"created_at" json:"created_at"`
	UpdatedAt null.Time `db:"updated_at" json:"updated_at"`
}

// Commune represents a French commune/municipality
type Commune struct {
	ID             int            `db:"id" json:"id"`
	InseeCode      string         `db:"insee_code" json:"insee_code"`
	Name           string         `db:"name" json:"name"`
	DepartmentCode string         `db:"department_code" json:"department_code"`
	Population     int            `db:"population" json:"population"`
	PostalCodes    pq.StringArray `db:"postal_codes" json:"postal_codes"`
	Latitude       null.Float64   `db:"latitude" json:"latitude"`
	Longitude      null.Float64   `db:"longitude" json:"longitude"`
	CreatedAt      null.Time      `db:"created_at" json:"created_at"`
	UpdatedAt      null.Time      `db:"updated_at" json:"updated_at"`

	// Joined fields
	DepartmentName string `db:"department_name" json:"department_name,omitempty"`
	Region         string `db:"region" json:"region,omitempty"`
}

// SubscriberCommune represents the association between a subscriber and a commune
type SubscriberCommune struct {
	SubscriberID int       `db:"subscriber_id" json:"subscriber_id"`
	CommuneID    int       `db:"commune_id" json:"commune_id"`
	CreatedAt    null.Time `db:"created_at" json:"created_at"`
}

// TargetingFilter represents filters for geographic targeting
type TargetingFilter struct {
	DepartmentCodes []string `json:"department_codes,omitempty"`
	PopulationMin   *int     `json:"population_min,omitempty"`
	PopulationMax   *int     `json:"population_max,omitempty"`
	Regions         []string `json:"regions,omitempty"`
	CommuneNames    []string `json:"commune_names,omitempty"`
	PostalCodes     []string `json:"postal_codes,omitempty"`
	
	// Advanced filtering with AND/OR operators
	AdvancedFilters *AdvancedTargetingFilter `json:"advanced_filters,omitempty"`
}

// AdvancedTargetingFilter represents complex filtering with AND/OR logic
type AdvancedTargetingFilter struct {
	Operator string                    `json:"operator"` // "AND" or "OR"
	Rules    []TargetingRule          `json:"rules"`
	Groups   []AdvancedTargetingFilter `json:"groups,omitempty"`
}

// TargetingRule represents a single targeting rule
type TargetingRule struct {
	Field    string      `json:"field"`    // "department", "population", "region", "commune_name", "postal_code"
	Operator string      `json:"operator"` // "eq", "ne", "gt", "gte", "lt", "lte", "in", "not_in", "contains", "not_contains"
	Value    interface{} `json:"value"`
}

// PopulationRange represents a population range filter
type PopulationRange struct {
	Min *int `json:"min,omitempty"`
	Max *int `json:"max,omitempty"`
}

// TargetingStats represents statistics for geographic targeting
type TargetingStats struct {
	TotalCommunes      int                    `json:"total_communes"`
	TotalSubscribers   int                    `json:"total_subscribers"`
	ByDepartment       map[string]int         `json:"by_department"`
	ByRegion           map[string]int         `json:"by_region"`
	ByPopulationRange  map[string]int         `json:"by_population_range"`
	AveragePopulation  float64                `json:"average_population"`
	PopulationRanges   []PopulationRangeStats `json:"population_ranges"`
}

// PopulationRangeStats represents statistics for a population range
type PopulationRangeStats struct {
	Range       string `json:"range"`
	Min         int    `json:"min"`
	Max         int    `json:"max"`
	Count       int    `json:"count"`
	Subscribers int    `json:"subscribers"`
}

// GeoStats represents general geographic statistics
type GeoStats struct {
	TotalDepartments int `json:"total_departments"`
	TotalCommunes    int `json:"total_communes"`
	TotalSubscribers int `json:"total_subscribers"`
	
	// Coverage statistics
	CommunesWithSubscribers int     `json:"communes_with_subscribers"`
	CoveragePercentage      float64 `json:"coverage_percentage"`
	
	// Population statistics
	TotalPopulation   int64   `json:"total_population"`
	AveragePopulation float64 `json:"average_population"`
	MedianPopulation  int     `json:"median_population"`
	
	// Regional breakdown
	RegionStats []RegionStat `json:"region_stats"`
}

// RegionStat represents statistics for a specific region
type RegionStat struct {
	Region           string  `json:"region"`
	Departments      int     `json:"departments"`
	Communes         int     `json:"communes"`
	Subscribers      int     `json:"subscribers"`
	TotalPopulation  int64   `json:"total_population"`
	CoveragePercent  float64 `json:"coverage_percent"`
}

// MairieCSVRecord represents a record from the CSV import file
type MairieCSVRecord struct {
	CommuneName    string `csv:"nom_commune"`
	InseeCode      string `csv:"code_insee"`
	DepartmentCode string `csv:"code_departement"`
	Population     int    `csv:"population"`
	Email          string `csv:"email"`
	ContactName    string `csv:"nom_contact"`
	ContactRole    string `csv:"contact_role"`
	Phone          string `csv:"phone"`
	Address        string `csv:"address"`
	PostalCode     string `csv:"code_postal"`
	Latitude       string `csv:"latitude"`
	Longitude      string `csv:"longitude"`
}

// ImportResult represents the result of a CSV import operation
type ImportResult struct {
	TotalRecords    int      `json:"total_records"`
	ImportedRecords int      `json:"imported_records"`
	SkippedRecords  int      `json:"skipped_records"`
	ErrorRecords    int      `json:"error_records"`
	Errors          []string `json:"errors,omitempty"`
	Duration        string   `json:"duration"`
	StartTime       time.Time `json:"start_time"`
	EndTime         time.Time `json:"end_time"`
}

// TargetingPreview represents a preview of targeting results
type TargetingPreview struct {
	Count           int                    `json:"count"`
	Filters         TargetingFilter        `json:"filters"`
	SampleCommunes  []Commune              `json:"sample_communes,omitempty"`
	Statistics      TargetingStats         `json:"statistics"`
	EstimatedReach  int                    `json:"estimated_reach"`
	PopulationTotal int64                  `json:"population_total"`
}

// CommuneWithSubscriber represents a commune with its subscriber information
type CommuneWithSubscriber struct {
	Commune
	SubscriberID    int    `db:"subscriber_id" json:"subscriber_id,omitempty"`
	SubscriberEmail string `db:"subscriber_email" json:"subscriber_email,omitempty"`
	SubscriberName  string `db:"subscriber_name" json:"subscriber_name,omitempty"`
	SubscriberStatus string `db:"subscriber_status" json:"subscriber_status,omitempty"`
}