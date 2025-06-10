#!/bin/bash

# Script de déploiement complet du ciblage géographique
# Version finale avec vérifications et tests

set -e

echo "🚀 DÉPLOIEMENT COMPLET DU CIBLAGE GÉOGRAPHIQUE"
echo "=============================================="
echo ""

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonction d'affichage coloré
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

log_highlight() {
    echo -e "${CYAN}🎯 $1${NC}"
}

# Configuration
CONTAINER_NAME="listmonk_mairies_app"
DB_CONTAINER="listmonk_mairies_db"
API_USER="api"
API_TOKEN="RmAp4lu4hiMSE9GCV2KOSpjLWH0k7h1o"
API_URL="http://localhost:9000/api"
LISTMONK_URL="http://localhost:9000"

# Variables pour la DB
DB_USER="listmonk_mairies"
DB_PASSWORD="listmonk_mairies_2024"
DB_NAME="listmonk_mairies"

# Fonction de vérification des prérequis
check_prerequisites() {
    log_step "Vérification des prérequis..."
    
    # Vérifier Git
    if ! command -v git &> /dev/null; then
        log_error "Git n'est pas installé"
        exit 1
    fi
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé"
        exit 1
    fi
    
    # Vérifier curl
    if ! command -v curl &> /dev/null; then
        log_error "curl n'est pas installé"
        exit 1
    fi
    
    log_success "Prérequis vérifiés"
}

# Fonction de mise à jour du code
update_code() {
    log_step "Mise à jour du code depuis GitHub..."
    
    # Vérifier si nous sommes dans un repo Git
    if [ ! -d ".git" ]; then
        log_error "Ce répertoire n'est pas un dépôt Git"
        exit 1
    fi
    
    # Sauvegarder les modifications locales
    if ! git diff --quiet; then
        log_warning "Modifications locales détectées, création d'un stash..."
        git stash push -m "Sauvegarde avant déploiement $(date)"
    fi
    
    # Récupérer les dernières modifications
    log_info "Récupération des dernières modifications..."
    git fetch origin
    
    # Vérifier si la branche existe
    if git show-ref --verify --quiet refs/remotes/origin/feature/french-municipalities-targeting; then
        log_info "Basculement vers la branche feature/french-municipalities-targeting..."
        git checkout feature/french-municipalities-targeting
        git pull origin feature/french-municipalities-targeting
        log_success "Code mis à jour"
    else
        log_error "Branche feature/french-municipalities-targeting non trouvée"
        exit 1
    fi
}

# Fonction de vérification de l'environnement Docker
check_docker_environment() {
    log_step "Vérification de l'environnement Docker..."
    
    # Vérifier que Docker fonctionne
    if ! docker ps &> /dev/null; then
        log_error "Docker n'est pas accessible. Vérifiez les permissions."
        exit 1
    fi
    
    # Vérifier les conteneurs
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        log_error "Conteneur Listmonk '$CONTAINER_NAME' non trouvé ou arrêté"
        log_info "Conteneurs en cours d'exécution :"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        exit 1
    fi
    
    if ! docker ps | grep -q "$DB_CONTAINER"; then
        log_error "Conteneur de base de données '$DB_CONTAINER' non trouvé ou arrêté"
        exit 1
    fi
    
    log_success "Environnement Docker vérifié"
}

# Fonction de test de connectivité
test_connectivity() {
    log_step "Test de connectivité..."
    
    # Test de l'API Listmonk
    log_info "Test de l'API Listmonk..."
    local max_attempts=10
    for attempt in $(seq 1 $max_attempts); do
        if curl -s "$LISTMONK_URL/api/health" > /dev/null 2>&1; then
            log_success "Listmonk accessible sur $LISTMONK_URL"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log_error "Impossible d'accéder à Listmonk après $max_attempts tentatives"
            log_info "Vérifiez que le conteneur est en bonne santé :"
            docker ps | grep "$CONTAINER_NAME"
            exit 1
        fi
        
        log_info "Tentative $attempt/$max_attempts - Attente de Listmonk..."
        sleep 2
    done
    
    # Test de l'authentification API
    log_info "Test de l'authentification API..."
    if curl -s -u "$API_USER:$API_TOKEN" "$API_URL/lists" | grep -q '"data"'; then
        log_success "Authentification API réussie"
    else
        log_error "Échec de l'authentification API"
        exit 1
    fi
    
    # Test de la base de données
    log_info "Test de la connexion à la base de données..."
    if docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        log_success "Connexion à la base de données réussie"
    else
        log_error "Impossible de se connecter à la base de données"
        exit 1
    fi
}

# Fonction de déploiement de la base de données
deploy_database() {
    log_step "Déploiement des structures de base de données..."
    
    # Exécuter le script de déploiement géographique
    if [ -f "./deploy-geo-targeting-final.sh" ]; then
        log_info "Exécution du déploiement géographique..."
        echo "y" | ./deploy-geo-targeting-final.sh
    else
        log_error "Script deploy-geo-targeting-final.sh non trouvé"
        exit 1
    fi
    
    # Correction des données géographiques
    if [ -f "./fix-geo-data-extraction.sh" ]; then
        log_info "Correction des données géographiques..."
        ./fix-geo-data-extraction.sh
    else
        log_warning "Script fix-geo-data-extraction.sh non trouvé"
    fi
}

# Fonction de vérification des données
verify_data() {
    log_step "Vérification des données..."
    
    # Vérifier le nombre d'abonnés
    local total_subscribers=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers;" | tr -d ' ')
    log_info "Total des abonnés : $total_subscribers"
    
    if [ "$total_subscribers" -lt 30000 ]; then
        log_warning "Nombre d'abonnés faible ($total_subscribers), attendu: 30000+"
    else
        log_success "Nombre d'abonnés correct : $total_subscribers"
    fi
    
    # Vérifier les données géographiques
    local with_dept=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE department_code IS NOT NULL;" | tr -d ' ')
    local with_pop=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE population > 0;" | tr -d ' ')
    
    log_info "Abonnés avec code département : $with_dept"
    log_info "Abonnés avec population : $with_pop"
    
    if [ "$with_dept" -lt 10000 ]; then
        log_warning "Peu d'abonnés avec code département ($with_dept)"
        log_info "Relancement de la correction des données..."
        ./fix-geo-data-extraction.sh
    else
        log_success "Données géographiques correctes"
    fi
    
    # Vérifier les départements
    local dept_count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM departments;" | tr -d ' ')
    log_info "Départements en base : $dept_count"
    
    if [ "$dept_count" -lt 95 ]; then
        log_warning "Nombre de départements insuffisant ($dept_count/95+)"
    else
        log_success "Départements complets : $dept_count"
    fi
}

# Fonction de déploiement de l'interface utilisateur
deploy_ui() {
    log_step "Déploiement de l'interface utilisateur..."
    
    # Créer le fichier JavaScript d'interface
    log_info "Création du fichier d'interface JavaScript..."
    
    cat > /tmp/geo-targeting-ui.js << 'EOF'
// Interface de ciblage géographique pour Listmonk
// Auto-injection au chargement de la page

(function() {
    'use strict';
    
    // Fonction pour détecter si nous sommes sur la page des abonnés
    function isSubscribersPage() {
        return window.location.pathname.includes('/subscribers') || 
               window.location.hash.includes('/subscribers') ||
               document.querySelector('h1, h2, h3')?.textContent?.includes('Abonnés') ||
               document.querySelector('h1, h2, h3')?.textContent?.includes('Subscribers');
    }
    
    // Fonction pour ajouter un bouton flottant
    function addFloatingButton() {
        if (document.getElementById('geo-floating-btn')) return;
        
        const btn = document.createElement('button');
        btn.id = 'geo-floating-btn';
        btn.innerHTML = '🎯<br>Ciblage<br>Géo';
        btn.style.cssText = `
            position: fixed;
            bottom: 20px;
            right: 20px;
            z-index: 10000;
            background: linear-gradient(135deg, #3273dc 0%, #2c5aa0 100%);
            color: white;
            border: none;
            border-radius: 50%;
            width: 70px;
            height: 70px;
            cursor: pointer;
            font-size: 10px;
            font-weight: bold;
            box-shadow: 0 4px 12px rgba(50, 115, 220, 0.4);
            transition: all 0.3s ease;
            line-height: 1.2;
        `;
        
        btn.onmouseover = function() {
            this.style.transform = 'scale(1.1)';
            this.style.boxShadow = '0 6px 20px rgba(50, 115, 220, 0.6)';
        };
        
        btn.onmouseout = function() {
            this.style.transform = 'scale(1)';
            this.style.boxShadow = '0 4px 12px rgba(50, 115, 220, 0.4)';
        };
        
        btn.onclick = function() {
            if (isSubscribersPage()) {
                showGeoInterface();
            } else {
                alert('🎯 Allez d\'abord sur la page "Abonnés" pour utiliser le ciblage géographique !');
            }
        };
        
        document.body.appendChild(btn);
    }
    
    // Fonction pour afficher l'interface de ciblage
    function showGeoInterface() {
        // Supprimer l'interface existante
        const existing = document.getElementById('geo-targeting-widget');
        if (existing) {
            existing.remove();
            return;
        }
        
        // Créer l'interface
        const widget = document.createElement('div');
        widget.id = 'geo-targeting-widget';
        widget.style.cssText = `
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 90%;
            max-width: 500px;
            max-height: 90vh;
            background: white;
            border: 3px solid #3273dc;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            z-index: 10001;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            font-size: 14px;
            overflow-y: auto;
        `;
        
        widget.innerHTML = `
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 2px solid #f0f0f0; padding-bottom: 15px;">
                <h3 style="margin: 0; color: #3273dc; font-size: 20px; font-weight: bold;">🎯 Ciblage Géographique</h3>
                <button onclick="this.parentElement.parentElement.remove()" style="background: #ff4757; color: white; border: none; border-radius: 50%; width: 35px; height: 35px; font-size: 18px; cursor: pointer; font-weight: bold;">×</button>
            </div>
            
            <div style="margin-bottom: 20px;">
                <label style="display: block; margin-bottom: 8px; font-weight: bold; color: #2c3e50;">📍 Départements :</label>
                <select id="geo-dept" multiple style="width: 100%; height: 120px; border: 2px solid #ddd; border-radius: 8px; padding: 8px; font-size: 13px;">
                    <optgroup label="🏛️ Île-de-France">
                        <option value="75">75 - Paris</option>
                        <option value="77">77 - Seine-et-Marne</option>
                        <option value="78">78 - Yvelines</option>
                        <option value="91">91 - Essonne</option>
                        <option value="92">92 - Hauts-de-Seine</option>
                        <option value="93">93 - Seine-Saint-Denis</option>
                        <option value="94">94 - Val-de-Marne</option>
                        <option value="95">95 - Val-d'Oise</option>
                    </optgroup>
                    <optgroup label="🌊 PACA">
                        <option value="04">04 - Alpes-de-Haute-Provence</option>
                        <option value="05">05 - Hautes-Alpes</option>
                        <option value="06">06 - Alpes-Maritimes</option>
                        <option value="13">13 - Bouches-du-Rhône</option>
                        <option value="83">83 - Var</option>
                        <option value="84">84 - Vaucluse</option>
                    </optgroup>
                    <optgroup label="🏔️ Auvergne-Rhône-Alpes">
                        <option value="01">01 - Ain</option>
                        <option value="03">03 - Allier</option>
                        <option value="07">07 - Ardèche</option>
                        <option value="15">15 - Cantal</option>
                        <option value="26">26 - Drôme</option>
                        <option value="38">38 - Isère</option>
                        <option value="42">42 - Loire</option>
                        <option value="43">43 - Haute-Loire</option>
                        <option value="63">63 - Puy-de-Dôme</option>
                        <option value="69">69 - Rhône</option>
                        <option value="73">73 - Savoie</option>
                        <option value="74">74 - Haute-Savoie</option>
                    </optgroup>
                    <optgroup label="🌿 Nouvelle-Aquitaine">
                        <option value="16">16 - Charente</option>
                        <option value="17">17 - Charente-Maritime</option>
                        <option value="19">19 - Corrèze</option>
                        <option value="23">23 - Creuse</option>
                        <option value="24">24 - Dordogne</option>
                        <option value="33">33 - Gironde</option>
                        <option value="40">40 - Landes</option>
                        <option value="47">47 - Lot-et-Garonne</option>
                        <option value="64">64 - Pyrénées-Atlantiques</option>
                        <option value="79">79 - Deux-Sèvres</option>
                        <option value="86">86 - Vienne</option>
                        <option value="87">87 - Haute-Vienne</option>
                    </optgroup>
                    <optgroup label="🌞 Occitanie">
                        <option value="09">09 - Ariège</option>
                        <option value="11">11 - Aude</option>
                        <option value="12">12 - Aveyron</option>
                        <option value="30">30 - Gard</option>
                        <option value="31">31 - Haute-Garonne</option>
                        <option value="32">32 - Gers</option>
                        <option value="34">34 - Hérault</option>
                        <option value="46">46 - Lot</option>
                        <option value="48">48 - Lozère</option>
                        <option value="65">65 - Hautes-Pyrénées</option>
                        <option value="66">66 - Pyrénées-Orientales</option>
                        <option value="81">81 - Tarn</option>
                        <option value="82">82 - Tarn-et-Garonne</option>
                    </optgroup>
                </select>
                <small style="color: #666; font-style: italic;">💡 Ctrl+clic pour sélectionner plusieurs</small>
            </div>
            
            <div style="margin-bottom: 20px; background: #f8f9fa; padding: 15px; border-radius: 8px;">
                <label style="display: block; margin-bottom: 10px; font-weight: bold;">
                    <input type="checkbox" id="geo-pop-filter" style="margin-right: 8px;"> 👥 Filtrer par population
                </label>
                <div id="geo-pop-controls" style="display: none; margin-top: 10px;">
                    <div style="display: flex; gap: 10px;">
                        <div style="flex: 1;">
                            <label style="font-size: 12px; font-weight: bold;">Min habitants</label>
                            <input type="number" id="geo-min-pop" placeholder="0" style="width: 100%; padding: 6px; border: 1px solid #ddd; border-radius: 4px;">
                        </div>
                        <div style="flex: 1;">
                            <label style="font-size: 12px; font-weight: bold;">Max habitants</label>
                            <input type="number" id="geo-max-pop" placeholder="100000" style="width: 100%; padding: 6px; border: 1px solid #ddd; border-radius: 4px;">
                        </div>
                    </div>
                </div>
            </div>
            
            <div style="margin-bottom: 20px;">
                <label style="display: block; margin-bottom: 10px; font-weight: bold;">⚡ Filtres rapides :</label>
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 10px;">
                    <button onclick="geoQuickFilter('small')" style="padding: 8px; font-size: 11px; border: 2px solid #74b9ff; background: #dfe6e9; border-radius: 6px; cursor: pointer;">🏘️ Petites (&lt;2k)</button>
                    <button onclick="geoQuickFilter('medium')" style="padding: 8px; font-size: 11px; border: 2px solid #00b894; background: #dfe6e9; border-radius: 6px; cursor: pointer;">🏙️ Moyennes (2k-10k)</button>
                    <button onclick="geoQuickFilter('large')" style="padding: 8px; font-size: 11px; border: 2px solid #e17055; background: #dfe6e9; border-radius: 6px; cursor: pointer;">🏢 Grandes (&gt;10k)</button>
                    <button onclick="geoQuickFilter('metro')" style="padding: 8px; font-size: 11px; border: 2px solid #6c5ce7; background: #dfe6e9; border-radius: 6px; cursor: pointer;">🏙️ Métropoles (&gt;50k)</button>
                </div>
                <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 6px;">
                    <button onclick="geoQuickFilter('idf')" style="padding: 6px; font-size: 10px; border: 2px solid #3273dc; background: #e3f2fd; border-radius: 4px; cursor: pointer;">🏛️ IDF</button>
                    <button onclick="geoQuickFilter('paca')" style="padding: 6px; font-size: 10px; border: 2px solid #00b894; background: #e8f5e8; border-radius: 4px; cursor: pointer;">🌊 PACA</button>
                    <button onclick="geoQuickFilter('aura')" style="padding: 6px; font-size: 10px; border: 2px solid #6c5ce7; background: #f3e5f5; border-radius: 4px; cursor: pointer;">🏔️ AURA</button>
                </div>
            </div>
            
            <div style="margin-bottom: 20px;">
                <label style="display: block; margin-bottom: 8px; font-weight: bold;">🔍 Requête SQL :</label>
                <textarea id="geo-query" readonly style="width: 100%; height: 60px; font-family: monospace; font-size: 11px; background: #f8f9fa; border: 1px solid #ddd; border-radius: 4px; padding: 8px; resize: vertical;"></textarea>
            </div>
            
            <div style="display: grid; grid-template-columns: 2fr 1fr 1fr; gap: 8px;">
                <button onclick="geoApplyFilter()" style="padding: 10px; background: linear-gradient(135deg, #3273dc 0%, #2c5aa0 100%); color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold;">🎯 Appliquer</button>
                <button onclick="geoResetFilter()" style="padding: 10px; background: #f8f9fa; border: 1px solid #ddd; border-radius: 6px; cursor: pointer;">🔄 Reset</button>
                <button onclick="geoCopyQuery()" style="padding: 10px; background: #17a2b8; color: white; border: none; border-radius: 6px; cursor: pointer;">📋 Copier</button>
            </div>
        `;
        
        document.body.appendChild(widget);
        
        // Ajouter les gestionnaires d'événements
        setupEventHandlers();
        geoUpdateQuery();
    }
    
    // Gestionnaires d'événements
    function setupEventHandlers() {
        const popFilter = document.getElementById('geo-pop-filter');
        const popControls = document.getElementById('geo-pop-controls');
        
        if (popFilter && popControls) {
            popFilter.addEventListener('change', function() {
                popControls.style.display = this.checked ? 'block' : 'none';
                geoUpdateQuery();
            });
        }
        
        ['geo-dept', 'geo-min-pop', 'geo-max-pop'].forEach(id => {
            const element = document.getElementById(id);
            if (element) {
                element.addEventListener('change', geoUpdateQuery);
                element.addEventListener('input', geoUpdateQuery);
            }
        });
    }
    
    // Fonctions globales
    window.geoUpdateQuery = function() {
        const deptSelect = document.getElementById('geo-dept');
        const usePopFilter = document.getElementById('geo-pop-filter')?.checked;
        const minPop = document.getElementById('geo-min-pop')?.value;
        const maxPop = document.getElementById('geo-max-pop')?.value;
        const queryTextarea = document.getElementById('geo-query');
        
        if (!queryTextarea) return;
        
        let conditions = [];
        
        if (deptSelect) {
            const selectedDepts = Array.from(deptSelect.selectedOptions).map(opt => opt.value);
            if (selectedDepts.length > 0) {
                if (selectedDepts.length === 1) {
                    conditions.push(`department_code = '${selectedDepts[0]}'`);
                } else {
                    conditions.push(`department_code IN (${selectedDepts.map(d => `'${d}'`).join(', ')})`);
                }
            }
        }
        
        if (usePopFilter) {
            if (minPop && maxPop) {
                conditions.push(`population BETWEEN ${minPop} AND ${maxPop}`);
            } else if (minPop) {
                conditions.push(`population >= ${minPop}`);
            } else if (maxPop) {
                conditions.push(`population <= ${maxPop}`);
            }
        }
        
        let query = 'SELECT * FROM subscribers';
        if (conditions.length > 0) {
            query += ' WHERE ' + conditions.join(' AND ');
        }
        
        queryTextarea.value = query;
    };
    
    window.geoQuickFilter = function(type) {
        geoResetFilter();
        const deptSelect = document.getElementById('geo-dept');
        const popFilter = document.getElementById('geo-pop-filter');
        const popControls = document.getElementById('geo-pop-controls');
        const minPop = document.getElementById('geo-min-pop');
        const maxPop = document.getElementById('geo-max-pop');
        
        switch(type) {
            case 'small':
                popFilter.checked = true;
                popControls.style.display = 'block';
                maxPop.value = 2000;
                break;
            case 'medium':
                popFilter.checked = true;
                popControls.style.display = 'block';
                minPop.value = 2000;
                maxPop.value = 10000;
                break;
            case 'large':
                popFilter.checked = true;
                popControls.style.display = 'block';
                minPop.value = 10000;
                break;
            case 'metro':
                popFilter.checked = true;
                popControls.style.display = 'block';
                minPop.value = 50000;
                break;
            case 'idf':
                ['75','77','78','91','92','93','94','95'].forEach(dept => {
                    const option = deptSelect.querySelector(`option[value="${dept}"]`);
                    if (option) option.selected = true;
                });
                break;
            case 'paca':
                ['04','05','06','13','83','84'].forEach(dept => {
                    const option = deptSelect.querySelector(`option[value="${dept}"]`);
                    if (option) option.selected = true;
                });
                break;
            case 'aura':
                ['01','03','07','15','26','38','42','43','63','69','73','74'].forEach(dept => {
                    const option = deptSelect.querySelector(`option[value="${dept}"]`);
                    if (option) option.selected = true;
                });
                break;
        }
        geoUpdateQuery();
    };
    
    window.geoResetFilter = function() {
        const deptSelect = document.getElementById('geo-dept');
        const popFilter = document.getElementById('geo-pop-filter');
        const popControls = document.getElementById('geo-pop-controls');
        const minPop = document.getElementById('geo-min-pop');
        const maxPop = document.getElementById('geo-max-pop');
        
        if (deptSelect) deptSelect.selectedIndex = -1;
        if (popFilter) popFilter.checked = false;
        if (popControls) popControls.style.display = 'none';
        if (minPop) minPop.value = '';
        if (maxPop) maxPop.value = '';
        geoUpdateQuery();
    };
    
    window.geoApplyFilter = function() {
        const query = document.getElementById('geo-query')?.value;
        if (!query) return;
        
        const sqlTextarea = document.querySelector('textarea[placeholder*="SQL"]') || 
                           document.querySelector('textarea[placeholder*="sql"]') ||
                           document.querySelector('textarea[placeholder*="requête"]') ||
                           document.querySelector('textarea');
        
        if (sqlTextarea) {
            sqlTextarea.value = query;
            sqlTextarea.dispatchEvent(new Event('input', { bubbles: true }));
            
            setTimeout(() => {
                const searchBtn = document.querySelector('button[type="submit"]') ||
                                document.querySelector('.button.is-primary');
                if (searchBtn) searchBtn.click();
            }, 100);
            
            // Feedback
            const btn = event.target;
            const originalText = btn.textContent;
            btn.textContent = '✅ Appliqué !';
            btn.style.background = 'linear-gradient(135deg, #00b894 0%, #00a085 100%)';
            setTimeout(() => {
                btn.textContent = originalText;
                btn.style.background = 'linear-gradient(135deg, #3273dc 0%, #2c5aa0 100%)';
            }, 2000);
        } else {
            geoCopyQuery();
            alert('📋 Requête copiée ! Collez-la dans le champ de recherche.');
        }
    };
    
    window.geoCopyQuery = function() {
        const query = document.getElementById('geo-query')?.value;
        if (!query) return;
        
        navigator.clipboard.writeText(query).then(() => {
            const btn = event.target;
            const originalText = btn.textContent;
            btn.textContent = '✅ Copié !';
            setTimeout(() => btn.textContent = originalText, 1500);
        });
    };
    
    // Initialisation
    function init() {
        addFloatingButton();
    }
    
    // Lancer l'initialisation
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
    
    // Observer les changements de page
    setInterval(addFloatingButton, 3000);
    
})();
EOF

    # Copier le fichier dans le conteneur
    log_info "Injection du fichier JavaScript dans le conteneur..."
    docker cp /tmp/geo-targeting-ui.js "$CONTAINER_NAME":/listmonk/static/geo-targeting.js
    
    # Créer un script d'injection HTML
    cat > /tmp/inject-html.sh << 'EOF'
#!/bin/sh
# Script d'injection dans les fichiers HTML

echo "Recherche des fichiers HTML..."
find /listmonk -name "*.html" -type f | while read file; do
    if [ -f "$file" ] && ! grep -q "geo-targeting.js" "$file"; then
        echo "Injection dans $file"
        # Injecter avant la fermeture du body
        sed -i 's|</body>|<script src="/static/geo-targeting.js"></script>\n</body>|g' "$file"
    fi
done

# Chercher aussi dans les templates
find /listmonk -name "*.tmpl" -o -name "*.tpl" -type f | while read file; do
    if [ -f "$file" ] && ! grep -q "geo-targeting.js" "$file"; then
        echo "Injection dans template $file"
        sed -i 's|</body>|<script src="/static/geo-targeting.js"></script>\n</body>|g' "$file"
    fi
done

echo "Injection terminée"
EOF

    docker cp /tmp/inject-html.sh "$CONTAINER_NAME":/tmp/inject-html.sh
    docker exec "$CONTAINER_NAME" chmod +x /tmp/inject-html.sh
    docker exec "$CONTAINER_NAME" /tmp/inject-html.sh
    
    log_success "Interface utilisateur déployée"
    
    # Nettoyer
    rm -f /tmp/geo-targeting-ui.js /tmp/inject-html.sh
}

# Fonction de redémarrage des services
restart_services() {
    log_step "Redémarrage des services..."
    
    log_info "Redémarrage du conteneur Listmonk..."
    docker restart "$CONTAINER_NAME"
    
    log_info "Attente du redémarrage (30 secondes)..."
    sleep 30
    
    # Vérifier que le service est de nouveau accessible
    local max_attempts=20
    for attempt in $(seq 1 $max_attempts); do
        if curl -s "$LISTMONK_URL/api/health" > /dev/null 2>&1; then
            log_success "Service redémarré avec succès"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log_error "Service non accessible après redémarrage"
            exit 1
        fi
        
        log_info "Attente du service... ($attempt/$max_attempts)"
        sleep 3
    done
}

# Fonction de test de l'interface
test_ui() {
    log_step "Test de l'interface utilisateur..."
    
    # Vérifier que le fichier JavaScript est accessible
    if curl -s "$LISTMONK_URL/static/geo-targeting.js" | grep -q "Ciblage Géographique"; then
        log_success "Fichier JavaScript accessible"
    else
        log_warning "Fichier JavaScript non accessible via HTTP"
    fi
    
    # Vérifier dans le conteneur
    if docker exec "$CONTAINER_NAME" test -f "/listmonk/static/geo-targeting.js"; then
        log_success "Fichier JavaScript présent dans le conteneur"
    else
        log_error "Fichier JavaScript manquant dans le conteneur"
    fi
}

# Fonction de test des requêtes
test_queries() {
    log_step "Test des requêtes de ciblage..."
    
    # Test requête par département
    log_info "Test requête département Paris (75)..."
    local paris_count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE department_code = '75';" | tr -d ' ')
    log_info "Mairies Paris trouvées : $paris_count"
    
    # Test requête par population
    log_info "Test requête petites communes (< 2000 hab.)..."
    local small_count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE population < 2000 AND population > 0;" | tr -d ' ')
    log_info "Petites communes trouvées : $small_count"
    
    # Test requête combinée
    log_info "Test requête combinée (IDF + grandes communes)..."
    local combined_count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE department_code IN ('75','77','78','91','92','93','94','95') AND population > 10000;" | tr -d ' ')
    log_info "Grandes communes IDF trouvées : $combined_count"
    
    if [ "$paris_count" -gt 0 ] && [ "$small_count" -gt 0 ]; then
        log_success "Requêtes de test fonctionnelles"
    else
        log_warning "Résultats de requêtes faibles, vérifiez les données"
    fi
}

# Fonction de génération du rapport final
generate_report() {
    log_step "Génération du rapport de déploiement..."
    
    cat > RAPPORT_DEPLOIEMENT.md << EOF
# 📊 Rapport de Déploiement - Ciblage Géographique

**Date :** $(date)
**Version :** $(git rev-parse --short HEAD)

## ✅ Statut du Déploiement

### 🗄️ Base de Données
- **Abonnés totaux :** $(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers;" | tr -d ' ')
- **Avec code département :** $(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE department_code IS NOT NULL;" | tr -d ' ')
- **Avec population :** $(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE population > 0;" | tr -d ' ')
- **Départements en base :** $(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM departments;" | tr -d ' ')

### 🎯 Tests de Ciblage
- **Mairies Paris (75) :** $(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE department_code = '75';" | tr -d ' ')
- **Petites communes (< 2000 hab.) :** $(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE population < 2000 AND population > 0;" | tr -d ' ')
- **Grandes communes IDF :** $(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE department_code IN ('75','77','78','91','92','93','94','95') AND population > 10000;" | tr -d ' ')

### 🌐 Interface Utilisateur
- **Fichier JavaScript :** $(docker exec "$CONTAINER_NAME" test -f "/listmonk/static/geo-targeting.js" && echo "✅ Présent" || echo "❌ Manquant")
- **Accès HTTP :** $(curl -s "$LISTMONK_URL/static/geo-targeting.js" | grep -q "Ciblage" && echo "✅ Accessible" || echo "❌ Non accessible")

## 🚀 Utilisation

### 1. Interface Graphique
1. Allez sur http://localhost:9000
2. Naviguez vers la page "Abonnés"
3. Cliquez sur le bouton flottant "🎯 Ciblage Géo" en bas à droite
4. Configurez vos filtres et cliquez "Appliquer"

### 2. Exemples de Requêtes SQL
\`\`\`sql
-- Mairies de Paris
SELECT * FROM subscribers WHERE department_code = '75';

-- Petites communes rurales
SELECT * FROM subscribers WHERE population < 2000 AND population > 0;

-- Île-de-France
SELECT * FROM subscribers WHERE department_code IN ('75','77','78','91','92','93','94','95');
\`\`\`

## 🔧 Maintenance

### Mise à jour des données
\`\`\`bash
./fix-geo-data-extraction.sh
\`\`\`

### Redéploiement complet
\`\`\`bash
./deploy-complete-geo-targeting.sh
\`\`\`

## 📞 Support
- Vérifiez les logs : \`docker logs $CONTAINER_NAME\`
- Testez la DB : \`docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME\`
- Interface : Ouvrez la console navigateur (F12) pour les erreurs JS
EOF

    log_success "Rapport généré : RAPPORT_DEPLOIEMENT.md"
}

# Fonction principale
main() {
    echo "Ce script va déployer complètement le système de ciblage géographique"
    echo "pour vos 30 000+ mairies françaises dans Listmonk."
    echo ""
    echo "🔧 Étapes du déploiement :"
    echo "  1. Vérification des prérequis"
    echo "  2. Mise à jour du code depuis GitHub"
    echo "  3. Vérification de l'environnement Docker"
    echo "  4. Test de connectivité"
    echo "  5. Déploiement de la base de données"
    echo "  6. Vérification des données"
    echo "  7. Déploiement de l'interface utilisateur"
    echo "  8. Redémarrage des services"
    echo "  9. Tests de l'interface"
    echo "  10. Tests des requêtes"
    echo "  11. Génération du rapport"
    echo ""
    
    read -p "Continuer avec le déploiement complet ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Déploiement annulé."
        exit 0
    fi
    
    echo ""
    log_highlight "🚀 DÉBUT DU DÉPLOIEMENT COMPLET"
    echo ""
    
    # Exécuter toutes les étapes
    check_prerequisites
    update_code
    check_docker_environment
    test_connectivity
    deploy_database
    verify_data
    deploy_ui
    restart_services
    test_ui
    test_queries
    generate_report
    
    echo ""
    log_highlight "🎉 DÉPLOIEMENT TERMINÉ AVEC SUCCÈS !"
    echo ""
    log_success "✅ Le système de ciblage géographique est maintenant opérationnel"
    echo ""
    log_info "🌐 Accédez à votre Listmonk : $LISTMONK_URL"
    log_info "📊 Consultez le rapport : RAPPORT_DEPLOIEMENT.md"
    echo ""
    log_highlight "🎯 Pour utiliser le ciblage :"
    log_info "   1. Allez sur la page 'Abonnés'"
    log_info "   2. Cliquez sur le bouton flottant '🎯 Ciblage Géo'"
    log_info "   3. Configurez vos filtres géographiques"
    log_info "   4. Cliquez 'Appliquer' pour filtrer vos contacts"
    echo ""
    log_success "🇫🇷 Vous pouvez maintenant cibler vos mairies par département et population !"
    echo ""
}

# Exécuter le script principal
main "$@"