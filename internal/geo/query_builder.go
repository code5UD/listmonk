package geo

import (
	"fmt"
	"strings"

	"github.com/lib/pq"
)

// QueryBuilder builds SQL queries for advanced targeting
type QueryBuilder struct {
	conditions []string
	args       []interface{}
	argIndex   int
}

// NewQueryBuilder creates a new query builder
func NewQueryBuilder() *QueryBuilder {
	return &QueryBuilder{
		conditions: make([]string, 0),
		args:       make([]interface{}, 0),
		argIndex:   1,
	}
}

// BuildAdvancedQuery builds a SQL WHERE clause from advanced targeting filters
func (qb *QueryBuilder) BuildAdvancedQuery(filter TargetingFilter) (string, []interface{}, error) {
	// Reset builder
	qb.conditions = make([]string, 0)
	qb.args = make([]interface{}, 0)
	qb.argIndex = 1

	// Handle legacy simple filters first
	if err := qb.addLegacyFilters(filter); err != nil {
		return "", nil, err
	}

	// Handle advanced filters
	if filter.AdvancedFilters != nil {
		advancedCondition, err := qb.buildAdvancedFilterGroup(*filter.AdvancedFilters)
		if err != nil {
			return "", nil, err
		}
		if advancedCondition != "" {
			qb.conditions = append(qb.conditions, advancedCondition)
		}
	}

	// Combine all conditions with AND
	var whereClause string
	if len(qb.conditions) > 0 {
		whereClause = strings.Join(qb.conditions, " AND ")
	}

	return whereClause, qb.args, nil
}

// addLegacyFilters adds the legacy simple filters for backward compatibility
func (qb *QueryBuilder) addLegacyFilters(filter TargetingFilter) error {
	// Department codes
	if len(filter.DepartmentCodes) > 0 {
		qb.conditions = append(qb.conditions, fmt.Sprintf("c.department_code = ANY($%d)", qb.argIndex))
		qb.args = append(qb.args, pq.Array(filter.DepartmentCodes))
		qb.argIndex++
	}

	// Population range
	if filter.PopulationMin != nil {
		qb.conditions = append(qb.conditions, fmt.Sprintf("c.population >= $%d", qb.argIndex))
		qb.args = append(qb.args, *filter.PopulationMin)
		qb.argIndex++
	}

	if filter.PopulationMax != nil {
		qb.conditions = append(qb.conditions, fmt.Sprintf("c.population <= $%d", qb.argIndex))
		qb.args = append(qb.args, *filter.PopulationMax)
		qb.argIndex++
	}

	// Regions
	if len(filter.Regions) > 0 {
		qb.conditions = append(qb.conditions, fmt.Sprintf("d.region = ANY($%d)", qb.argIndex))
		qb.args = append(qb.args, pq.Array(filter.Regions))
		qb.argIndex++
	}

	// Commune names
	if len(filter.CommuneNames) > 0 {
		nameConditions := make([]string, len(filter.CommuneNames))
		for i, name := range filter.CommuneNames {
			nameConditions[i] = fmt.Sprintf("c.name ILIKE $%d", qb.argIndex)
			qb.args = append(qb.args, "%"+name+"%")
			qb.argIndex++
		}
		qb.conditions = append(qb.conditions, "("+strings.Join(nameConditions, " OR ")+")")
	}

	// Postal codes
	if len(filter.PostalCodes) > 0 {
		qb.conditions = append(qb.conditions, fmt.Sprintf("c.postal_codes && $%d", qb.argIndex))
		qb.args = append(qb.args, pq.Array(filter.PostalCodes))
		qb.argIndex++
	}

	return nil
}

// buildAdvancedFilterGroup builds a SQL condition from an advanced filter group
func (qb *QueryBuilder) buildAdvancedFilterGroup(group AdvancedTargetingFilter) (string, error) {
	var conditions []string

	// Process rules
	for _, rule := range group.Rules {
		condition, err := qb.buildRuleCondition(rule)
		if err != nil {
			return "", err
		}
		if condition != "" {
			conditions = append(conditions, condition)
		}
	}

	// Process nested groups
	for _, nestedGroup := range group.Groups {
		nestedCondition, err := qb.buildAdvancedFilterGroup(nestedGroup)
		if err != nil {
			return "", err
		}
		if nestedCondition != "" {
			conditions = append(conditions, "("+nestedCondition+")")
		}
	}

	if len(conditions) == 0 {
		return "", nil
	}

	// Join conditions with the specified operator
	operator := " AND "
	if strings.ToUpper(group.Operator) == "OR" {
		operator = " OR "
	}

	return strings.Join(conditions, operator), nil
}

// buildRuleCondition builds a SQL condition from a single targeting rule
func (qb *QueryBuilder) buildRuleCondition(rule TargetingRule) (string, error) {
	var condition string
	var err error

	switch rule.Field {
	case "department":
		condition, err = qb.buildDepartmentCondition(rule)
	case "population":
		condition, err = qb.buildPopulationCondition(rule)
	case "region":
		condition, err = qb.buildRegionCondition(rule)
	case "commune_name":
		condition, err = qb.buildCommuneNameCondition(rule)
	case "postal_code":
		condition, err = qb.buildPostalCodeCondition(rule)
	default:
		return "", fmt.Errorf("unknown field: %s", rule.Field)
	}

	return condition, err
}

// buildDepartmentCondition builds a condition for department filtering
func (qb *QueryBuilder) buildDepartmentCondition(rule TargetingRule) (string, error) {
	switch rule.Operator {
	case "eq":
		condition := fmt.Sprintf("c.department_code = $%d", qb.argIndex)
		qb.args = append(qb.args, rule.Value)
		qb.argIndex++
		return condition, nil

	case "ne":
		condition := fmt.Sprintf("c.department_code != $%d", qb.argIndex)
		qb.args = append(qb.args, rule.Value)
		qb.argIndex++
		return condition, nil

	case "in":
		if values, ok := rule.Value.([]interface{}); ok {
			stringValues := make([]string, len(values))
			for i, v := range values {
				if s, ok := v.(string); ok {
					stringValues[i] = s
				} else {
					return "", fmt.Errorf("invalid department value: %v", v)
				}
			}
			condition := fmt.Sprintf("c.department_code = ANY($%d)", qb.argIndex)
			qb.args = append(qb.args, pq.Array(stringValues))
			qb.argIndex++
			return condition, nil
		}
		return "", fmt.Errorf("invalid value for 'in' operator: %v", rule.Value)

	case "not_in":
		if values, ok := rule.Value.([]interface{}); ok {
			stringValues := make([]string, len(values))
			for i, v := range values {
				if s, ok := v.(string); ok {
					stringValues[i] = s
				} else {
					return "", fmt.Errorf("invalid department value: %v", v)
				}
			}
			condition := fmt.Sprintf("c.department_code != ALL($%d)", qb.argIndex)
			qb.args = append(qb.args, pq.Array(stringValues))
			qb.argIndex++
			return condition, nil
		}
		return "", fmt.Errorf("invalid value for 'not_in' operator: %v", rule.Value)

	default:
		return "", fmt.Errorf("unsupported operator for department: %s", rule.Operator)
	}
}

// buildPopulationCondition builds a condition for population filtering
func (qb *QueryBuilder) buildPopulationCondition(rule TargetingRule) (string, error) {
	switch rule.Operator {
	case "eq":
		condition := fmt.Sprintf("c.population = $%d", qb.argIndex)
		qb.args = append(qb.args, rule.Value)
		qb.argIndex++
		return condition, nil

	case "ne":
		condition := fmt.Sprintf("c.population != $%d", qb.argIndex)
		qb.args = append(qb.args, rule.Value)
		qb.argIndex++
		return condition, nil

	case "gt":
		condition := fmt.Sprintf("c.population > $%d", qb.argIndex)
		qb.args = append(qb.args, rule.Value)
		qb.argIndex++
		return condition, nil

	case "gte":
		condition := fmt.Sprintf("c.population >= $%d", qb.argIndex)
		qb.args = append(qb.args, rule.Value)
		qb.argIndex++
		return condition, nil

	case "lt":
		condition := fmt.Sprintf("c.population < $%d", qb.argIndex)
		qb.args = append(qb.args, rule.Value)
		qb.argIndex++
		return condition, nil

	case "lte":
		condition := fmt.Sprintf("c.population <= $%d", qb.argIndex)
		qb.args = append(qb.args, rule.Value)
		qb.argIndex++
		return condition, nil

	case "between":
		if rangeVal, ok := rule.Value.(map[string]interface{}); ok {
			min, hasMin := rangeVal["min"]
			max, hasMax := rangeVal["max"]
			
			var conditions []string
			if hasMin {
				conditions = append(conditions, fmt.Sprintf("c.population >= $%d", qb.argIndex))
				qb.args = append(qb.args, min)
				qb.argIndex++
			}
			if hasMax {
				conditions = append(conditions, fmt.Sprintf("c.population <= $%d", qb.argIndex))
				qb.args = append(qb.args, max)
				qb.argIndex++
			}
			
			if len(conditions) > 0 {
				return "(" + strings.Join(conditions, " AND ") + ")", nil
			}
		}
		return "", fmt.Errorf("invalid value for 'between' operator: %v", rule.Value)

	default:
		return "", fmt.Errorf("unsupported operator for population: %s", rule.Operator)
	}
}

// buildRegionCondition builds a condition for region filtering
func (qb *QueryBuilder) buildRegionCondition(rule TargetingRule) (string, error) {
	switch rule.Operator {
	case "eq":
		condition := fmt.Sprintf("d.region = $%d", qb.argIndex)
		qb.args = append(qb.args, rule.Value)
		qb.argIndex++
		return condition, nil

	case "ne":
		condition := fmt.Sprintf("d.region != $%d", qb.argIndex)
		qb.args = append(qb.args, rule.Value)
		qb.argIndex++
		return condition, nil

	case "in":
		if values, ok := rule.Value.([]interface{}); ok {
			stringValues := make([]string, len(values))
			for i, v := range values {
				if s, ok := v.(string); ok {
					stringValues[i] = s
				} else {
					return "", fmt.Errorf("invalid region value: %v", v)
				}
			}
			condition := fmt.Sprintf("d.region = ANY($%d)", qb.argIndex)
			qb.args = append(qb.args, pq.Array(stringValues))
			qb.argIndex++
			return condition, nil
		}
		return "", fmt.Errorf("invalid value for 'in' operator: %v", rule.Value)

	case "not_in":
		if values, ok := rule.Value.([]interface{}); ok {
			stringValues := make([]string, len(values))
			for i, v := range values {
				if s, ok := v.(string); ok {
					stringValues[i] = s
				} else {
					return "", fmt.Errorf("invalid region value: %v", v)
				}
			}
			condition := fmt.Sprintf("d.region != ALL($%d)", qb.argIndex)
			qb.args = append(qb.args, pq.Array(stringValues))
			qb.argIndex++
			return condition, nil
		}
		return "", fmt.Errorf("invalid value for 'not_in' operator: %v", rule.Value)

	case "contains":
		condition := fmt.Sprintf("d.region ILIKE $%d", qb.argIndex)
		qb.args = append(qb.args, "%"+fmt.Sprintf("%v", rule.Value)+"%")
		qb.argIndex++
		return condition, nil

	case "not_contains":
		condition := fmt.Sprintf("d.region NOT ILIKE $%d", qb.argIndex)
		qb.args = append(qb.args, "%"+fmt.Sprintf("%v", rule.Value)+"%")
		qb.argIndex++
		return condition, nil

	default:
		return "", fmt.Errorf("unsupported operator for region: %s", rule.Operator)
	}
}

// buildCommuneNameCondition builds a condition for commune name filtering
func (qb *QueryBuilder) buildCommuneNameCondition(rule TargetingRule) (string, error) {
	switch rule.Operator {
	case "eq":
		condition := fmt.Sprintf("c.name = $%d", qb.argIndex)
		qb.args = append(qb.args, rule.Value)
		qb.argIndex++
		return condition, nil

	case "ne":
		condition := fmt.Sprintf("c.name != $%d", qb.argIndex)
		qb.args = append(qb.args, rule.Value)
		qb.argIndex++
		return condition, nil

	case "contains":
		condition := fmt.Sprintf("c.name ILIKE $%d", qb.argIndex)
		qb.args = append(qb.args, "%"+fmt.Sprintf("%v", rule.Value)+"%")
		qb.argIndex++
		return condition, nil

	case "not_contains":
		condition := fmt.Sprintf("c.name NOT ILIKE $%d", qb.argIndex)
		qb.args = append(qb.args, "%"+fmt.Sprintf("%v", rule.Value)+"%")
		qb.argIndex++
		return condition, nil

	case "in":
		if values, ok := rule.Value.([]interface{}); ok {
			stringValues := make([]string, len(values))
			for i, v := range values {
				if s, ok := v.(string); ok {
					stringValues[i] = s
				} else {
					return "", fmt.Errorf("invalid commune name value: %v", v)
				}
			}
			condition := fmt.Sprintf("c.name = ANY($%d)", qb.argIndex)
			qb.args = append(qb.args, pq.Array(stringValues))
			qb.argIndex++
			return condition, nil
		}
		return "", fmt.Errorf("invalid value for 'in' operator: %v", rule.Value)

	default:
		return "", fmt.Errorf("unsupported operator for commune_name: %s", rule.Operator)
	}
}

// buildPostalCodeCondition builds a condition for postal code filtering
func (qb *QueryBuilder) buildPostalCodeCondition(rule TargetingRule) (string, error) {
	switch rule.Operator {
	case "eq":
		condition := fmt.Sprintf("$%d = ANY(c.postal_codes)", qb.argIndex)
		qb.args = append(qb.args, rule.Value)
		qb.argIndex++
		return condition, nil

	case "ne":
		condition := fmt.Sprintf("NOT ($%d = ANY(c.postal_codes))", qb.argIndex)
		qb.args = append(qb.args, rule.Value)
		qb.argIndex++
		return condition, nil

	case "in":
		if values, ok := rule.Value.([]interface{}); ok {
			stringValues := make([]string, len(values))
			for i, v := range values {
				if s, ok := v.(string); ok {
					stringValues[i] = s
				} else {
					return "", fmt.Errorf("invalid postal code value: %v", v)
				}
			}
			condition := fmt.Sprintf("c.postal_codes && $%d", qb.argIndex)
			qb.args = append(qb.args, pq.Array(stringValues))
			qb.argIndex++
			return condition, nil
		}
		return "", fmt.Errorf("invalid value for 'in' operator: %v", rule.Value)

	case "not_in":
		if values, ok := rule.Value.([]interface{}); ok {
			stringValues := make([]string, len(values))
			for i, v := range values {
				if s, ok := v.(string); ok {
					stringValues[i] = s
				} else {
					return "", fmt.Errorf("invalid postal code value: %v", v)
				}
			}
			condition := fmt.Sprintf("NOT (c.postal_codes && $%d)", qb.argIndex)
			qb.args = append(qb.args, pq.Array(stringValues))
			qb.argIndex++
			return condition, nil
		}
		return "", fmt.Errorf("invalid value for 'not_in' operator: %v", rule.Value)

	default:
		return "", fmt.Errorf("unsupported operator for postal_code: %s", rule.Operator)
	}
}