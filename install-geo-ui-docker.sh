#!/bin/bash

# Script d'installation de l'interface de ciblage géographique dans Docker

echo "🚀 Installation de l'interface de ciblage géographique"
echo "====================================================="

# Configuration
CONTAINER_NAME="listmonk_mairies_app"

echo "1. Correction des données géographiques..."
./fix-geo-data-extraction.sh

echo ""
echo "2. Création de l'interface utilisateur..."
./create-geo-targeting-ui.sh

echo ""
echo "3. Installation dans le conteneur Docker..."

# Créer le script d'injection JavaScript
cat > /tmp/geo-targeting-inject.js << 'EOF'
// Script d'injection pour l'interface de ciblage géographique
(function() {
    'use strict';
    
    // Vérifier si nous sommes sur la page des abonnés
    function isSubscribersPage() {
        return window.location.pathname.includes('/subscribers') || 
               window.location.hash.includes('/subscribers');
    }
    
    // Créer l'interface de ciblage géographique
    function createGeoTargetingUI() {
        if (document.getElementById('geo-targeting-container')) {
            return; // Déjà créé
        }
        
        const geoHTML = `
        <div id="geo-targeting-container" class="box" style="margin-bottom: 1rem; border-left: 4px solid #3273dc; background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%);">
            <h4 class="title is-5" style="color: #3273dc;">🎯 Ciblage Géographique des Mairies</h4>
            
            <!-- Sélection des départements -->
            <div class="field">
                <label class="label">📍 Départements</label>
                <div class="control">
                    <div class="select is-multiple" style="width: 100%;">
                        <select id="dept-select" multiple size="6" style="width: 100%;">
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
                            <optgroup label="🌊 Provence-Alpes-Côte d'Azur">
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
                            <optgroup label="🌊 Bretagne">
                                <option value="22">22 - Côtes-d'Armor</option>
                                <option value="29">29 - Finistère</option>
                                <option value="35">35 - Ille-et-Vilaine</option>
                                <option value="56">56 - Morbihan</option>
                            </optgroup>
                            <optgroup label="🏰 Centre-Val de Loire">
                                <option value="18">18 - Cher</option>
                                <option value="28">28 - Eure-et-Loir</option>
                                <option value="36">36 - Indre</option>
                                <option value="37">37 - Indre-et-Loire</option>
                                <option value="41">41 - Loir-et-Cher</option>
                                <option value="45">45 - Loiret</option>
                            </optgroup>
                        </select>
                    </div>
                </div>
                <p class="help">Maintenez Ctrl/Cmd pour sélectionner plusieurs départements</p>
            </div>

            <!-- Filtres de population -->
            <div class="field">
                <label class="label">👥 Population des communes</label>
                <div class="field is-grouped">
                    <div class="control">
                        <label class="checkbox">
                            <input type="checkbox" id="use-population"> Filtrer par population
                        </label>
                    </div>
                </div>
                
                <div id="population-controls" style="display: none;" class="field is-grouped">
                    <div class="control">
                        <label class="label is-small">Min habitants</label>
                        <input class="input" type="number" id="min-pop" placeholder="0" style="width: 120px;">
                    </div>
                    <div class="control">
                        <label class="label is-small">Max habitants</label>
                        <input class="input" type="number" id="max-pop" placeholder="100000" style="width: 120px;">
                    </div>
                </div>
            </div>

            <!-- Filtres prédéfinis -->
            <div class="field">
                <label class="label">🎯 Filtres rapides</label>
                <div class="field is-grouped is-grouped-multiline">
                    <div class="control">
                        <button class="button is-small is-info" onclick="applyQuickFilter('small')">
                            🏘️ Petites communes (&lt; 2000 hab.)
                        </button>
                    </div>
                    <div class="control">
                        <button class="button is-small is-info" onclick="applyQuickFilter('medium')">
                            🏙️ Communes moyennes (2000-10000 hab.)
                        </button>
                    </div>
                    <div class="control">
                        <button class="button is-small is-info" onclick="applyQuickFilter('large')">
                            🏢 Grandes communes (&gt; 10000 hab.)
                        </button>
                    </div>
                    <div class="control">
                        <button class="button is-small is-warning" onclick="applyQuickFilter('idf')">
                            🏛️ Île-de-France
                        </button>
                    </div>
                    <div class="control">
                        <button class="button is-small is-warning" onclick="applyQuickFilter('paca')">
                            🌊 PACA
                        </button>
                    </div>
                    <div class="control">
                        <button class="button is-small is-warning" onclick="applyQuickFilter('aura')">
                            🏔️ Auvergne-Rhône-Alpes
                        </button>
                    </div>
                </div>
            </div>

            <!-- Aperçu de la requête -->
            <div class="field">
                <label class="label">🔍 Requête SQL générée</label>
                <div class="control">
                    <textarea id="generated-query" class="textarea" readonly rows="3" style="font-family: monospace; font-size: 0.875rem; background-color: #f5f5f5;"></textarea>
                </div>
            </div>

            <!-- Boutons d'action -->
            <div class="field is-grouped">
                <div class="control">
                    <button class="button is-primary" onclick="applyGeoFilter()">
                        🎯 Appliquer le filtre
                    </button>
                </div>
                <div class="control">
                    <button class="button" onclick="resetGeoFilter()">
                        🔄 Réinitialiser
                    </button>
                </div>
                <div class="control">
                    <button class="button is-info" onclick="copyQuery()">
                        📋 Copier la requête
                    </button>
                </div>
            </div>
        </div>
        `;
        
        // Insérer l'interface
        const targetContainer = document.querySelector('.content') || 
                               document.querySelector('main') || 
                               document.querySelector('.container');
        
        if (targetContainer) {
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = geoHTML;
            targetContainer.insertBefore(tempDiv.firstElementChild, targetContainer.firstElementChild);
            setupEventHandlers();
            updateQuery();
        }
    }
    
    // Gestionnaires d'événements
    function setupEventHandlers() {
        const usePopCheckbox = document.getElementById('use-population');
        const popControls = document.getElementById('population-controls');
        const deptSelect = document.getElementById('dept-select');
        const minPop = document.getElementById('min-pop');
        const maxPop = document.getElementById('max-pop');
        
        if (usePopCheckbox && popControls) {
            usePopCheckbox.addEventListener('change', function() {
                popControls.style.display = this.checked ? 'block' : 'none';
                updateQuery();
            });
        }
        
        if (deptSelect) {
            deptSelect.addEventListener('change', updateQuery);
        }
        
        if (minPop) {
            minPop.addEventListener('input', updateQuery);
        }
        
        if (maxPop) {
            maxPop.addEventListener('input', updateQuery);
        }
    }
    
    // Mettre à jour la requête affichée
    function updateQuery() {
        const deptSelect = document.getElementById('dept-select');
        const usePopCheckbox = document.getElementById('use-population');
        const minPop = document.getElementById('min-pop');
        const maxPop = document.getElementById('max-pop');
        const queryTextarea = document.getElementById('generated-query');
        
        if (!queryTextarea) return;
        
        let conditions = [];
        
        // Filtre par département
        if (deptSelect) {
            const selectedDepts = Array.from(deptSelect.selectedOptions)
                .map(option => option.value)
                .filter(value => value !== '');
            
            if (selectedDepts.length > 0) {
                if (selectedDepts.length === 1) {
                    conditions.push(`department_code = '${selectedDepts[0]}'`);
                } else {
                    const depts = selectedDepts.map(d => `'${d}'`).join(', ');
                    conditions.push(`department_code IN (${depts})`);
                }
            }
        }
        
        // Filtre par population
        if (usePopCheckbox && usePopCheckbox.checked) {
            const min = minPop && minPop.value ? parseInt(minPop.value) : null;
            const max = maxPop && maxPop.value ? parseInt(maxPop.value) : null;
            
            if (min && max) {
                conditions.push(`population BETWEEN ${min} AND ${max}`);
            } else if (min) {
                conditions.push(`population >= ${min}`);
            } else if (max) {
                conditions.push(`population <= ${max}`);
            }
        }
        
        // Construire la requête
        let query = 'SELECT * FROM subscribers';
        if (conditions.length > 0) {
            query += ' WHERE ' + conditions.join(' AND ');
        }
        
        queryTextarea.value = query;
    }
    
    // Fonctions globales
    window.applyQuickFilter = function(type) {
        resetGeoFilter();
        
        const deptSelect = document.getElementById('dept-select');
        const usePopCheckbox = document.getElementById('use-population');
        const minPop = document.getElementById('min-pop');
        const maxPop = document.getElementById('max-pop');
        const popControls = document.getElementById('population-controls');
        
        switch(type) {
            case 'small':
                usePopCheckbox.checked = true;
                popControls.style.display = 'block';
                maxPop.value = 2000;
                break;
            case 'medium':
                usePopCheckbox.checked = true;
                popControls.style.display = 'block';
                minPop.value = 2000;
                maxPop.value = 10000;
                break;
            case 'large':
                usePopCheckbox.checked = true;
                popControls.style.display = 'block';
                minPop.value = 10000;
                break;
            case 'idf':
                ['75', '77', '78', '91', '92', '93', '94', '95'].forEach(dept => {
                    const option = deptSelect.querySelector(`option[value="${dept}"]`);
                    if (option) option.selected = true;
                });
                break;
            case 'paca':
                ['04', '05', '06', '13', '83', '84'].forEach(dept => {
                    const option = deptSelect.querySelector(`option[value="${dept}"]`);
                    if (option) option.selected = true;
                });
                break;
            case 'aura':
                ['01', '03', '07', '15', '26', '38', '42', '43', '63', '69', '73', '74'].forEach(dept => {
                    const option = deptSelect.querySelector(`option[value="${dept}"]`);
                    if (option) option.selected = true;
                });
                break;
        }
        updateQuery();
    };
    
    window.resetGeoFilter = function() {
        const deptSelect = document.getElementById('dept-select');
        const usePopCheckbox = document.getElementById('use-population');
        const minPop = document.getElementById('min-pop');
        const maxPop = document.getElementById('max-pop');
        const popControls = document.getElementById('population-controls');
        
        if (deptSelect) {
            Array.from(deptSelect.options).forEach(option => option.selected = false);
        }
        if (usePopCheckbox) usePopCheckbox.checked = false;
        if (minPop) minPop.value = '';
        if (maxPop) maxPop.value = '';
        if (popControls) popControls.style.display = 'none';
        updateQuery();
    };
    
    window.applyGeoFilter = function() {
        const queryTextarea = document.getElementById('generated-query');
        if (!queryTextarea) return;
        
        const query = queryTextarea.value;
        
        // Chercher le champ de requête SQL dans Listmonk
        const sqlTextarea = document.querySelector('textarea[placeholder*="SQL"]') || 
                           document.querySelector('.query textarea') ||
                           document.querySelector('textarea:not(#generated-query)');
        
        if (sqlTextarea) {
            sqlTextarea.value = query;
            sqlTextarea.dispatchEvent(new Event('input', { bubbles: true }));
            
            // Déclencher la recherche
            setTimeout(() => {
                const searchButton = document.querySelector('button[type="submit"]') ||
                                   document.querySelector('.button.is-primary:not([onclick])');
                if (searchButton) {
                    searchButton.click();
                }
            }, 100);
        } else {
            copyQuery();
            alert('Requête copiée dans le presse-papiers. Collez-la dans le champ de recherche SQL.');
        }
    };
    
    window.copyQuery = function() {
        const queryTextarea = document.getElementById('generated-query');
        if (queryTextarea) {
            queryTextarea.select();
            document.execCommand('copy');
            
            // Feedback visuel
            const button = event.target;
            const originalText = button.textContent;
            button.textContent = '✅ Copié !';
            button.classList.add('is-success');
            setTimeout(() => {
                button.textContent = originalText;
                button.classList.remove('is-success');
            }, 2000);
        }
    };
    
    // Initialisation
    function init() {
        if (isSubscribersPage()) {
            setTimeout(createGeoTargetingUI, 1000);
        }
    }
    
    // Observer les changements de page
    let currentPath = window.location.pathname + window.location.hash;
    setInterval(() => {
        const newPath = window.location.pathname + window.location.hash;
        if (newPath !== currentPath) {
            currentPath = newPath;
            if (isSubscribersPage()) {
                setTimeout(createGeoTargetingUI, 1000);
            }
        }
    }, 1000);
    
    // Lancer l'initialisation
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
EOF

# Injecter le script dans le conteneur
echo "📦 Injection du script dans le conteneur..."
docker cp /tmp/geo-targeting-inject.js "$CONTAINER_NAME":/listmonk/static/geo-targeting.js

# Créer un script d'injection dans l'HTML
cat > /tmp/inject-script.sh << 'EOF'
#!/bin/sh
# Script à exécuter dans le conteneur pour injecter le JavaScript

# Chercher les fichiers HTML dans Listmonk
find /listmonk -name "*.html" -o -name "index.html" | while read file; do
    if [ -f "$file" ] && ! grep -q "geo-targeting.js" "$file"; then
        echo "Injection dans $file"
        sed -i 's|</body>|<script src="/static/geo-targeting.js"></script>\n</body>|g' "$file"
    fi
done

# Aussi essayer dans les templates
find /listmonk -name "*.tmpl" -o -name "*.tpl" | while read file; do
    if [ -f "$file" ] && ! grep -q "geo-targeting.js" "$file"; then
        echo "Injection dans $file"
        sed -i 's|</body>|<script src="/static/geo-targeting.js"></script>\n</body>|g' "$file"
    fi
done
EOF

docker cp /tmp/inject-script.sh "$CONTAINER_NAME":/tmp/inject-script.sh
docker exec "$CONTAINER_NAME" chmod +x /tmp/inject-script.sh
docker exec "$CONTAINER_NAME" /tmp/inject-script.sh

echo ""
echo "4. Redémarrage du conteneur pour appliquer les modifications..."
docker restart "$CONTAINER_NAME"

echo ""
echo "5. Attente du redémarrage..."
sleep 10

# Nettoyer les fichiers temporaires
rm -f /tmp/geo-targeting-inject.js /tmp/inject-script.sh

echo ""
echo "🎉 Installation terminée !"
echo "========================="
echo ""
echo "✅ L'interface de ciblage géographique est maintenant installée !"
echo ""
echo "🌐 Pour l'utiliser :"
echo "   1. Ouvrez http://localhost:9000"
echo "   2. Allez dans 'Abonnés' (Subscribers)"
echo "   3. L'interface de ciblage apparaîtra en haut de la page"
echo ""
echo "🎯 Fonctionnalités disponibles :"
echo "   📍 Sélection multiple de départements"
echo "   👥 Filtres min/max de population"
echo "   ⚡ Filtres rapides (petites/moyennes/grandes communes)"
echo "   🗺️ Filtres par région (Île-de-France, PACA, etc.)"
echo "   🔍 Génération automatique de requêtes SQL"
echo "   📋 Application directe dans Listmonk"
echo ""
echo "💡 Si l'interface n'apparaît pas immédiatement :"
echo "   - Actualisez la page (F5)"
echo "   - Videz le cache du navigateur"
echo "   - Vérifiez que vous êtes sur la page 'Abonnés'"
echo ""