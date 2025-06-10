#!/bin/bash

# Script pour créer une interface utilisateur de ciblage géographique

echo "🎨 Création de l'interface de ciblage géographique"
echo "================================================="

# Créer le composant Vue.js pour le ciblage géographique
cat > geo-targeting-component.vue << 'EOF'
<template>
  <div class="geo-targeting">
    <div class="box">
      <h4 class="title is-5">🎯 Ciblage Géographique</h4>
      
      <!-- Sélection des départements -->
      <div class="field">
        <label class="label">📍 Départements</label>
        <div class="control">
          <div class="select is-multiple">
            <select multiple v-model="selectedDepartments" size="8">
              <option value="">-- Tous les départements --</option>
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
              <!-- Autres régions... -->
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
              <input type="checkbox" v-model="usePopulationFilter">
              Filtrer par population
            </label>
          </div>
        </div>
        
        <div v-if="usePopulationFilter" class="field is-grouped">
          <div class="control">
            <label class="label is-small">Min</label>
            <input class="input" type="number" v-model="minPopulation" placeholder="0">
          </div>
          <div class="control">
            <label class="label is-small">Max</label>
            <input class="input" type="number" v-model="maxPopulation" placeholder="100000">
          </div>
        </div>
      </div>

      <!-- Filtres prédéfinis -->
      <div class="field">
        <label class="label">🎯 Filtres rapides</label>
        <div class="field is-grouped is-grouped-multiline">
          <div class="control">
            <button class="button is-small" @click="selectPredefined('small')">
              Petites communes (&lt; 2000 hab.)
            </button>
          </div>
          <div class="control">
            <button class="button is-small" @click="selectPredefined('medium')">
              Communes moyennes (2000-10000 hab.)
            </button>
          </div>
          <div class="control">
            <button class="button is-small" @click="selectPredefined('large')">
              Grandes communes (&gt; 10000 hab.)
            </button>
          </div>
          <div class="control">
            <button class="button is-small" @click="selectPredefined('idf')">
              Île-de-France
            </button>
          </div>
          <div class="control">
            <button class="button is-small" @click="selectPredefined('paca')">
              PACA
            </button>
          </div>
        </div>
      </div>

      <!-- Aperçu de la requête -->
      <div class="field">
        <label class="label">🔍 Requête générée</label>
        <div class="control">
          <textarea class="textarea" readonly :value="generatedQuery" rows="4"></textarea>
        </div>
      </div>

      <!-- Boutons d'action -->
      <div class="field is-grouped">
        <div class="control">
          <button class="button is-primary" @click="applyFilter">
            🎯 Appliquer le filtre
          </button>
        </div>
        <div class="control">
          <button class="button" @click="resetFilter">
            🔄 Réinitialiser
          </button>
        </div>
        <div class="control">
          <button class="button is-info" @click="previewCount">
            📊 Aperçu ({{ estimatedCount }} contacts)
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'GeoTargeting',
  data() {
    return {
      selectedDepartments: [],
      usePopulationFilter: false,
      minPopulation: null,
      maxPopulation: null,
      estimatedCount: 0
    }
  },
  computed: {
    generatedQuery() {
      let conditions = [];
      
      // Filtre par département
      if (this.selectedDepartments.length > 0) {
        if (this.selectedDepartments.length === 1) {
          conditions.push(`department_code = '${this.selectedDepartments[0]}'`);
        } else {
          const depts = this.selectedDepartments.map(d => `'${d}'`).join(', ');
          conditions.push(`department_code IN (${depts})`);
        }
      }
      
      // Filtre par population
      if (this.usePopulationFilter) {
        if (this.minPopulation && this.maxPopulation) {
          conditions.push(`population BETWEEN ${this.minPopulation} AND ${this.maxPopulation}`);
        } else if (this.minPopulation) {
          conditions.push(`population >= ${this.minPopulation}`);
        } else if (this.maxPopulation) {
          conditions.push(`population <= ${this.maxPopulation}`);
        }
      }
      
      let query = 'SELECT * FROM subscribers';
      if (conditions.length > 0) {
        query += ' WHERE ' + conditions.join(' AND ');
      }
      
      return query;
    }
  },
  methods: {
    selectPredefined(type) {
      this.resetFilter();
      
      switch(type) {
        case 'small':
          this.usePopulationFilter = true;
          this.maxPopulation = 2000;
          break;
        case 'medium':
          this.usePopulationFilter = true;
          this.minPopulation = 2000;
          this.maxPopulation = 10000;
          break;
        case 'large':
          this.usePopulationFilter = true;
          this.minPopulation = 10000;
          break;
        case 'idf':
          this.selectedDepartments = ['75', '77', '78', '91', '92', '93', '94', '95'];
          break;
        case 'paca':
          this.selectedDepartments = ['04', '05', '06', '13', '83', '84'];
          break;
      }
    },
    
    resetFilter() {
      this.selectedDepartments = [];
      this.usePopulationFilter = false;
      this.minPopulation = null;
      this.maxPopulation = null;
      this.estimatedCount = 0;
    },
    
    async previewCount() {
      // Simuler un appel API pour compter les résultats
      try {
        const response = await this.$http.post('/api/subscribers/query', {
          query: this.generatedQuery.replace('SELECT *', 'SELECT COUNT(*)')
        });
        this.estimatedCount = response.data.count || 0;
      } catch (e) {
        this.estimatedCount = '?';
      }
    },
    
    applyFilter() {
      // Émettre l'événement pour appliquer le filtre
      this.$emit('filter-applied', {
        query: this.generatedQuery,
        departments: this.selectedDepartments,
        population: this.usePopulationFilter ? {
          min: this.minPopulation,
          max: this.maxPopulation
        } : null
      });
    }
  }
}
</script>

<style scoped>
.geo-targeting {
  margin-bottom: 1rem;
}

.select select[multiple] {
  height: auto;
}

.field.is-grouped .control .label.is-small {
  font-size: 0.75rem;
  margin-bottom: 0.25rem;
}

.textarea[readonly] {
  background-color: #f5f5f5;
  font-family: monospace;
  font-size: 0.875rem;
}
</style>
EOF

echo "✅ Composant Vue.js créé : geo-targeting-component.vue"

# Créer un script d'intégration dans Listmonk
cat > integrate-geo-ui.js << 'EOF'
// Script d'intégration de l'interface de ciblage géographique dans Listmonk

// 1. Ajouter le composant de ciblage géographique
function addGeoTargetingToSubscribers() {
    // Vérifier si nous sommes sur la page des abonnés
    if (!window.location.pathname.includes('/subscribers')) {
        return;
    }
    
    // Créer le conteneur pour le ciblage géographique
    const geoContainer = document.createElement('div');
    geoContainer.id = 'geo-targeting-container';
    geoContainer.innerHTML = `
        <div class="box" style="margin-bottom: 1rem; border-left: 4px solid #3273dc;">
            <h4 class="title is-5">🎯 Ciblage Géographique</h4>
            
            <!-- Sélection des départements -->
            <div class="field">
                <label class="label">📍 Départements</label>
                <div class="control">
                    <div class="select is-multiple">
                        <select id="dept-select" multiple size="6">
                            <option value="">-- Tous les départements --</option>
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
                        <label class="label is-small">Min</label>
                        <input class="input" type="number" id="min-pop" placeholder="0">
                    </div>
                    <div class="control">
                        <label class="label is-small">Max</label>
                        <input class="input" type="number" id="max-pop" placeholder="100000">
                    </div>
                </div>
            </div>

            <!-- Filtres prédéfinis -->
            <div class="field">
                <label class="label">🎯 Filtres rapides</label>
                <div class="field is-grouped is-grouped-multiline">
                    <div class="control">
                        <button class="button is-small" onclick="applyQuickFilter('small')">
                            Petites communes (&lt; 2000 hab.)
                        </button>
                    </div>
                    <div class="control">
                        <button class="button is-small" onclick="applyQuickFilter('medium')">
                            Communes moyennes (2000-10000 hab.)
                        </button>
                    </div>
                    <div class="control">
                        <button class="button is-small" onclick="applyQuickFilter('large')">
                            Grandes communes (&gt; 10000 hab.)
                        </button>
                    </div>
                    <div class="control">
                        <button class="button is-small" onclick="applyQuickFilter('idf')">
                            Île-de-France
                        </button>
                    </div>
                    <div class="control">
                        <button class="button is-small" onclick="applyQuickFilter('paca')">
                            PACA
                        </button>
                    </div>
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
            </div>
        </div>
    `;
    
    // Insérer le conteneur avant la liste des abonnés
    const subscribersContainer = document.querySelector('.subscribers') || document.querySelector('main');
    if (subscribersContainer) {
        subscribersContainer.insertBefore(geoContainer, subscribersContainer.firstChild);
    }
    
    // Ajouter les gestionnaires d'événements
    setupGeoTargetingEvents();
}

// 2. Gestionnaires d'événements
function setupGeoTargetingEvents() {
    // Toggle des contrôles de population
    const usePopCheckbox = document.getElementById('use-population');
    const popControls = document.getElementById('population-controls');
    
    if (usePopCheckbox && popControls) {
        usePopCheckbox.addEventListener('change', function() {
            popControls.style.display = this.checked ? 'block' : 'none';
        });
    }
}

// 3. Fonctions de filtrage
function applyQuickFilter(type) {
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
    }
}

function resetGeoFilter() {
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
}

function applyGeoFilter() {
    const deptSelect = document.getElementById('dept-select');
    const usePopCheckbox = document.getElementById('use-population');
    const minPop = document.getElementById('min-pop');
    const maxPop = document.getElementById('max-pop');
    
    let conditions = [];
    
    // Filtre par département
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
    
    // Filtre par population
    if (usePopCheckbox.checked) {
        const min = minPop.value ? parseInt(minPop.value) : null;
        const max = maxPop.value ? parseInt(maxPop.value) : null;
        
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
    
    // Appliquer la requête dans le champ SQL de Listmonk
    const sqlTextarea = document.querySelector('textarea[placeholder*="SQL"]') || 
                       document.querySelector('.query textarea') ||
                       document.querySelector('textarea');
    
    if (sqlTextarea) {
        sqlTextarea.value = query;
        sqlTextarea.dispatchEvent(new Event('input', { bubbles: true }));
        
        // Déclencher la recherche si possible
        const searchButton = document.querySelector('button[type="submit"]') ||
                           document.querySelector('.button.is-primary');
        if (searchButton) {
            searchButton.click();
        }
    } else {
        // Fallback: copier dans le presse-papiers
        navigator.clipboard.writeText(query).then(() => {
            alert('Requête copiée dans le presse-papiers:\\n\\n' + query);
        });
    }
}

// 4. Initialisation
function initGeoTargeting() {
    // Attendre que la page soit chargée
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', addGeoTargetingToSubscribers);
    } else {
        addGeoTargetingToSubscribers();
    }
    
    // Observer les changements de page (SPA)
    const observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            if (mutation.type === 'childList' && 
                window.location.pathname.includes('/subscribers') &&
                !document.getElementById('geo-targeting-container')) {
                addGeoTargetingToSubscribers();
            }
        });
    });
    
    observer.observe(document.body, {
        childList: true,
        subtree: true
    });
}

// Lancer l'initialisation
initGeoTargeting();
EOF

echo "✅ Script d'intégration créé : integrate-geo-ui.js"

echo ""
echo "🎨 Interface de ciblage géographique créée !"
echo "============================================"
echo ""
echo "📁 Fichiers créés :"
echo "   📄 geo-targeting-component.vue - Composant Vue.js"
echo "   📄 integrate-geo-ui.js - Script d'intégration"
echo ""
echo "🚀 Pour intégrer dans Listmonk :"
echo "   1. Copier integrate-geo-ui.js dans les assets statiques"
echo "   2. Inclure le script dans l'interface Listmonk"
echo "   3. L'interface apparaîtra automatiquement sur la page des abonnés"
echo ""
echo "✨ Fonctionnalités de l'interface :"
echo "   🎯 Sélection multiple de départements"
echo "   👥 Filtres min/max de population"
echo "   ⚡ Filtres rapides prédéfinis"
echo "   🔍 Génération automatique de requêtes SQL"
echo "   📋 Application directe dans Listmonk"
echo ""