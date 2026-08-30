import { createApp } from 'vue'
import App from './App.vue'
import './styles.css'
import { supabaseConfigError } from './lib/supabase'

// If Supabase isn't configured (e.g. env vars not set in Netlify),
// show a plain, readable message instead of leaving a blank white
// page with no clue why. This does not touch any component's design —
// it's a fallback that only ever appears in this one broken state.
if (supabaseConfigError) {
  const root = document.getElementById('app')
  root.innerHTML = `
    <div style="max-width:520px;margin:15vh auto;padding:24px;
      font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
      color:#7a271a;background:#fef3f2;border:1px solid #fecdca;border-radius:12px;">
      <strong>Usanidi wa Supabase haujakamilika</strong>
      <p style="margin:8px 0 0;line-height:1.5;">${supabaseConfigError}</p>
    </div>
  `
} else {
  createApp(App).mount('#app')
}