#!/bin/bash

# Script simple pour ajouter le ciblage géographique directement dans Listmonk

echo "🎯 Installation simple du ciblage géographique"
echo "=============================================="

# Configuration
CONTAINER_NAME="listmonk_mairies_app"

echo "1. Correction des données géographiques..."
./fix-geo-data-extraction.sh

echo ""
echo "2. Création d'un bookmarklet pour le ciblage géographique..."

# Créer un bookmarklet JavaScript
cat > geo-targeting-bookmarklet.js << 'EOF'
javascript:(function(){
    // Supprimer l'interface existante si elle existe
    const existing = document.getElementById('geo-targeting-widget');
    if (existing) existing.remove();
    
    // Créer l'interface de ciblage
    const widget = document.createElement('div');
    widget.id = 'geo-targeting-widget';
    widget.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        width: 350px;
        background: white;
        border: 2px solid #3273dc;
        border-radius: 8px;
        padding: 15px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        z-index: 10000;
        font-family: Arial, sans-serif;
        font-size: 14px;
    `;
    
    widget.innerHTML = `
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
            <h3 style="margin: 0; color: #3273dc;">🎯 Ciblage Géographique</h3>
            <button onclick="this.parentElement.parentElement.remove()" style="background: none; border: none; font-size: 18px; cursor: pointer;">×</button>
        </div>
        
        <div style="margin-bottom: 15px;">
            <label style="display: block; margin-bottom: 5px; font-weight: bold;">📍 Départements :</label>
            <select id="geo-dept" multiple style="width: 100%; height: 100px; border: 1px solid #ddd; border-radius: 4px;">
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
            <small style="color: #666;">Maintenez Ctrl/Cmd pour sélectionner plusieurs</small>
        </div>
        
        <div style="margin-bottom: 15px;">
            <label style="display: block; margin-bottom: 5px;">
                <input type="checkbox" id="geo-pop-filter"> 👥 Filtrer par population
            </label>
            <div id="geo-pop-controls" style="display: none; margin-top: 8px;">
                <div style="display: flex; gap: 10px;">
                    <div>
                        <label style="font-size: 12px;">Min habitants</label>
                        <input type="number" id="geo-min-pop" placeholder="0" style="width: 80px; padding: 4px; border: 1px solid #ddd; border-radius: 4px;">
                    </div>
                    <div>
                        <label style="font-size: 12px;">Max habitants</label>
                        <input type="number" id="geo-max-pop" placeholder="100000" style="width: 80px; padding: 4px; border: 1px solid #ddd; border-radius: 4px;">
                    </div>
                </div>
            </div>
        </div>
        
        <div style="margin-bottom: 15px;">
            <label style="display: block; margin-bottom: 5px; font-weight: bold;">⚡ Filtres rapides :</label>
            <div style="display: flex; flex-wrap: wrap; gap: 5px;">
                <button onclick="geoQuickFilter('small')" style="padding: 4px 8px; font-size: 11px; border: 1px solid #ddd; background: #f8f9fa; border-radius: 4px; cursor: pointer;">🏘️ Petites (&lt;2k)</button>
                <button onclick="geoQuickFilter('medium')" style="padding: 4px 8px; font-size: 11px; border: 1px solid #ddd; background: #f8f9fa; border-radius: 4px; cursor: pointer;">🏙️ Moyennes (2k-10k)</button>
                <button onclick="geoQuickFilter('large')" style="padding: 4px 8px; font-size: 11px; border: 1px solid #ddd; background: #f8f9fa; border-radius: 4px; cursor: pointer;">🏢 Grandes (&gt;10k)</button>
                <button onclick="geoQuickFilter('idf')" style="padding: 4px 8px; font-size: 11px; border: 1px solid #ddd; background: #e3f2fd; border-radius: 4px; cursor: pointer;">🏛️ IDF</button>
                <button onclick="geoQuickFilter('paca')" style="padding: 4px 8px; font-size: 11px; border: 1px solid #ddd; background: #e3f2fd; border-radius: 4px; cursor: pointer;">🌊 PACA</button>
            </div>
        </div>
        
        <div style="margin-bottom: 15px;">
            <label style="display: block; margin-bottom: 5px; font-weight: bold;">🔍 Requête SQL :</label>
            <textarea id="geo-query" readonly style="width: 100%; height: 60px; font-family: monospace; font-size: 12px; background: #f5f5f5; border: 1px solid #ddd; border-radius: 4px; padding: 5px; resize: vertical;"></textarea>
        </div>
        
        <div style="display: flex; gap: 8px;">
            <button onclick="geoApplyFilter()" style="flex: 1; padding: 8px; background: #3273dc; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: bold;">🎯 Appliquer</button>
            <button onclick="geoResetFilter()" style="padding: 8px 12px; background: #f5f5f5; border: 1px solid #ddd; border-radius: 4px; cursor: pointer;">🔄 Reset</button>
            <button onclick="geoCopyQuery()" style="padding: 8px 12px; background: #17a2b8; color: white; border: none; border-radius: 4px; cursor: pointer;">📋 Copier</button>
        </div>
    `;
    
    document.body.appendChild(widget);
    
    // Gestionnaires d'événements
    document.getElementById('geo-pop-filter').addEventListener('change', function() {
        document.getElementById('geo-pop-controls').style.display = this.checked ? 'block' : 'none';
        geoUpdateQuery();
    });
    
    document.getElementById('geo-dept').addEventListener('change', geoUpdateQuery);
    document.getElementById('geo-min-pop').addEventListener('input', geoUpdateQuery);
    document.getElementById('geo-max-pop').addEventListener('input', geoUpdateQuery);
    
    // Fonctions globales
    window.geoUpdateQuery = function() {
        const deptSelect = document.getElementById('geo-dept');
        const usePopFilter = document.getElementById('geo-pop-filter').checked;
        const minPop = document.getElementById('geo-min-pop').value;
        const maxPop = document.getElementById('geo-max-pop').value;
        const queryTextarea = document.getElementById('geo-query');
        
        let conditions = [];
        
        // Départements
        const selectedDepts = Array.from(deptSelect.selectedOptions).map(opt => opt.value);
        if (selectedDepts.length > 0) {
            if (selectedDepts.length === 1) {
                conditions.push(`department_code = '${selectedDepts[0]}'`);
            } else {
                conditions.push(`department_code IN (${selectedDepts.map(d => `'${d}'`).join(', ')})`);
            }
        }
        
        // Population
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
        }
        geoUpdateQuery();
    };
    
    window.geoResetFilter = function() {
        document.getElementById('geo-dept').selectedIndex = -1;
        document.getElementById('geo-pop-filter').checked = false;
        document.getElementById('geo-pop-controls').style.display = 'none';
        document.getElementById('geo-min-pop').value = '';
        document.getElementById('geo-max-pop').value = '';
        geoUpdateQuery();
    };
    
    window.geoApplyFilter = function() {
        const query = document.getElementById('geo-query').value;
        const sqlTextarea = document.querySelector('textarea[placeholder*="SQL"]') || 
                           document.querySelector('textarea');
        
        if (sqlTextarea) {
            sqlTextarea.value = query;
            sqlTextarea.dispatchEvent(new Event('input', { bubbles: true }));
            
            // Chercher et cliquer sur le bouton de recherche
            setTimeout(() => {
                const searchBtn = document.querySelector('button[type="submit"]') ||
                                document.querySelector('.button.is-primary');
                if (searchBtn) searchBtn.click();
            }, 100);
            
            alert('✅ Filtre appliqué ! Vérifiez les résultats ci-dessous.');
        } else {
            geoCopyQuery();
            alert('📋 Requête copiée ! Collez-la dans le champ de recherche SQL.');
        }
    };
    
    window.geoCopyQuery = function() {
        const query = document.getElementById('geo-query').value;
        navigator.clipboard.writeText(query).then(() => {
            const btn = event.target;
            const originalText = btn.textContent;
            btn.textContent = '✅ Copié !';
            setTimeout(() => btn.textContent = originalText, 2000);
        });
    };
    
    // Initialiser
    geoUpdateQuery();
})();
EOF

echo "✅ Bookmarklet créé : geo-targeting-bookmarklet.js"

echo ""
echo "3. Création d'un script d'injection simple..."

# Créer un script d'injection plus simple
cat > inject-geo-simple.js << 'EOF'
// Script d'injection simple pour le ciblage géographique

// Ajouter un bouton dans la barre de navigation
function addGeoButton() {
    // Vérifier si le bouton existe déjà
    if (document.getElementById('geo-btn')) return;
    
    // Créer le bouton
    const btn = document.createElement('button');
    btn.id = 'geo-btn';
    btn.innerHTML = '🎯 Ciblage Géo';
    btn.style.cssText = `
        position: fixed;
        top: 10px;
        right: 10px;
        z-index: 9999;
        background: #3273dc;
        color: white;
        border: none;
        padding: 8px 12px;
        border-radius: 4px;
        cursor: pointer;
        font-size: 12px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    `;
    
    // Ajouter l'événement click avec le code du bookmarklet
    btn.onclick = function() {
        // Code du bookmarklet ici (copié depuis geo-targeting-bookmarklet.js)
        eval(document.querySelector('#geo-bookmarklet-code').textContent);
    };
    
    document.body.appendChild(btn);
}

// Script caché contenant le code du bookmarklet
const script = document.createElement('script');
script.id = 'geo-bookmarklet-code';
script.type = 'text/plain';
script.textContent = `
// [Le contenu du bookmarklet sera inséré ici]
`;
document.head.appendChild(script);

// Ajouter le bouton quand la page est chargée
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', addGeoButton);
} else {
    addGeoButton();
}

// Observer les changements de page (pour les SPA)
setInterval(addGeoButton, 2000);
EOF

echo "✅ Script d'injection créé : inject-geo-simple.js"

echo ""
echo "4. Création d'instructions d'utilisation..."

cat > UTILISATION_CIBLAGE_GEO.md << 'EOF'
# 🎯 Guide d'utilisation du Ciblage Géographique

## 🚀 Méthode 1 : Bookmarklet (Recommandée)

### Installation :
1. Copiez le contenu du fichier `geo-targeting-bookmarklet.js`
2. Créez un nouveau marque-page dans votre navigateur
3. Collez le code comme URL du marque-page
4. Nommez-le "🎯 Ciblage Géo"

### Utilisation :
1. Allez sur la page **Abonnés** de Listmonk
2. Cliquez sur votre marque-page "🎯 Ciblage Géo"
3. Une interface apparaît en haut à droite
4. Configurez vos filtres et cliquez "Appliquer"

## 🎯 Fonctionnalités disponibles

### 📍 Sélection de départements
- **Île-de-France** : 75, 77, 78, 91, 92, 93, 94, 95
- **PACA** : 04, 05, 06, 13, 83, 84
- **Auvergne-Rhône-Alpes** : 01, 03, 07, 15, 26, 38, 42, 43, 63, 69, 73, 74
- **Nouvelle-Aquitaine** : 16, 17, 19, 23, 24, 33, 40, 47, 64, 79, 86, 87
- **Occitanie** : 09, 11, 12, 30, 31, 32, 34, 46, 48, 65, 66, 81, 82

### 👥 Filtres de population
- **Petites communes** : < 2000 habitants
- **Communes moyennes** : 2000-10000 habitants
- **Grandes communes** : > 10000 habitants
- **Filtres personnalisés** : Min/Max au choix

### ⚡ Filtres rapides
- 🏘️ **Petites** : Communes < 2000 hab.
- 🏙️ **Moyennes** : Communes 2000-10000 hab.
- 🏢 **Grandes** : Communes > 10000 hab.
- 🏛️ **IDF** : Tous les départements d'Île-de-France
- 🌊 **PACA** : Tous les départements PACA

## 📋 Exemples d'utilisation

### Campagne pour les grandes métropoles
1. Cliquez sur "🏢 Grandes (>10k)"
2. Cliquez "🎯 Appliquer"
3. Résultat : Toutes les communes > 10000 habitants

### Campagne Île-de-France
1. Cliquez sur "🏛️ IDF"
2. Cliquez "🎯 Appliquer"
3. Résultat : Toutes les mairies franciliennes

### Campagne personnalisée
1. Sélectionnez les départements souhaités (Ctrl+clic)
2. Cochez "Filtrer par population"
3. Définissez Min/Max habitants
4. Cliquez "🎯 Appliquer"

## 🔧 Dépannage

### L'interface n'apparaît pas
- Vérifiez que vous êtes sur la page "Abonnés"
- Actualisez la page (F5)
- Recliquez sur le bookmarklet

### La requête ne s'applique pas
- Vérifiez qu'il y a un champ de recherche SQL sur la page
- Utilisez le bouton "📋 Copier" et collez manuellement

### Pas de résultats
- Vérifiez que les données géographiques sont bien extraites
- Lancez `./fix-geo-data-extraction.sh` si nécessaire

## 📊 Vérification des données

Pour vérifier que les données géographiques sont correctes :

```sql
-- Vérifier les départements
SELECT department_code, COUNT(*) 
FROM subscribers 
WHERE department_code IS NOT NULL 
GROUP BY department_code 
ORDER BY COUNT(*) DESC;

-- Vérifier les populations
SELECT 
    CASE 
        WHEN population < 500 THEN 'Très petites'
        WHEN population < 2000 THEN 'Petites'
        WHEN population < 10000 THEN 'Moyennes'
        ELSE 'Grandes'
    END as taille,
    COUNT(*) as nombre
FROM subscribers 
WHERE population > 0 
GROUP BY taille;
```
EOF

echo "✅ Guide d'utilisation créé : UTILISATION_CIBLAGE_GEO.md"

echo ""
echo "🎉 Installation simple terminée !"
echo "================================="
echo ""
echo "🎯 UTILISATION IMMÉDIATE :"
echo ""
echo "1. 📖 Lisez le guide : UTILISATION_CIBLAGE_GEO.md"
echo ""
echo "2. 🔖 Créez un bookmarklet :"
echo "   - Copiez le contenu de geo-targeting-bookmarklet.js"
echo "   - Créez un marque-page avec ce code"
echo "   - Nommez-le '🎯 Ciblage Géo'"
echo ""
echo "3. 🚀 Utilisez-le :"
echo "   - Allez sur la page 'Abonnés' de Listmonk"
echo "   - Cliquez sur votre marque-page"
echo "   - Configurez vos filtres"
echo "   - Cliquez 'Appliquer'"
echo ""
echo "✨ L'interface apparaîtra en haut à droite de votre écran !"
echo ""