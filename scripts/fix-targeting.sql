-- Script pour corriger les fonctionnalités de ciblage géographique

-- Mise à jour de la fonction de comptage pour corriger les problèmes
DROP FUNCTION IF EXISTS count_targeting_recipients(TEXT[], INTEGER, INTEGER, TEXT[]);

CREATE OR REPLACE FUNCTION count_targeting_recipients(
    dept_codes TEXT[] DEFAULT NULL,
    pop_min INTEGER DEFAULT NULL,
    pop_max INTEGER DEFAULT NULL,
    regions TEXT[] DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    result INTEGER;
BEGIN
    SELECT COUNT(DISTINCT s.id) INTO result
    FROM subscribers s
    INNER JOIN subscriber_communes sc ON s.id = sc.subscriber_id
    INNER JOIN french_communes c ON sc.commune_id = c.id
    LEFT JOIN french_departments d ON c.department_code = d.code
    WHERE s.status = 'enabled'
    AND (dept_codes IS NULL OR c.department_code = ANY(dept_codes))
    AND (pop_min IS NULL OR c.population >= pop_min)
    AND (pop_max IS NULL OR c.population <= pop_max)
    AND (regions IS NULL OR d.region = ANY(regions));
    
    RETURN COALESCE(result, 0);
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir les abonnés ciblés
CREATE OR REPLACE FUNCTION get_targeted_subscribers(
    dept_codes TEXT[] DEFAULT NULL,
    pop_min INTEGER DEFAULT NULL,
    pop_max INTEGER DEFAULT NULL,
    regions TEXT[] DEFAULT NULL,
    limit_count INTEGER DEFAULT NULL,
    offset_count INTEGER DEFAULT 0
) RETURNS TABLE (
    subscriber_id INTEGER,
    subscriber_email TEXT,
    subscriber_name TEXT,
    commune_id INTEGER,
    commune_name TEXT,
    insee_code TEXT,
    department_code TEXT,
    population INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT 
        s.id as subscriber_id,
        s.email as subscriber_email,
        s.name as subscriber_name,
        c.id as commune_id,
        c.name as commune_name,
        c.insee_code,
        c.department_code,
        c.population
    FROM subscribers s
    INNER JOIN subscriber_communes sc ON s.id = sc.subscriber_id
    INNER JOIN french_communes c ON sc.commune_id = c.id
    LEFT JOIN french_departments d ON c.department_code = d.code
    WHERE s.status = 'enabled'
    AND (dept_codes IS NULL OR c.department_code = ANY(dept_codes))
    AND (pop_min IS NULL OR c.population >= pop_min)
    AND (pop_max IS NULL OR c.population <= pop_max)
    AND (regions IS NULL OR d.region = ANY(regions))
    ORDER BY c.name, s.name
    LIMIT limit_count
    OFFSET offset_count;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir les statistiques par département
CREATE OR REPLACE FUNCTION get_department_statistics()
RETURNS TABLE (
    department_code TEXT,
    department_name TEXT,
    region TEXT,
    commune_count BIGINT,
    subscriber_count BIGINT,
    total_population BIGINT,
    coverage_percentage NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.code as department_code,
        d.name as department_name,
        d.region,
        COUNT(DISTINCT c.id) as commune_count,
        COUNT(DISTINCT sc.subscriber_id) as subscriber_count,
        COALESCE(SUM(c.population), 0) as total_population,
        CASE 
            WHEN COUNT(DISTINCT c.id) > 0 THEN 
                ROUND((COUNT(DISTINCT sc.commune_id)::NUMERIC / COUNT(DISTINCT c.id)::NUMERIC) * 100, 2)
            ELSE 0
        END as coverage_percentage
    FROM french_departments d
    LEFT JOIN french_communes c ON d.code = c.department_code
    LEFT JOIN subscriber_communes sc ON c.id = sc.commune_id
    GROUP BY d.code, d.name, d.region
    ORDER BY d.code;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir les statistiques par tranche de population
CREATE OR REPLACE FUNCTION get_population_range_statistics()
RETURNS TABLE (
    range_name TEXT,
    min_population INTEGER,
    max_population INTEGER,
    commune_count BIGINT,
    subscriber_count BIGINT,
    total_population BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH population_ranges AS (
        SELECT 
            '0-500' as range_name, 0 as min_pop, 500 as max_pop
        UNION ALL SELECT '501-1000', 501, 1000
        UNION ALL SELECT '1001-2000', 1001, 2000
        UNION ALL SELECT '2001-5000', 2001, 5000
        UNION ALL SELECT '5001-10000', 5001, 10000
        UNION ALL SELECT '10001-20000', 10001, 20000
        UNION ALL SELECT '20001-50000', 20001, 50000
        UNION ALL SELECT '50001+', 50001, 999999999
    )
    SELECT 
        pr.range_name,
        pr.min_pop as min_population,
        pr.max_pop as max_population,
        COUNT(DISTINCT c.id) as commune_count,
        COUNT(DISTINCT sc.subscriber_id) as subscriber_count,
        COALESCE(SUM(c.population), 0) as total_population
    FROM population_ranges pr
    LEFT JOIN french_communes c ON c.population >= pr.min_pop AND c.population <= pr.max_pop
    LEFT JOIN subscriber_communes sc ON c.id = sc.commune_id
    GROUP BY pr.range_name, pr.min_pop, pr.max_pop
    ORDER BY pr.min_pop;
END;
$$ LANGUAGE plpgsql;

-- Index pour améliorer les performances des requêtes de ciblage
CREATE INDEX IF NOT EXISTS idx_communes_population_dept ON french_communes(population, department_code);
CREATE INDEX IF NOT EXISTS idx_communes_dept_pop ON french_communes(department_code, population);
CREATE INDEX IF NOT EXISTS idx_subscriber_communes_composite ON subscriber_communes(subscriber_id, commune_id);

-- Vue matérialisée pour les statistiques (optionnel, pour de meilleures performances)
CREATE MATERIALIZED VIEW IF NOT EXISTS targeting_stats_mv AS
SELECT 
    d.code as department_code,
    d.name as department_name,
    d.region,
    COUNT(DISTINCT c.id) as commune_count,
    COUNT(DISTINCT sc.subscriber_id) as subscriber_count,
    COALESCE(SUM(c.population), 0) as total_population,
    CASE 
        WHEN COUNT(DISTINCT c.id) > 0 THEN 
            ROUND((COUNT(DISTINCT sc.commune_id)::NUMERIC / COUNT(DISTINCT c.id)::NUMERIC) * 100, 2)
        ELSE 0
    END as coverage_percentage
FROM french_departments d
LEFT JOIN french_communes c ON d.code = c.department_code
LEFT JOIN subscriber_communes sc ON c.id = sc.commune_id
GROUP BY d.code, d.name, d.region;

-- Index sur la vue matérialisée
CREATE UNIQUE INDEX IF NOT EXISTS idx_targeting_stats_mv_dept ON targeting_stats_mv(department_code);

-- Fonction pour rafraîchir les statistiques
CREATE OR REPLACE FUNCTION refresh_targeting_stats() RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY targeting_stats_mv;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour rafraîchir automatiquement les stats (optionnel)
-- CREATE OR REPLACE FUNCTION trigger_refresh_targeting_stats() RETURNS TRIGGER AS $$
-- BEGIN
--     PERFORM refresh_targeting_stats();
--     RETURN NULL;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER refresh_stats_on_subscriber_change
--     AFTER INSERT OR UPDATE OR DELETE ON subscriber_communes
--     FOR EACH STATEMENT
--     EXECUTE FUNCTION trigger_refresh_targeting_stats();

COMMENT ON FUNCTION count_targeting_recipients IS 'Compte le nombre d''abonnés correspondant aux critères de ciblage géographique';
COMMENT ON FUNCTION get_targeted_subscribers IS 'Retourne les abonnés correspondant aux critères de ciblage géographique';
COMMENT ON FUNCTION get_department_statistics IS 'Retourne les statistiques par département';
COMMENT ON FUNCTION get_population_range_statistics IS 'Retourne les statistiques par tranche de population';
COMMENT ON FUNCTION refresh_targeting_stats IS 'Rafraîchit la vue matérialisée des statistiques de ciblage';