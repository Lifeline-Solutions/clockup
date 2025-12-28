import { Controller } from '@hotwired/stimulus';

// A lightweight searchable combobox for timezones
// Targets:
// - input: the text input for typing
// - list: the dropdown list container
// - item: individual timezone items (li)
// - hidden: hidden input that carries the selected value to the server
export default class extends Controller {
  static targets = ['input', 'list', 'item', 'hidden']

  connect() {
    this.selected = null;
    this.opened = false;
    // Ensure the list is hidden on load
    this.listTarget.classList.add('hidden');
  }

  filter() {
    const q = this.inputTarget.value.trim().toLowerCase();
    let visibleCount = 0;
    this.itemTargets.forEach((el) => {
      const text = el.textContent.toLowerCase();
      const match = q === '' || text.includes(q);
      el.classList.toggle('hidden', !match);
      // eslint-disable-next-line no-plusplus
      if (match) visibleCount++;
    });
    // Only toggle visibility if list is opened by user
    if (this.opened) {
      this.listTarget.classList.toggle('hidden', visibleCount === 0);
    } else {
      this.listTarget.classList.add('hidden');
    }
  }

  open() {
    this.opened = true;
    this.listTarget.classList.remove('hidden');
    this.filter();
  }

  close() {
    this.opened = false;
    this.listTarget.classList.add('hidden');
  }

  select(event) {
    const { value } = event.currentTarget.dataset;
    const label = event.currentTarget.textContent;
    this.inputTarget.value = label;
    this.hiddenTarget.value = value;
    this.selected = value;
    this.close();
  }

  commit() {
    // If user typed an exact match, set hidden to that value
    const typed = this.inputTarget.value.trim();
    const found = this.itemTargets.find((el) => el.textContent.trim() === typed);
    if (found) {
      this.hiddenTarget.value = found.dataset.value;
      this.selected = found.dataset.value;
    }
    this.close();
  }

  useCurrent() {
    try {
      const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
      if (!tz) return;
      // Try to find an item with this exact IANA value
      const match = this.itemTargets.find((el) => el.dataset.value === tz);
      this.hiddenTarget.value = tz;
      this.inputTarget.value = match ? match.textContent.trim() : tz;
      this.selected = tz;
      this.close();
    } catch (e) {
      // eslint-disable-next-line no-console
      console.warn('Timezone detection failed', e);
    }
  }
}
