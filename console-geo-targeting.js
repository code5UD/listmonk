// 🎯 CIBLAGE GÉOGRAPHIQUE POUR LISTMONK
// Copiez et collez ce code dans la console de votre navigateur (F12)
// sur la page "Abonnés" de Listmonk

(function() {
    'use strict';
    
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
        width: 380px;
        background: white;
        border: 3px solid #3273dc;
        border-radius: 12px;
        padding: 20px;
        box-shadow: 0 8px 25px rgba(0,0,0,0.2);
        z-index: 10000;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        font-size: 14px;
        max-height: 90vh;
        overflow-y: auto;
    `;
    
    widget.innerHTML = `
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 2px solid #f0f0f0; padding-bottom: 15px;">
            <h3 style="margin: 0; color: #3273dc; font-size: 18px; font-weight: bold;">🎯 Ciblage Géographique</h3>
            <button onclick="this.parentElement.parentElement.remove()" style="background: #ff4757; color: white; border: none; border-radius: 50%; width: 30px; height: 30px; font-size: 16px; cursor: pointer; font-weight: bold;">×</button>
        </div>
        
        <div style="margin-bottom: 20px;">
            <label style="display: block; margin-bottom: 8px; font-weight: bold; color: #2c3e50;">📍 Sélection des départements :</label>
            <select id="geo-dept" multiple style="width: 100%; height: 120px; border: 2px solid #ddd; border-radius: 8px; padding: 8px; font-size: 13px;">
                <optgroup label="🏛️ Île-de-France" style="font-weight: bold; color: #3273dc;">
                    <option value="75">75 - Paris</option>
                    <option value="77">77 - Seine-et-Marne</option>
                    <option value="78">78 - Yvelines</option>
                    <option value="91">91 - Essonne</option>
                    <option value="92">92 - Hauts-de-Seine</option>
                    <option value="93">93 - Seine-Saint-Denis</option>
                    <option value="94">94 - Val-de-Marne</option>
                    <option value="95">95 - Val-d'Oise</option>
                </optgroup>
                <optgroup label="🌊 Provence-Alpes-Côte d'Azur" style="font-weight: bold; color: #00b894;">
                    <option value="04">04 - Alpes-de-Haute-Provence</option>
                    <option value="05">05 - Hautes-Alpes</option>
                    <option value="06">06 - Alpes-Maritimes</option>
                    <option value="13">13 - Bouches-du-Rhône</option>
                    <option value="83">83 - Var</option>
                    <option value="84">84 - Vaucluse</option>
                </optgroup>
                <optgroup label="🏔️ Auvergne-Rhône-Alpes" style="font-weight: bold; color: #6c5ce7;">
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
                <optgroup label="🌿 Nouvelle-Aquitaine" style="font-weight: bold; color: #00b894;">
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
                <optgroup label="🌞 Occitanie" style="font-weight: bold; color: #fdcb6e;">
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
                <optgroup label="🌊 Bretagne" style="font-weight: bold; color: #0984e3;">
                    <option value="22">22 - Côtes-d'Armor</option>
                    <option value="29">29 - Finistère</option>
                    <option value="35">35 - Ille-et-Vilaine</option>
                    <option value="56">56 - Morbihan</option>
                </optgroup>
                <optgroup label="🏰 Centre-Val de Loire" style="font-weight: bold; color: #a29bfe;">
                    <option value="18">18 - Cher</option>
                    <option value="28">28 - Eure-et-Loir</option>
                    <option value="36">36 - Indre</option>
                    <option value="37">37 - Indre-et-Loire</option>
                    <option value="41">41 - Loir-et-Cher</option>
                    <option value="45">45 - Loiret</option>
                </optgroup>
            </select>
            <small style="color: #666; font-style: italic;">💡 Maintenez Ctrl/Cmd pour sélectionner plusieurs départements</small>
        </div>
        
        <div style="margin-bottom: 20px; background: #f8f9fa; padding: 15px; border-radius: 8px; border: 1px solid #e9ecef;">
            <label style="display: block; margin-bottom: 10px; font-weight: bold;">
                <input type="checkbox" id="geo-pop-filter" style="margin-right: 8px; transform: scale(1.2);"> 👥 Filtrer par population
            </label>
            <div id="geo-pop-controls" style="display: none; margin-top: 12px;">
                <div style="display: flex; gap: 15px; align-items: center;">
                    <div style="flex: 1;">
                        <label style="font-size: 12px; font-weight: bold; color: #495057; display: block; margin-bottom: 4px;">Min habitants</label>
                        <input type="number" id="geo-min-pop" placeholder="0" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px;">
                    </div>
                    <div style="flex: 1;">
                        <label style="font-size: 12px; font-weight: bold; color: #495057; display: block; margin-bottom: 4px;">Max habitants</label>
                        <input type="number" id="geo-max-pop" placeholder="100000" style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px;">
                    </div>
                </div>
            </div>
        </div>
        
        <div style="margin-bottom: 20px;">
            <label style="display: block; margin-bottom: 10px; font-weight: bold; color: #2c3e50;">⚡ Filtres rapides :</label>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 10px;">
                <button onclick="geoQuickFilter('small')" style="padding: 10px; font-size: 12px; border: 2px solid #74b9ff; background: #dfe6e9; color: #2d3436; border-radius: 8px; cursor: pointer; font-weight: bold; transition: all 0.2s;">🏘️ Petites<br>(&lt; 2k hab.)</button>
                <button onclick="geoQuickFilter('medium')" style="padding: 10px; font-size: 12px; border: 2px solid #00b894; background: #dfe6e9; color: #2d3436; border-radius: 8px; cursor: pointer; font-weight: bold; transition: all 0.2s;">🏙️ Moyennes<br>(2k-10k hab.)</button>
                <button onclick="geoQuickFilter('large')" style="padding: 10px; font-size: 12px; border: 2px solid #e17055; background: #dfe6e9; color: #2d3436; border-radius: 8px; cursor: pointer; font-weight: bold; transition: all 0.2s;">🏢 Grandes<br>(&gt; 10k hab.)</button>
                <button onclick="geoQuickFilter('metro')" style="padding: 10px; font-size: 12px; border: 2px solid #6c5ce7; background: #dfe6e9; color: #2d3436; border-radius: 8px; cursor: pointer; font-weight: bold; transition: all 0.2s;">🏙️ Métropoles<br>(&gt; 50k hab.)</button>
            </div>
            <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px;">
                <button onclick="geoQuickFilter('idf')" style="padding: 8px; font-size: 11px; border: 2px solid #3273dc; background: #e3f2fd; color: #1565c0; border-radius: 6px; cursor: pointer; font-weight: bold;">🏛️ Île-de-France</button>
                <button onclick="geoQuickFilter('paca')" style="padding: 8px; font-size: 11px; border: 2px solid #00b894; background: #e8f5e8; color: #2e7d32; border-radius: 6px; cursor: pointer; font-weight: bold;">🌊 PACA</button>
                <button onclick="geoQuickFilter('aura')" style="padding: 8px; font-size: 11px; border: 2px solid #6c5ce7; background: #f3e5f5; color: #7b1fa2; border-radius: 6px; cursor: pointer; font-weight: bold;">🏔️ AURA</button>
            </div>
        </div>
        
        <div style="margin-bottom: 20px;">
            <label style="display: block; margin-bottom: 8px; font-weight: bold; color: #2c3e50;">🔍 Requête SQL générée :</label>
            <textarea id="geo-query" readonly style="width: 100%; height: 80px; font-family: 'Courier New', monospace; font-size: 12px; background: #f8f9fa; border: 2px solid #dee2e6; border-radius: 8px; padding: 10px; resize: vertical; color: #495057;"></textarea>
        </div>
        
        <div style="display: grid; grid-template-columns: 2fr 1fr 1fr; gap: 10px;">
            <button onclick="geoApplyFilter()" style="padding: 12px; background: linear-gradient(135deg, #3273dc 0%, #2c5aa0 100%); color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: bold; font-size: 14px; box-shadow: 0 4px 8px rgba(50, 115, 220, 0.3);">🎯 Appliquer le filtre</button>
            <button onclick="geoResetFilter()" style="padding: 12px; background: #f8f9fa; border: 2px solid #dee2e6; color: #495057; border-radius: 8px; cursor: pointer; font-weight: bold;">🔄 Reset</button>
            <button onclick="geoCopyQuery()" style="padding: 12px; background: linear-gradient(135deg, #17a2b8 0%, #138496 100%); color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: bold; box-shadow: 0 4px 8px rgba(23, 162, 184, 0.3);">📋 Copier</button>
        </div>
        
        <div style="margin-top: 15px; padding: 10px; background: #e8f4fd; border-radius: 6px; border-left: 4px solid #3273dc;">
            <small style="color: #1565c0; font-weight: bold;">💡 Astuce : Allez d'abord sur la page "Abonnés" puis utilisez cette interface pour filtrer vos contacts par zone géographique !</small>
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
        document.getElementById('geo-dept').selectedIndex = -1;
        document.getElementById('geo-pop-filter').checked = false;
        document.getElementById('geo-pop-controls').style.display = 'none';
        document.getElementById('geo-min-pop').value = '';
        document.getElementById('geo-max-pop').value = '';
        geoUpdateQuery();
    };
    
    window.geoApplyFilter = function() {
        const query = document.getElementById('geo-query').value;
        
        // Chercher le champ de requête SQL dans Listmonk
        const sqlTextarea = document.querySelector('textarea[placeholder*="SQL"]') || 
                           document.querySelector('textarea[placeholder*="sql"]') ||
                           document.querySelector('textarea[placeholder*="requête"]') ||
                           document.querySelector('textarea[placeholder*="query"]') ||
                           document.querySelector('textarea');
        
        if (sqlTextarea) {
            sqlTextarea.value = query;
            sqlTextarea.dispatchEvent(new Event('input', { bubbles: true }));
            sqlTextarea.dispatchEvent(new Event('change', { bubbles: true }));
            
            // Chercher et cliquer sur le bouton de recherche
            setTimeout(() => {
                const searchBtn = document.querySelector('button[type="submit"]') ||
                                document.querySelector('.button.is-primary') ||
                                document.querySelector('button:contains("Requête")') ||
                                document.querySelector('button:contains("Search")');
                if (searchBtn) {
                    searchBtn.click();
                    console.log('✅ Filtre appliqué automatiquement !');
                } else {
                    console.log('⚠️ Bouton de recherche non trouvé, requête insérée dans le champ');
                }
            }, 200);
            
            // Feedback visuel
            const btn = event.target;
            const originalText = btn.textContent;
            const originalBg = btn.style.background;
            btn.textContent = '✅ Appliqué !';
            btn.style.background = 'linear-gradient(135deg, #00b894 0%, #00a085 100%)';
            setTimeout(() => {
                btn.textContent = originalText;
                btn.style.background = originalBg;
            }, 3000);
            
        } else {
            // Fallback : copier dans le presse-papiers
            geoCopyQuery();
            alert('📋 Aucun champ SQL trouvé. Requête copiée dans le presse-papiers !\\n\\nCollez-la manuellement dans le champ de recherche.');
        }
    };
    
    window.geoCopyQuery = function() {
        const query = document.getElementById('geo-query').value;
        navigator.clipboard.writeText(query).then(() => {
            const btn = event.target;
            const originalText = btn.textContent;
            const originalBg = btn.style.background;
            btn.textContent = '✅ Copié !';
            btn.style.background = 'linear-gradient(135deg, #00b894 0%, #00a085 100%)';
            setTimeout(() => {
                btn.textContent = originalText;
                btn.style.background = originalBg;
            }, 2000);
            console.log('📋 Requête copiée :', query);
        }).catch(() => {
            // Fallback pour les navigateurs plus anciens
            const textArea = document.createElement('textarea');
            textArea.value = query;
            document.body.appendChild(textArea);
            textArea.select();
            document.execCommand('copy');
            document.body.removeChild(textArea);
            alert('📋 Requête copiée dans le presse-papiers !');
        });
    };
    
    // Initialiser
    geoUpdateQuery();
    
    console.log('🎯 Interface de ciblage géographique chargée !');
    console.log('💡 Utilisez les filtres pour cibler vos mairies par département et population.');
    
})();