<template>
  <div class="advanced-targeting">
    <div class="box">
      <h3 class="title is-5">{{ $t('targeting.advanced.title') }}</h3>
      <p class="subtitle is-6">{{ $t('targeting.advanced.description') }}</p>

      <!-- Filter Builder -->
      <div class="filter-builder">
        <div class="field">
          <label class="label">{{ $t('targeting.advanced.operator') }}</label>
          <div class="control">
            <div class="select">
              <select v-model="filter.advanced_filters.operator">
                <option value="AND">{{ $t('targeting.advanced.and') }}</option>
                <option value="OR">{{ $t('targeting.advanced.or') }}</option>
              </select>
            </div>
          </div>
        </div>

        <!-- Rules -->
        <div class="rules-container">
          <h4 class="title is-6">{{ $t('targeting.advanced.rules') }}</h4>
          
          <div 
            v-for="(rule, index) in filter.advanced_filters.rules" 
            :key="index"
            class="rule-item box"
          >
            <div class="columns">
              <div class="column is-3">
                <div class="field">
                  <label class="label">{{ $t('targeting.advanced.field') }}</label>
                  <div class="control">
                    <div class="select is-fullwidth">
                      <select v-model="rule.field" @change="onFieldChange(rule)">
                        <option value="department">{{ $t('targeting.advanced.department') }}</option>
                        <option value="population">{{ $t('targeting.advanced.population') }}</option>
                        <option value="region">{{ $t('targeting.advanced.region') }}</option>
                        <option value="commune_name">{{ $t('targeting.advanced.communeName') }}</option>
                        <option value="postal_code">{{ $t('targeting.advanced.postalCode') }}</option>
                      </select>
                    </div>
                  </div>
                </div>
              </div>

              <div class="column is-3">
                <div class="field">
                  <label class="label">{{ $t('targeting.advanced.operator') }}</label>
                  <div class="control">
                    <div class="select is-fullwidth">
                      <select v-model="rule.operator">
                        <option 
                          v-for="op in getAvailableOperators(rule.field)" 
                          :key="op.value" 
                          :value="op.value"
                        >
                          {{ op.label }}
                        </option>
                      </select>
                    </div>
                  </div>
                </div>
              </div>

              <div class="column is-5">
                <div class="field">
                  <label class="label">{{ $t('targeting.advanced.value') }}</label>
                  <div class="control">
                    <!-- Text input for simple values -->
                    <input 
                      v-if="isSimpleValue(rule)"
                      v-model="rule.value"
                      class="input"
                      :type="getInputType(rule.field)"
                      :placeholder="getPlaceholder(rule.field)"
                    />
                    
                    <!-- Multi-select for array values -->
                    <b-taginput
                      v-else-if="isArrayValue(rule)"
                      v-model="rule.value"
                      :data="getFieldOptions(rule.field)"
                      autocomplete
                      :placeholder="getPlaceholder(rule.field)"
                    />
                    
                    <!-- Population range -->
                    <div v-else-if="rule.operator === 'between' && rule.field === 'population'" class="field has-addons">
                      <div class="control">
                        <input 
                          v-model.number="rule.value.min"
                          class="input"
                          type="number"
                          placeholder="Min"
                        />
                      </div>
                      <div class="control">
                        <span class="button is-static">-</span>
                      </div>
                      <div class="control">
                        <input 
                          v-model.number="rule.value.max"
                          class="input"
                          type="number"
                          placeholder="Max"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div class="column is-1">
                <div class="field">
                  <label class="label">&nbsp;</label>
                  <div class="control">
                    <button 
                      @click="removeRule(index)"
                      class="button is-danger is-small"
                      :disabled="filter.advanced_filters.rules.length <= 1"
                    >
                      <span class="icon">
                        <i class="fas fa-trash"></i>
                      </span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="field">
            <div class="control">
              <button @click="addRule" class="button is-primary is-small">
                <span class="icon">
                  <i class="fas fa-plus"></i>
                </span>
                <span>{{ $t('targeting.advanced.addRule') }}</span>
              </button>
            </div>
          </div>
        </div>

        <!-- Preview and Actions -->
        <div class="field is-grouped">
          <div class="control">
            <button 
              @click="previewTargeting"
              class="button is-info"
              :loading="previewing"
            >
              <span class="icon">
                <i class="fas fa-eye"></i>
              </span>
              <span>{{ $t('targeting.advanced.preview') }}</span>
            </button>
          </div>
          
          <div class="control">
            <button 
              @click="applyTargeting"
              class="button is-primary"
              :loading="applying"
            >
              <span class="icon">
                <i class="fas fa-search"></i>
              </span>
              <span>{{ $t('targeting.advanced.apply') }}</span>
            </button>
          </div>
          
          <div class="control">
            <button 
              @click="resetFilter"
              class="button"
            >
              <span class="icon">
                <i class="fas fa-refresh"></i>
              </span>
              <span>{{ $t('targeting.advanced.reset') }}</span>
            </button>
          </div>
        </div>

        <!-- Generated SQL Preview -->
        <div v-if="showSqlPreview && sqlPreview" class="notification is-light">
          <h5 class="title is-6">{{ $t('targeting.advanced.sqlPreview') }}</h5>
          <pre class="content"><code>{{ sqlPreview }}</code></pre>
        </div>
      </div>
    </div>

    <!-- Results Preview -->
    <div v-if="previewResults" class="box">
      <h3 class="title is-5">{{ $t('targeting.advanced.results') }}</h3>
      
      <div class="level">
        <div class="level-left">
          <div class="level-item">
            <div class="content">
              <p class="title is-4">{{ previewResults.total_count }}</p>
              <p class="subtitle is-6">{{ $t('targeting.advanced.totalRecipients') }}</p>
            </div>
          </div>
          <div class="level-item">
            <div class="content">
              <p class="title is-4">{{ previewResults.statistics.total_communes }}</p>
              <p class="subtitle is-6">{{ $t('targeting.advanced.totalCommunes') }}</p>
            </div>
          </div>
        </div>
        <div class="level-right">
          <div class="level-item">
            <button 
              @click="exportResults"
              class="button is-success"
              :loading="exporting"
              :disabled="!previewResults.subscribers.length"
            >
              <span class="icon">
                <i class="fas fa-download"></i>
              </span>
              <span>{{ $t('targeting.advanced.export') }}</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Sample Results Table -->
      <div v-if="previewResults.subscribers.length > 0">
        <h4 class="title is-6">{{ $t('targeting.advanced.sampleResults') }}</h4>
        <b-table
          :data="previewResults.subscribers.slice(0, 10)"
          :loading="applying"
        >
          <b-table-column field="subscriber_email" :label="$t('targeting.advanced.email')" v-slot="props">
            {{ props.row.subscriber_email }}
          </b-table-column>
          
          <b-table-column field="subscriber_name" :label="$t('targeting.advanced.name')" v-slot="props">
            {{ props.row.subscriber_name }}
          </b-table-column>
          
          <b-table-column field="name" :label="$t('targeting.advanced.commune')" v-slot="props">
            {{ props.row.name }}
          </b-table-column>
          
          <b-table-column field="department_code" :label="$t('targeting.advanced.department')" v-slot="props">
            {{ props.row.department_code }}
          </b-table-column>
          
          <b-table-column field="population" :label="$t('targeting.advanced.population')" numeric v-slot="props">
            {{ formatNumber(props.row.population) }}
          </b-table-column>
        </b-table>
        
        <p v-if="previewResults.subscribers.length > 10" class="has-text-grey">
          {{ $t('targeting.advanced.showingFirst10') }}
        </p>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AdvancedTargeting',

  props: {
    showSqlPreview: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      filter: {
        advanced_filters: {
          operator: 'AND',
          rules: [
            {
              field: 'department',
              operator: 'in',
              value: [],
            },
          ],
        },
      },
      previewResults: null,
      previewing: false,
      applying: false,
      exporting: false,
      sqlPreview: '',
      
      // Field options
      departments: [],
      regions: [],
      loadingOptions: false,
    };
  },

  mounted() {
    this.loadFieldOptions();
  },

  methods: {
    async loadFieldOptions() {
      this.loadingOptions = true;
      try {
        // Load departments
        const deptResponse = await this.$api.getDepartments();
        this.departments = deptResponse.data.map(d => d.code);
        
        // Load regions
        const regionResponse = await this.$api.getRegions();
        this.regions = regionResponse.data.map(r => r.name);
      } catch (e) {
        console.error('Error loading field options:', e);
      } finally {
        this.loadingOptions = false;
      }
    },

    addRule() {
      this.filter.advanced_filters.rules.push({
        field: 'department',
        operator: 'in',
        value: [],
      });
    },

    removeRule(index) {
      if (this.filter.advanced_filters.rules.length > 1) {
        this.filter.advanced_filters.rules.splice(index, 1);
      }
    },

    onFieldChange(rule) {
      // Reset operator and value when field changes
      const operators = this.getAvailableOperators(rule.field);
      rule.operator = operators[0].value;
      rule.value = this.getDefaultValue(rule.field, rule.operator);
    },

    getAvailableOperators(field) {
      const operators = {
        department: [
          { value: 'in', label: this.$t('targeting.operators.in') },
          { value: 'not_in', label: this.$t('targeting.operators.notIn') },
          { value: 'eq', label: this.$t('targeting.operators.equals') },
          { value: 'ne', label: this.$t('targeting.operators.notEquals') },
        ],
        population: [
          { value: 'between', label: this.$t('targeting.operators.between') },
          { value: 'gte', label: this.$t('targeting.operators.greaterThanOrEqual') },
          { value: 'lte', label: this.$t('targeting.operators.lessThanOrEqual') },
          { value: 'gt', label: this.$t('targeting.operators.greaterThan') },
          { value: 'lt', label: this.$t('targeting.operators.lessThan') },
          { value: 'eq', label: this.$t('targeting.operators.equals') },
          { value: 'ne', label: this.$t('targeting.operators.notEquals') },
        ],
        region: [
          { value: 'in', label: this.$t('targeting.operators.in') },
          { value: 'not_in', label: this.$t('targeting.operators.notIn') },
          { value: 'eq', label: this.$t('targeting.operators.equals') },
          { value: 'ne', label: this.$t('targeting.operators.notEquals') },
          { value: 'contains', label: this.$t('targeting.operators.contains') },
          { value: 'not_contains', label: this.$t('targeting.operators.notContains') },
        ],
        commune_name: [
          { value: 'contains', label: this.$t('targeting.operators.contains') },
          { value: 'not_contains', label: this.$t('targeting.operators.notContains') },
          { value: 'eq', label: this.$t('targeting.operators.equals') },
          { value: 'ne', label: this.$t('targeting.operators.notEquals') },
          { value: 'in', label: this.$t('targeting.operators.in') },
        ],
        postal_code: [
          { value: 'in', label: this.$t('targeting.operators.in') },
          { value: 'not_in', label: this.$t('targeting.operators.notIn') },
          { value: 'eq', label: this.$t('targeting.operators.equals') },
          { value: 'ne', label: this.$t('targeting.operators.notEquals') },
        ],
      };
      
      return operators[field] || [];
    },

    getDefaultValue(field, operator) {
      if (operator === 'between' && field === 'population') {
        return { min: null, max: null };
      }
      if (['in', 'not_in'].includes(operator)) {
        return [];
      }
      return '';
    },

    isSimpleValue(rule) {
      return !['in', 'not_in', 'between'].includes(rule.operator);
    },

    isArrayValue(rule) {
      return ['in', 'not_in'].includes(rule.operator);
    },

    getInputType(field) {
      return field === 'population' ? 'number' : 'text';
    },

    getPlaceholder(field) {
      const placeholders = {
        department: this.$t('targeting.placeholders.department'),
        population: this.$t('targeting.placeholders.population'),
        region: this.$t('targeting.placeholders.region'),
        commune_name: this.$t('targeting.placeholders.communeName'),
        postal_code: this.$t('targeting.placeholders.postalCode'),
      };
      return placeholders[field] || '';
    },

    getFieldOptions(field) {
      const options = {
        department: this.departments,
        region: this.regions,
        postal_code: [], // Could be loaded dynamically
        commune_name: [], // Could be loaded dynamically
      };
      return options[field] || [];
    },

    async previewTargeting() {
      this.previewing = true;
      try {
        const response = await this.$api.post('/api/geo/targeting/advanced/preview', {
          filter: this.filter,
        });
        this.previewResults = response.data.data;
        
        this.$emit('preview', this.previewResults);
        
        this.$buefy.toast.open({
          message: this.$t('targeting.advanced.previewSuccess', {
            count: this.previewResults.total_count,
          }),
          type: 'is-success',
        });
      } catch (e) {
        console.error('Error previewing targeting:', e);
        this.$buefy.toast.open({
          message: this.$t('targeting.advanced.previewError'),
          type: 'is-danger',
        });
      } finally {
        this.previewing = false;
      }
    },

    async applyTargeting() {
      this.applying = true;
      try {
        const response = await this.$api.post('/api/geo/targeting/advanced', {
          filter: this.filter,
          limit: 1000,
        });
        this.previewResults = response.data.data;
        
        this.$emit('apply', this.previewResults);
        
        this.$buefy.toast.open({
          message: this.$t('targeting.advanced.applySuccess', {
            count: this.previewResults.total_count,
          }),
          type: 'is-success',
        });
      } catch (e) {
        console.error('Error applying targeting:', e);
        this.$buefy.toast.open({
          message: this.$t('targeting.advanced.applyError'),
          type: 'is-danger',
        });
      } finally {
        this.applying = false;
      }
    },

    resetFilter() {
      this.filter = {
        advanced_filters: {
          operator: 'AND',
          rules: [
            {
              field: 'department',
              operator: 'in',
              value: [],
            },
          ],
        },
      };
      this.previewResults = null;
      this.sqlPreview = '';
    },

    async exportResults() {
      if (!this.previewResults || !this.previewResults.subscribers.length) {
        return;
      }

      this.exporting = true;
      try {
        // Create CSV content
        const headers = ['Email', 'Name', 'Commune', 'Department', 'Population'];
        const rows = this.previewResults.subscribers.map(sub => [
          sub.subscriber_email,
          sub.subscriber_name,
          sub.name,
          sub.department_code,
          sub.population,
        ]);

        const csvContent = [headers, ...rows]
          .map(row => row.map(field => `"${field}"`).join(','))
          .join('\n');

        // Download file
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        link.setAttribute('href', url);
        link.setAttribute('download', `targeting-results-${new Date().toISOString().split('T')[0]}.csv`);
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        this.$buefy.toast.open({
          message: this.$t('targeting.advanced.exportSuccess'),
          type: 'is-success',
        });
      } catch (e) {
        console.error('Error exporting results:', e);
        this.$buefy.toast.open({
          message: this.$t('targeting.advanced.exportError'),
          type: 'is-danger',
        });
      } finally {
        this.exporting = false;
      }
    },

    formatNumber(num) {
      return new Intl.NumberFormat().format(num);
    },
  },
};
</script>

<style scoped>
.advanced-targeting {
  margin-bottom: 2rem;
}

.filter-builder {
  margin-top: 1rem;
}

.rules-container {
  margin: 1.5rem 0;
}

.rule-item {
  margin-bottom: 1rem;
  padding: 1rem;
  border-left: 4px solid #3273dc;
}

.rule-item:last-child {
  margin-bottom: 0;
}

pre code {
  background: transparent;
  font-size: 0.875rem;
}

.level {
  margin-bottom: 1.5rem;
}
</style>