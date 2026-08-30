<template>
  <main class="dashboard">

    <!-- =====================================================
         TOP BAR
    ====================================================== -->
    <header class="topbar">

      <div class="brand-area">
        <div class="brand-logo">
          <img :src="logo" alt="Golani SDA Church" />
        </div>

        <div class="brand-text">
          <p class="eyebrow">GOLANI SDA CHURCH</p>
          <h1>Church Members Registration</h1>
          <p class="brand-subtitle">Member information management portal</p>
        </div>
      </div>

      <div class="topbar-actions">
        <div class="admin-info">
          <span class="admin-label">Signed in as</span>
          <span class="admin-email">{{ session.user.email }}</span>
        </div>

        <button class="ghost-button" type="button" @click="$emit('logged-out')">
          Sign out
        </button>
      </div>

    </header>


    <!-- =====================================================
         STATISTICS
    ====================================================== -->
    <section class="stats">

      <div class="stat-card">
        <div class="stat-icon navy-icon"><span>👥</span></div>
        <div>
          <span>Total Members</span>
          <strong>{{ residents.length }}</strong>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon"><span>♂</span></div>
        <div>
          <span>Men</span>
          <strong>{{ menCount }}</strong>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon"><span>♀</span></div>
        <div>
          <span>Women</span>
          <strong>{{ womenCount }}</strong>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon"><span>✓</span></div>
        <div>
          <span>Wamebatizwa</span>
          <strong>{{ baptizedCount }}</strong>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon"><span>🎓</span></div>
        <div>
          <span>TUCASA</span>
          <strong>{{ tucasaCount }}</strong>
        </div>
      </div>

    </section>


    <!-- =====================================================
         REGISTRATION PANEL
    ====================================================== -->
    <section class="panel">

      <div class="panel-heading">
        <div class="section-title">
          <div class="section-title-icon">+</div>
          <div>
            <h2>{{ editing ? 'Edit Church Member' : 'Register Church Member' }}</h2>
            <p>
              {{
                editing
                  ? 'Update the member information below.'
                  : 'Enter the church member information to create a new record.'
              }}
            </p>
          </div>
        </div>

        <div class="panel-actions">
          <button class="secondary-button" type="button" @click="exportExcel" :disabled="!residents.length">
            ↓ &nbsp; Export Excel
          </button>

          <button v-if="editing" class="ghost-button" type="button" @click="resetForm">
            Cancel edit
          </button>
        </div>
      </div>


      <!-- =====================================================
           FORM
      ====================================================== -->
      <form class="resident-form" @submit.prevent="saveResident">

        <!-- ================= SECTION 1: TAARIFA BINAFSI ================= -->
        <div class="form-section">
          <span class="form-section-number">1</span>
          <h3>Taarifa Binafsi</h3>
          <span class="form-section-hint">Lazima</span>
        </div>

        <label>
          <span>Jina kamili <b>*</b></span>
          <input v-model.trim="form.full_name" required placeholder="Andika jina kamili" @blur="upperize(form, 'full_name')" />
        </label>

        <label>
          <span>Jinsia <b>*</b></span>
          <select v-model="form.gender" required>
            <option disabled value="">Chagua jinsia</option>
            <option value="Mwanaume">Mwanaume</option>
            <option value="Mwanamke">Mwanamke</option>
          </select>
        </label>

        <label>
          <span>Tarehe ya kuzaliwa</span>
          <input v-model="form.date_of_birth" type="date" / required>
        </label>

        <label>
          <span>Hali ya ndoa</span>
          <select v-model="form.marital_status" required>
            <option value="">Chagua hali ya ndoa</option>
            <!-- These values match the database CHECK constraint -->
            <option value="Hajaoa/Hajaolewa">Hajaoa/Hajaolewa</option>
            <option value="Ameoa/Ameolewa">Ameoa/Ameolewa</option>
            <option value="Mjane">Mjane</option>
            <option value="Mgane">Mgane</option>
            <option value="Talaka">Talaka</option>
          </select>
        </label>

        <label>
          <span>Namba ya simu</span>
          <input v-model.trim="form.phone_number" type="tel" placeholder="07XXXXXXXX (pia ni namba ya WhatsApp)" />
        </label>

        <label>
          <span>Barua pepe (Email)</span>
          <input v-model.trim="form.email" type="email" placeholder="jina@mfano.com" />
        </label>

        <label class="span-2">
          <span>Anwani/Makazi</span>
          <input v-model.trim="form.residence" placeholder="Mtaa, Kata, Jiji — Mfano: Miono, Msata, Dodoma" @blur="upperize(form, 'residence')" />
        </label>


        <!-- ================= SECTION 2: TAARIFA ZA KIROHO / KANISA ================= -->
        <div class="form-section">
          <span class="form-section-number">2</span>
          <h3>Taarifa za Kiroho / Kanisa</h3>
        </div>

        <label>
          <span>Umebatizwa?</span>
          <select v-model="form.is_baptized">
            <option :value="false">Hapana</option>
            <option :value="true">Ndiyo</option>
          </select>
        </label>

        <div></div>

        <template v-if="form.is_baptized">
          <div class="conditional-panel span-2">
            <label>
              <span>Mwaka wa ubatizo</span>
              <input
                v-model="form.baptism_year"
                type="number"
                min="1900"
                :max="currentYear"
                placeholder="Mfano: 2018"
              />
            </label>

            <label>
              <span>Kanisa ulipobatizwa</span>
              <input v-model.trim="form.baptism_place" placeholder="Mfano: Golani SDA Church" @blur="upperize(form, 'baptism_place')" />
            </label>
              <label>
                <span>Ushirika ulipo</span>
                <input v-model.trim="form.church_area" placeholder="Mfano: Golani SDA" @blur="upperize(form, 'church_area')" />
              </label>
          </div>
        </template>

        <label>
          <span>Idara/Kikundi alichopo</span>
          <input v-model.trim="form.ministry_group" list="ministry-group-options" placeholder="Mfano: Kwaya, Vijana, Dorkas" @blur="upperize(form, 'ministry_group')" />
          <datalist id="ministry-group-options">
            <option value="Kwaya" />
            <option value="Vijana" />
            <option value="Dorkas" />
            <option value="AMO" />
            <option value="Uinjilisti" />
            <option value="Watoto" />
            <option value="Shule Sabato" />
          </datalist>
        </label>

        <label>
          <span>Wadhifa</span>
          <select v-model="form.church_role">
            <option value="">Chagua wadhifa</option>
            <option value="Mshiriki">Mshiriki</option>
            <option value="Kiongozi">Kiongozi</option>
            <option value="Mchungaji">Mchungaji</option>
            <option value="Mzee">Mzee</option>
          </select>
        </label>


        <!-- ================= SECTION 3: TAARIFA ZA FAMILIA ================= -->
        <div class="form-section">
          <span class="form-section-number">3</span>
          <h3>Taarifa za Familia</h3>
          <span v-if="!isMarried" class="form-section-hint">
            Taarifa za mwenzi na watoto zitaonekana akichagua Hali ya Ndoa: Ameoa/Ameolewa
          </span>
        </div>

        <template v-if="isMarried">

          <!-- ---------- Mwenzi: Taarifa Binafsi ---------- -->
          <div class="subsection-label span-2">Taarifa Binafsi za Mwenzi</div>

          <label>
            <span>Jina kamili la Mwenzi</span>
            <input v-model.trim="form.spouse.full_name" placeholder="Jina kamili la mwenzi" @blur="upperize(form.spouse, 'full_name')" />
          </label>

          <label>
            <span>Jinsia ya Mwenzi</span>
            <select v-model="form.spouse.gender" disabled>
              <option value="">Jinsia itawekwa moja kwa moja</option>
              <option value="Mwanaume">Mwanaume</option>
              <option value="Mwanamke">Mwanamke</option>
            </select>
            <small class="field-hint">
              Jinsia ya mwenzi huwekwa moja kwa moja kuwa tofauti na jinsia ya anayejaza taarifa.
            </small>
          </label>

          <label>
            <span>Tarehe ya kuzaliwa (Mwenzi)</span>
            <input v-model="form.spouse.date_of_birth" type="date" />
          </label>

          <label>
            <span>Namba ya simu (Mwenzi)</span>
            <input v-model.trim="form.spouse.phone_number" type="tel" placeholder="07XXXXXXXX" />
          </label>

          <label class="span-2">
            <span>Barua pepe (Mwenzi)</span>
            <input v-model.trim="form.spouse.email" type="email" placeholder="jina@mfano.com" />
          </label>

          <!-- ---------- Mwenzi: Taarifa za Kiroho / Kanisa ---------- -->
          <div class="subsection-label span-2">Taarifa za Kiroho / Kanisa za Mwenzi</div>

          <label>
            <span>Umebatizwa? (Mwenzi)</span>
            <select v-model="form.spouse.is_baptized">
              <option :value="false">Hapana</option>
              <option :value="true">Ndiyo</option>
            </select>
          </label>

          <div></div>

          <template v-if="form.spouse.is_baptized">
            <div class="conditional-panel span-2">
              <label>
                <span>Mwaka wa ubatizo (Mwenzi)</span>
                <input
                  v-model="form.spouse.baptism_year"
                  type="number"
                  min="1900"
                  :max="currentYear"
                  placeholder="Mfano: 2018"
                />
              </label>

              <label>
                <span>Mahali alipobatizwa (Mwenzi)</span>
                <input v-model.trim="form.spouse.baptism_place" placeholder="Mfano: Golani SDA Church" @blur="upperize(form.spouse, 'baptism_place')" />
              </label>
                <label>
                  <span>Ushirika ulipo (Mwenzi)</span>
                  <input v-model.trim="form.spouse.church_area" placeholder="Mfano: Golani SDA" @blur="upperize(form.spouse, 'church_area')" />
                </label>
            </div>
          </template>

          <label>
            <span>Idara/Kikundi (Mwenzi)</span>
            <input v-model.trim="form.spouse.ministry_group" list="ministry-group-options" placeholder="Mfano: Kwaya, Vijana, Dorkas" @blur="upperize(form.spouse, 'ministry_group')" />
          </label>

          <label>
            <span>Wadhifa (Mwenzi)</span>
            <select v-model="form.spouse.church_role">
              <option value="">Chagua wadhifa</option>
              <option value="Mshiriki">Mshiriki</option>
              <option value="Kiongozi">Kiongozi</option>
              <option value="Mchungaji">Mchungaji</option>
              <option value="Mzee">Mzee</option>
            </select>
          </label>

          <label>
            <span>Mahitaji Maalum (Mwenzi)</span>
            <input v-model.trim="form.spouse.special_needs" placeholder="Mfano: Anahitaji msaada maalum" @blur="upperize(form.spouse, 'special_needs')" />
          </label>

          <!-- ---------- Mwenzi: Taarifa za Ziada ---------- -->
          <div class="subsection-label span-2">Taarifa za Ziada za Mwenzi</div>

          <label>
            <span>MwanaTUCASA? (Mwenzi)</span>
            <select v-model="form.spouse.is_tucasa_member">
              <option :value="false">Hapana</option>
              <option :value="true">Ndiyo</option>
            </select>
          </label>

          <label v-if="form.spouse.is_tucasa_member">
            <span>Chuo anachosoma (Mwenzi)</span>
            <input v-model.trim="form.spouse.institution_name" placeholder="Mfano: UDSM, NIT, SUA, MUHAS" @blur="upperize(form.spouse, 'institution_name')" />
          </label>
          <div v-else></div>

          <label>
            <span>Elimu/Kazi (Mwenzi)</span>
            <input v-model.trim="form.spouse.occupation" placeholder="Mfano: Mwalimu, Mfanyabiashara" @blur="upperize(form.spouse, 'occupation')" />
          </label>

          <label>
            <span>Vipaji/Mahususi (Mwenzi)</span>
            <input v-model.trim="form.spouse.skills" placeholder="Mfano: Muziki, Ufundishaji, Upishi" @blur="upperize(form.spouse, 'skills')" />
          </label>

          <!-- ---------- Watoto ---------- -->
          <div class="subsection-label span-2">Watoto</div>

          <label>
            <span>Idadi ya Watoto</span>
            <input v-model="childrenCountModel" type="number" min="0" max="15" />
          </label>

          <div></div>

          <div v-if="form.children.length" class="children-list span-2">
            <div v-for="(child, index) in form.children" :key="index" class="family-member-card">
              <div class="family-member-card-head">
                <span>Mtoto #{{ index + 1 }}</span>
                <button type="button" class="child-remove" title="Ondoa mtoto" @click="removeChild(index)">✕</button>
              </div>
              <div class="family-member-grid">
                <input v-model.trim="child.full_name" placeholder="Jina kamili *" @blur="upperize(child, 'full_name')" />
                <select v-model="child.gender"><option value="">Jinsia</option><option value="Mwanaume">Mwanaume</option><option value="Mwanamke">Mwanamke</option></select>
                <input v-model="child.date_of_birth" type="date" />
                <input v-model.trim="child.phone_number" type="tel" placeholder="Namba ya simu" />
                <input v-model.trim="child.email" type="email" placeholder="Barua pepe" />
                <input v-model.trim="child.residence" placeholder="Anwani/Makazi" @blur="upperize(child, 'residence')" />
                <div class="subsection-label span-2">Taarifa za Kiroho / Kanisa za Mtoto</div>
                <label><span>Amebatizwa?</span><select v-model="child.is_baptized"><option :value="false">Hapana</option><option :value="true">Ndiyo</option></select></label>
                <template v-if="child.is_baptized">
                  <label><span>Mwaka wa ubatizo</span><input v-model="child.baptism_year" type="number" min="1900" :max="currentYear" /></label>
                  <label><span>Kanisa alikobatiziwa</span><input v-model.trim="child.baptism_place" placeholder="Mfano: Golani SDA Church" @blur="upperize(child, 'baptism_place')" /></label>
                  <label><span>Ushirika ulipo</span><input v-model.trim="child.church_area" placeholder="Mfano: Golani SDA" @blur="upperize(child, 'church_area')" /></label>
                </template>
                <label><span>Idara/Kikundi</span><input v-model.trim="child.ministry_group" list="ministry-group-options" @blur="upperize(child, 'ministry_group')" /></label>
                <label><span>Wadhifa</span><select v-model="child.church_role"><option value="">Chagua wadhifa</option><option value="Mshiriki">Mshiriki</option><option value="Kiongozi">Kiongozi</option></select></label>
                <label class="span-2"><span>Mahitaji Maalum</span><input v-model.trim="child.special_needs" placeholder="Mfano: Anahitaji msaada maalum" @blur="upperize(child, 'special_needs')" /></label>

                <div class="subsection-label span-2">Taarifa za Ziada za Mtoto</div>
                <label>
                  <span>MwanaTUCASA?</span>
                  <select v-model="child.is_tucasa_member">
                    <option :value="false">Hapana</option>
                    <option :value="true">Ndiyo</option>
                  </select>
                </label>
                <label v-if="child.is_tucasa_member">
                  <span>Chuo anachosoma</span>
                  <input v-model.trim="child.institution_name" placeholder="Mfano: UDSM, NIT, SUA, MUHAS" @blur="upperize(child, 'institution_name')" />
                </label>
                <div v-else></div>
                <label>
                  <span>Elimu/Kazi</span>
                  <input v-model.trim="child.occupation" placeholder="Mfano: Mwanafunzi, Mwalimu" @blur="upperize(child, 'occupation')" />
                </label>
                <label>
                  <span>Vipaji/Mahususi</span>
                  <input v-model.trim="child.skills" placeholder="Mfano: Muziki, Uchoraji, Michezo" @blur="upperize(child, 'skills')" />
                </label>
              </div>
            </div>
          </div>

        </template>

        <!-- ---------- Wanafamilia Wengine (siyo mtoto) ---------- -->
        <div class="subsection-label span-2">Wanafamilia Wengine (siyo mtoto)</div>

        <div v-if="form.family_members.length" class="family-members-list span-2">
          <div v-for="(member, index) in form.family_members" :key="index" class="family-member-card">
            <div class="family-member-card-head">
              <span>Mwanafamilia #{{ index + 1 }}</span>
              <button type="button" class="child-remove" title="Ondoa mwanafamilia" @click="removeFamilyMember(index)">✕</button>
            </div>
            <div class="family-member-grid">
              <input v-model.trim="member.full_name" placeholder="Jina kamili *" @blur="upperize(member, 'full_name')" />
              <input v-model.trim="member.relationship" list="relationship-options" placeholder="Uhusiano — Mfano: Baba, Kaka" @blur="upperize(member, 'relationship')" />
              <select v-model="member.gender"><option value="">Jinsia</option><option value="Mwanaume">Mwanaume</option><option value="Mwanamke">Mwanamke</option></select>
              <input v-model="member.date_of_birth" type="date" />
              <input v-model.trim="member.phone_number" type="tel" placeholder="Namba ya simu" />
              <input v-model.trim="member.email" type="email" placeholder="Barua pepe" />
              <input v-model.trim="member.residence" placeholder="Anwani/Makazi" @blur="upperize(member, 'residence')" />
              <div class="subsection-label span-2">Taarifa za Kiroho / Kanisa za Mwanafamilia</div>
              <label><span>Amebatizwa?</span><select v-model="member.is_baptized"><option :value="false">Hapana</option><option :value="true">Ndiyo</option></select></label>
              <template v-if="member.is_baptized">
                <label><span>Mwaka wa ubatizo</span><input v-model="member.baptism_year" type="number" min="1900" :max="currentYear" /></label>
                <label><span>Kanisa alikobatiziwa</span><input v-model.trim="member.baptism_place" @blur="upperize(member, 'baptism_place')" /></label>
                <label><span>Ushirika ulipo</span><input v-model.trim="member.church_area" @blur="upperize(member, 'church_area')" /></label>
              </template>
              <label><span>Idara/Kikundi</span><input v-model.trim="member.ministry_group" list="ministry-group-options" @blur="upperize(member, 'ministry_group')" /></label>
              <label><span>Wadhifa</span><select v-model="member.church_role"><option value="">Chagua wadhifa</option><option value="Mshiriki">Mshiriki</option><option value="Kiongozi">Kiongozi</option><option value="Mchungaji">Mchungaji</option><option value="Mzee">Mzee</option></select></label>
              <label class="span-2"><span>Mahitaji Maalum</span><input v-model.trim="member.special_needs" placeholder="Mfano: Anahitaji msaada maalum" @blur="upperize(member, 'special_needs')" /></label>

              <div class="subsection-label span-2">Taarifa za Ziada za Mwanafamilia</div>
              <label>
                <span>MwanaTUCASA?</span>
                <select v-model="member.is_tucasa_member">
                  <option :value="false">Hapana</option>
                  <option :value="true">Ndiyo</option>
                </select>
              </label>
              <label v-if="member.is_tucasa_member">
                <span>Chuo anachosoma</span>
                <input v-model.trim="member.institution_name" placeholder="Mfano: UDSM, NIT, SUA, MUHAS" @blur="upperize(member, 'institution_name')" />
              </label>
              <div v-else></div>
              <label>
                <span>Elimu/Kazi</span>
                <input v-model.trim="member.occupation" placeholder="Mfano: Mwanafunzi, Mwalimu" @blur="upperize(member, 'occupation')" />
              </label>
              <label>
                <span>Vipaji/Mahususi</span>
                <input v-model.trim="member.skills" placeholder="Mfano: Muziki, Uchoraji, Michezo" @blur="upperize(member, 'skills')" />
              </label>
            </div>
          </div>
        </div>

        <button type="button" class="secondary-button span-2 add-family-btn" @click="addFamilyMember">
          + &nbsp; Ongeza Mwanafamilia Mwingine
        </button>

        <datalist id="relationship-options">
          <option value="Baba" />
          <option value="Mama" />
          <option value="Kaka" />
          <option value="Dada" />
          <option value="Babu" />
          <option value="Bibi" />
          <option value="Mjukuu" />
          <option value="Ndugu mwingine" />
        </datalist>


        <label>
          <span>Mtu wa karibu wa kuwasiliana nae ikiwa sipatikani — Jina</span>
          <input v-model.trim="form.emergency_contact_name" placeholder="Jina la mtu wa dharura" @blur="upperize(form, 'emergency_contact_name')" />
        </label>

        <label>
          <span>Namba ya dharura</span>
          <input v-model.trim="form.emergency_contact_phone" type="tel" placeholder="07XXXXXXXX" />
        </label>


        <!-- ================= SECTION 4: TAARIFA ZA ZIADA ================= -->
        <div class="form-section">
          <span class="form-section-number">4</span>
          <h3>Taarifa za Ziada</h3>
        </div>

        <label>
          <span>MwanaTUCASA?</span>
          <select v-model="form.is_tucasa_member">
            <option :value="false">Hapana</option>
            <option :value="true">Ndiyo</option>
          </select>
        </label>

        <label v-if="form.is_tucasa_member">
          <span>Chuo anachosoma</span>
          <input v-model.trim="form.institution_name" placeholder="Mfano: UDSM, NIT, SUA, MUHAS" @blur="upperize(form, 'institution_name')" />
        </label>
        <div v-else></div>

        <label>
          <span>Elimu/Kazi</span>
          <input v-model.trim="form.occupation" placeholder="Mfano: Mwalimu" @blur="upperize(form, 'occupation')" />
        </label>

        <label>
          <span>Vipaji/Mahususi</span>
          <input v-model.trim="form.skills" placeholder="Mfano: Upigaji piano, Ufundishaji, Upishi" @blur="upperize(form, 'skills')" />
        </label>

        <label class="span-2">
          <span>Mahitaji Maalum</span>
          <input v-model.trim="form.special_needs" placeholder="Mfano: Mgonjwa, Mlemavu, Anahitaji msaada" @blur="upperize(form, 'special_needs')" />
        </label>


        <!-- Automatic registration information -->
        <div class="automatic-info">
          <div class="automatic-icon">✓</div>
          <div>
            <strong>Registration information</strong>
            <p>Registered by the currently signed-in admin. Registration date is recorded automatically.</p>
          </div>
        </div>


        <!-- Form Actions -->
        <div class="form-actions">
          <button class="primary-button" type="submit" :disabled="saving">
            <span v-if="!saving">{{ editing ? '✓' : '+' }}</span>
            {{ saving ? 'Saving…' : editing ? 'Update Member' : 'Register Member' }}
          </button>

          <button type="button" class="ghost-button" @click="resetForm">Clear</button>
        </div>


        <p v-if="message" class="success">✓ {{ message }}</p>
        <p v-if="error" class="error">{{ error }}</p>

      </form>

    </section>


    <!-- =====================================================
         MEMBERS TABLE
    ====================================================== -->
    <section class="panel">

      <div class="panel-heading">
        <div class="section-title">
          <div class="section-title-icon people-icon">≡</div>
          <div>
            <h2>Church Members</h2>
            <p>Search, edit or remove registered member records.</p>
          </div>
        </div>

        <div class="search-wrapper">
          <span class="search-icon">⌕</span>
          <input v-model.trim="search" class="search-input" placeholder="Search name, phone, email, idara…" />
        </div>
      </div>

      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Jina</th>
              <th>Jinsia</th>
              <th>Umri</th>
              <th>Simu</th>
              <th>Idara / Wadhifa</th>
              <th>TUCASA</th>
              <th>Batizwa</th>
              <th>Ndoa</th>
              <th>Usajili</th>
              <th>Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr v-for="resident in filteredResidents" :key="resident.id">

              <td><strong>{{ resident.full_name }}</strong></td>
              <td>{{ resident.gender }}</td>
              <td>{{ calculateAge(resident.date_of_birth) }}</td>
              <td>{{ resident.phone_number || '—' }}</td>

              <td>
                {{ resident.ministry_group || '—' }}
                <span v-if="resident.church_role"> · {{ resident.church_role }}</span>
              </td>

              <td>
                <span :class="['status-badge', resident.is_tucasa_member ? 'status-yes' : 'status-no']">
                  {{ resident.is_tucasa_member ? 'Ndiyo' : 'Hapana' }}
                </span>
              </td>

              <td>
                <span :class="['status-badge', resident.is_baptized ? 'status-yes' : 'status-no']">
                  {{ resident.is_baptized ? 'Ndiyo' : 'Hapana' }}
                </span>
              </td>

              <td>{{ resident.marital_status || '—' }}</td>
              <td>{{ formatDate(resident.created_at) }}</td>

              <td class="actions">
                <button class="small-button" type="button" @click="detailResident = resident">View</button>
                <button class="small-button" type="button" @click="startEdit(resident)">Edit</button>
                <button class="small-button danger" type="button" @click="deleteResident(resident)">Delete</button>
              </td>

            </tr>

            <tr v-if="!filteredResidents.length">
              <td colspan="10" class="empty">
                <div class="empty-state">
                  <div class="empty-icon">≡</div>
                  <strong>No members found</strong>
                  <span>Try another search or register a new church member.</span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

    </section>


    <!-- =====================================================
         MEMBER DETAILS MODAL
    ====================================================== -->
    <div v-if="detailResident" class="modal-overlay" @click.self="detailResident = null">
      <div class="modal-card">

        <div class="modal-head">
          <div>
            <h2>{{ detailResident.full_name }}</h2>
            <p>Alisajiliwa {{ formatDate(detailResident.created_at) }}</p>
          </div>
          <button class="ghost-button" type="button" @click="detailResident = null">Close</button>
        </div>

        <div class="detail-section">
          <h4>1. Taarifa Binafsi</h4>
          <div class="detail-grid">
            <div><span>Jinsia</span><strong>{{ detailResident.gender }}</strong></div>
            <div><span>Umri</span><strong>{{ calculateAge(detailResident.date_of_birth) }}</strong></div>
            <div><span>Tarehe ya kuzaliwa</span><strong>{{ formatDate(detailResident.date_of_birth) }}</strong></div>
            <div><span>Hali ya ndoa</span><strong>{{ detailResident.marital_status || '—' }}</strong></div>
            <div><span>Namba ya simu</span><strong>{{ detailResident.phone_number || '—' }}</strong></div>
            <div><span>Barua pepe</span><strong>{{ detailResident.email || '—' }}</strong></div>
            <div class="span-2"><span>Anwani/Makazi</span><strong>{{ detailResident.residence || '—' }}</strong></div>
          </div>
        </div>

        <div class="detail-section">
          <h4>2. Taarifa za Kiroho / Kanisa</h4>
          <div class="detail-grid">
            <div><span>Amebatizwa</span><strong>{{ detailResident.is_baptized ? 'Ndiyo' : 'Hapana' }}</strong></div>
            <template v-if="detailResident.is_baptized">
              <div><span>Mwaka wa ubatizo</span><strong>{{ detailResident.baptism_year || '—' }}</strong></div>
              <div><span>Kanisa ulipobatizwa</span><strong>{{ detailResident.baptism_place || '—' }}</strong></div>
            </template>
            <div><span>Ushirika ulipo</span><strong>{{ detailResident.church_area || '—' }}</strong></div>
            <div><span>Idara/Kikundi</span><strong>{{ detailResident.ministry_group || '—' }}</strong></div>
            <div><span>Wadhifa</span><strong>{{ detailResident.church_role || '—' }}</strong></div>
          </div>
        </div>

        <div v-if="detailResident.marital_status === 'Ameoa/Ameolewa' && detailResident.spouse" class="detail-section">
          <h4>3a. Taarifa za Mwenzi</h4>
          <div class="detail-grid">
            <div><span>Jina kamili</span><strong>{{ detailResident.spouse.full_name || '—' }}</strong></div>
            <div><span>Jinsia</span><strong>{{ detailResident.spouse.gender || '—' }}</strong></div>
            <div><span>Tarehe ya kuzaliwa</span><strong>{{ formatDate(detailResident.spouse.date_of_birth) }}</strong></div>
            <div><span>Namba ya simu</span><strong>{{ detailResident.spouse.phone_number || '—' }}</strong></div>
            <div><span>Barua pepe</span><strong>{{ detailResident.spouse.email || '—' }}</strong></div>
            <div><span>Amebatizwa</span><strong>{{ detailResident.spouse.is_baptized ? 'Ndiyo' : 'Hapana' }}</strong></div>
            <template v-if="detailResident.spouse.is_baptized">
              <div><span>Mwaka wa ubatizo</span><strong>{{ detailResident.spouse.baptism_year || '—' }}</strong></div>
              <div><span>Mahali alipobatizwa</span><strong>{{ detailResident.spouse.baptism_place || '—' }}</strong></div>
            </template>
            <div><span>Ushirika ulipo</span><strong>{{ detailResident.spouse.church_area || '—' }}</strong></div>
            <div><span>Idara/Kikundi</span><strong>{{ detailResident.spouse.ministry_group || '—' }}</strong></div>
            <div><span>Wadhifa</span><strong>{{ detailResident.spouse.church_role || '—' }}</strong></div>
            <div class="span-2"><span>Mahitaji Maalum</span><strong>{{ detailResident.spouse.special_needs || '—' }}</strong></div>

            <div class="span-2 detail-subheading">Taarifa za Ziada za Mwenzi</div>
            <div><span>MwanaTUCASA</span><strong>{{ detailResident.spouse.is_tucasa_member ? 'Ndiyo' : 'Hapana' }}</strong></div>
            <div v-if="detailResident.spouse.is_tucasa_member"><span>Chuo</span><strong>{{ detailResident.spouse.institution_name || '—' }}</strong></div>
            <div><span>Elimu/Kazi</span><strong>{{ detailResident.spouse.occupation || '—' }}</strong></div>
            <div><span>Vipaji/Mahususi</span><strong>{{ detailResident.spouse.skills || '—' }}</strong></div>
          </div>
        </div>

        <div v-if="detailResident.marital_status === 'Ameoa/Ameolewa'" class="detail-section">
          <h4>3b. Watoto</h4>
          <div v-if="(detailResident.children || []).length" class="children-details">
            <div v-for="(child, idx) in detailResident.children" :key="idx" class="family-detail-card">
              <strong>Mtoto #{{ idx + 1 }} — {{ child.full_name || child.name || '—' }}</strong>
              <div class="detail-grid">
                <div><span>Jinsia</span><strong>{{ child.gender || '—' }}</strong></div>
                <div><span>Umri</span><strong>{{ child.date_of_birth ? calculateAge(child.date_of_birth) : (child.age !== undefined && child.age !== null ? child.age + ' yrs' : '—') }}</strong></div>
                <div><span>Tarehe ya kuzaliwa</span><strong>{{ formatDate(child.date_of_birth) }}</strong></div>
                <div><span>Simu</span><strong>{{ child.phone_number || '—' }}</strong></div>
                <div><span>Email</span><strong>{{ child.email || '—' }}</strong></div>
                <div><span>Anwani/Makazi</span><strong>{{ child.residence || '—' }}</strong></div>
                <div><span>Amebatizwa</span><strong>{{ child.is_baptized ? 'Ndiyo' : 'Hapana' }}</strong></div>
                <template v-if="child.is_baptized">
                  <div><span>Mwaka wa ubatizo</span><strong>{{ child.baptism_year || '—' }}</strong></div>
                  <div><span>Kanisa alikobatiziwa</span><strong>{{ child.baptism_place || '—' }}</strong></div>
                  <div><span>Ushirika ulipo</span><strong>{{ child.church_area || '—' }}</strong></div>
                </template>
                <div><span>Idara/Kikundi</span><strong>{{ child.ministry_group || '—' }}</strong></div>
                <div><span>Wadhifa</span><strong>{{ child.church_role || '—' }}</strong></div>
                <div class="span-2"><span>Mahitaji Maalum</span><strong>{{ child.special_needs || '—' }}</strong></div>

                <div class="span-2 detail-subheading">Taarifa za Ziada za Mtoto</div>
                <div><span>MwanaTUCASA</span><strong>{{ child.is_tucasa_member ? 'Ndiyo' : 'Hapana' }}</strong></div>
                <div v-if="child.is_tucasa_member"><span>Chuo</span><strong>{{ child.institution_name || '—' }}</strong></div>
                <div><span>Elimu/Kazi</span><strong>{{ child.occupation || '—' }}</strong></div>
                <div><span>Vipaji/Mahususi</span><strong>{{ child.skills || '—' }}</strong></div>
              </div>
            </div>
          </div>
          <div v-else class="detail-grid">
            <div class="span-2"><span>Watoto</span><strong>—</strong></div>
          </div>
        </div>

        <div v-if="(detailResident.family_members || []).length" class="detail-section">
          <h4>3c. Wanafamilia Wengine</h4>
          <div class="family-details-list">
            <div v-for="(member, idx) in detailResident.family_members" :key="idx" class="family-detail-card">
              <strong>{{ member.relationship || 'Mwanafamilia' }} — {{ member.full_name || '—' }}</strong>
              <div class="detail-grid">
                <div><span>Jinsia</span><strong>{{ member.gender || '—' }}</strong></div>
                <div><span>Tarehe ya kuzaliwa</span><strong>{{ formatDate(member.date_of_birth) }}</strong></div>
                <div><span>Simu</span><strong>{{ member.phone_number || '—' }}</strong></div>
                <div><span>Email</span><strong>{{ member.email || '—' }}</strong></div>
                <div class="span-2"><span>Anwani/Makazi</span><strong>{{ member.residence || '—' }}</strong></div>
                <div><span>Amebatizwa</span><strong>{{ member.is_baptized ? 'Ndiyo' : 'Hapana' }}</strong></div>
                <template v-if="member.is_baptized">
                  <div><span>Mwaka wa ubatizo</span><strong>{{ member.baptism_year || '—' }}</strong></div>
                  <div><span>Kanisa alikobatiziwa</span><strong>{{ member.baptism_place || '—' }}</strong></div>
                  <div><span>Ushirika ulipo</span><strong>{{ member.church_area || '—' }}</strong></div>
                </template>
                <div><span>Idara/Kikundi</span><strong>{{ member.ministry_group || '—' }}</strong></div>
                <div><span>Wadhifa</span><strong>{{ member.church_role || '—' }}</strong></div>
                <div class="span-2"><span>Mahitaji Maalum</span><strong>{{ member.special_needs || '—' }}</strong></div>

                <div class="span-2 detail-subheading">Taarifa za Ziada za Mwanafamilia</div>
                <div><span>MwanaTUCASA</span><strong>{{ member.is_tucasa_member ? 'Ndiyo' : 'Hapana' }}</strong></div>
                <div v-if="member.is_tucasa_member"><span>Chuo</span><strong>{{ member.institution_name || '—' }}</strong></div>
                <div><span>Elimu/Kazi</span><strong>{{ member.occupation || '—' }}</strong></div>
                <div><span>Vipaji/Mahususi</span><strong>{{ member.skills || '—' }}</strong></div>
              </div>
            </div>
          </div>
        </div>

        <div class="detail-section">
          <h4>Mtu wa karibu wa kuwasiliana nae ikiwa sipatikani</h4>
          <div class="detail-grid">
            <div><span>Jina</span><strong>{{ detailResident.emergency_contact_name || '—' }}</strong></div>
            <div><span>Namba</span><strong>{{ detailResident.emergency_contact_phone || '—' }}</strong></div>
          </div>
        </div>

        <div class="detail-section">
          <h4>4. Taarifa za Ziada</h4>
          <div class="detail-grid">
            <div><span>MwanaTUCASA</span><strong>{{ detailResident.is_tucasa_member ? 'Ndiyo' : 'Hapana' }}</strong></div>
            <div v-if="detailResident.is_tucasa_member"><span>Chuo</span><strong>{{ detailResident.institution_name || '—' }}</strong></div>
            <div><span>Elimu/Kazi</span><strong>{{ detailResident.occupation || '—' }}</strong></div>
            <div><span>Vipaji/Mahususi</span><strong>{{ detailResident.skills || '—' }}</strong></div>
            <div class="span-2"><span>Mahitaji Maalum</span><strong>{{ detailResident.special_needs || '—' }}</strong></div>
          </div>
        </div>

      </div>
    </div>

  </main>
</template>


<script setup>

import {
  computed,
  onMounted,
  reactive,
  ref,
  watch,
} from 'vue'

import * as XLSX from 'xlsx'
import { supabase } from '../lib/supabase'
import logo from '../assets/logo.png'

const props = defineProps({
  session: {
    type: Object,
    required: true,
  },
})

defineEmits(['logged-out'])

const residents = ref([])
const search = ref('')
const saving = ref(false)
const editing = ref(null)
const error = ref('')
const message = ref('')
const detailResident = ref(null)

const currentYear = new Date().getFullYear()

function toUpper(value) {
  return typeof value === 'string' && value ? value.toUpperCase() : value
}

function upperize(target, key) {
  if (typeof target[key] === 'string' && target[key]) {
    target[key] = target[key].toUpperCase()
  }
}

const emptyForm = () => ({
  full_name: '',
  gender: '',
  date_of_birth: '',
  marital_status: '',
  phone_number: '',
  email: '',
  residence: '',

  is_baptized: false,
  baptism_year: '',
  baptism_place: '',
  church_area: '',
  ministry_group: '',
  church_role: '',

  spouse: {
    full_name: '',
    gender: '',
    date_of_birth: '',
    phone_number: '',
    email: '',
    is_baptized: false,
    baptism_year: '',
    baptism_place: '',
    church_area: '',
    ministry_group: '',
    church_role: '',
    special_needs: '',
    is_tucasa_member: false,
    institution_name: '',
    occupation: '',
    skills: '',
  },

  children: [],
  family_members: [],
  emergency_contact_name: '',
  emergency_contact_phone: '',

  is_tucasa_member: false,
  institution_name: '',
  occupation: '',
  skills: '',
  special_needs: '',
})

const form = reactive(emptyForm())

const isMarried = computed(() => form.marital_status === 'Ameoa/Ameolewa')

function getOppositeGender(gender) {
  if (gender === 'Mwanaume') return 'Mwanamke'
  if (gender === 'Mwanamke') return 'Mwanaume'
  return ''
}

function syncSpouseGender() {
  form.spouse.gender = isMarried.value
    ? getOppositeGender(form.gender)
    : ''
}

watch(
  [() => form.gender, () => form.marital_status],
  syncSpouseGender,
  { immediate: true },
)

/* =========================================================
   IDENTITY / DUPLICATE HELPERS
   ========================================================= */

function normalizeValue(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ')
}

function normalizePhone(value) {
  return String(value || '').replace(/\D/g, '')
}

function isSamePerson(a, b) {
  const nameA = normalizeValue(a.full_name)
  const nameB = normalizeValue(b.full_name)
  const phoneA = normalizePhone(a.phone_number)
  const phoneB = normalizePhone(b.phone_number)
  const emailA = normalizeValue(a.email)
  const emailB = normalizeValue(b.email)

  if (nameA && nameA === nameB) return true
  if (phoneA && phoneB && phoneA === phoneB) return true
  if (emailA && emailB && emailA === emailB) return true

  const dobA = String(a.date_of_birth || '').trim()
  const dobB = String(b.date_of_birth || '').trim()

  return !!(
    nameA && dobA &&
    nameB && dobB &&
    nameA === nameB && dobA === dobB
  )
}

async function findDuplicateMember(payload, excludeId = null) {
  const { data, error: duplicateQueryError } = await supabase
    .from('residents')
    .select('*')

  if (duplicateQueryError) {
    throw new Error(`Imeshindikana kuthibitisha duplicate: ${duplicateQueryError.message}`)
  }

  return (data || []).find((resident) => {
    if (excludeId && resident.id === excludeId) return false
    return isSamePerson(payload, resident)
  }) || null
}

/* =========================================================
   FAMILY HELPERS

   IMPORTANT:
   Every spouse/child/family member is now also stored as a REAL
   row in residents. The parent keeps the family structure in its
   spouse/children/family_members JSON fields, while each person
   also appears independently in Church Members.
   ========================================================= */

function familyPersonMatchScore(a, b) {
  if (!a || !b) return 0

  const nameA = normalizeValue(a.full_name)
  const nameB = normalizeValue(b.full_name)
  if (!nameA || !nameB || nameA !== nameB) return 0

  const phoneA = normalizePhone(a.phone_number)
  const phoneB = normalizePhone(b.phone_number)
  const emailA = normalizeValue(a.email)
  const emailB = normalizeValue(b.email)
  const dobA = String(a.date_of_birth || '').trim()
  const dobB = String(b.date_of_birth || '').trim()

  let score = 10

  if (phoneA && phoneB) {
    if (phoneA !== phoneB) return 0
    score += 30
  }

  if (emailA && emailB) {
    if (emailA !== emailB) return 0
    score += 30
  }

  if (dobA && dobB) {
    if (dobA !== dobB) return 0
    score += 20
  }

  return score
}

function findNestedFamilyPlaceholder(person, excludeId = null) {
  const matches = []

  for (const resident of residents.value) {
    if (excludeId && resident.id === excludeId) continue

    if (resident.spouse && typeof resident.spouse === 'object') {
      const score = familyPersonMatchScore(person, resident.spouse)
      if (score > 0) {
        matches.push({
          parent: resident,
          type: 'spouse',
          index: null,
          person: resident.spouse,
          score,
        })
      }
    }

    if (Array.isArray(resident.children)) {
      resident.children.forEach((child, index) => {
        const score = familyPersonMatchScore(person, child)
        if (score > 0) {
          matches.push({
            parent: resident,
            type: 'child',
            index,
            person: child,
            score,
          })
        }
      })
    }

    if (Array.isArray(resident.family_members)) {
      resident.family_members.forEach((member, index) => {
        const score = familyPersonMatchScore(person, member)
        if (score > 0) {
          matches.push({
            parent: resident,
            type: 'family_member',
            index,
            person: member,
            score,
          })
        }
      })
    }
  }

  if (!matches.length) return null

  matches.sort((a, b) => b.score - a.score)
  return matches[0]
}

function cleanChild(child, residentId = null) {
  const baptized = !!child.is_baptized

  return {
    full_name: toUpper((child.full_name || child.name || '').trim()),
    gender: child.gender || null,
    date_of_birth: child.date_of_birth || null,
    phone_number: (child.phone_number || '').trim() || null,
    email: (child.email || '').trim() || null,
    residence: toUpper((child.residence || '').trim()) || null,
    is_baptized: baptized,
    baptism_year: baptized && child.baptism_year ? Number(child.baptism_year) : null,
    baptism_place: baptized ? (toUpper((child.baptism_place || '').trim()) || null) : null,
    church_area: baptized ? (toUpper((child.church_area || '').trim()) || null) : null,
    ministry_group: toUpper((child.ministry_group || '').trim()) || null,
    church_role: (child.church_role || '').trim() || null,
    special_needs: toUpper((child.special_needs || '').trim()) || null,
    is_tucasa_member: !!child.is_tucasa_member,
    institution_name: child.is_tucasa_member
      ? (toUpper((child.institution_name || '').trim()) || null)
      : null,
    occupation: toUpper((child.occupation || '').trim()) || null,
    skills: toUpper((child.skills || '').trim()) || null,
    ...(residentId ? { resident_id: residentId } : {}),
  }
}

function cleanSpouse(spouse, married, residentId = null) {
  if (!married || !spouse?.full_name) return null

  const baptized = !!spouse.is_baptized
  const spouseGender = getOppositeGender(form.gender)

  return {
    full_name: toUpper((spouse.full_name || '').trim()),
    gender: spouseGender || null,
    date_of_birth: spouse.date_of_birth || null,
    phone_number: (spouse.phone_number || '').trim() || null,
    email: (spouse.email || '').trim() || null,
    is_baptized: baptized,
    baptism_year: baptized && spouse.baptism_year ? Number(spouse.baptism_year) : null,
    baptism_place: baptized ? (toUpper((spouse.baptism_place || '').trim()) || null) : null,
    church_area: baptized ? (toUpper((spouse.church_area || '').trim()) || null) : null,
    ministry_group: toUpper((spouse.ministry_group || '').trim()) || null,
    church_role: spouse.church_role || null,
    special_needs: toUpper((spouse.special_needs || '').trim()) || null,
    is_tucasa_member: !!spouse.is_tucasa_member,
    institution_name: spouse.is_tucasa_member
      ? (toUpper((spouse.institution_name || '').trim()) || null)
      : null,
    occupation: toUpper((spouse.occupation || '').trim()) || null,
    skills: toUpper((spouse.skills || '').trim()) || null,
    ...(residentId ? { resident_id: residentId } : {}),
  }
}

function cleanFamilyMembers(members) {
  return (members || [])
    .map((member) => {
      const baptized = !!member.is_baptized

      return {
        full_name: toUpper((member.full_name || '').trim()),
        relationship: toUpper((member.relationship || '').trim()) || null,
        gender: member.gender || null,
        date_of_birth: member.date_of_birth || null,
        phone_number: (member.phone_number || '').trim() || null,
        email: (member.email || '').trim() || null,
        residence: toUpper((member.residence || '').trim()) || null,
        is_baptized: baptized,
        baptism_year: baptized && member.baptism_year ? Number(member.baptism_year) : null,
        baptism_place: baptized ? (toUpper((member.baptism_place || '').trim()) || null) : null,
        church_area: baptized ? (toUpper((member.church_area || '').trim()) || null) : null,
        ministry_group: toUpper((member.ministry_group || '').trim()) || null,
        church_role: (member.church_role || '').trim() || null,
        special_needs: toUpper((member.special_needs || '').trim()) || null,
        is_tucasa_member: !!member.is_tucasa_member,
        institution_name: member.is_tucasa_member
          ? (toUpper((member.institution_name || '').trim()) || null)
          : null,
        occupation: toUpper((member.occupation || '').trim()) || null,
        skills: toUpper((member.skills || '').trim()) || null,
      }
    })
    .filter((member) => member.full_name)
}

function familyRoleLabel(type) {
  if (type === 'spouse') return 'SPOUSE'
  if (type === 'child') return 'CHILD'
  return 'MEMBER'
}

function familyPersonPayload(person, type, parentId, registeredBy) {
  const role = familyRoleLabel(type)
  const base = type === 'child'
    ? cleanChild(person)
    : type === 'spouse'
      ? cleanSpouse(person, true)
      : cleanFamilyMembers([person])[0]

  if (!base?.full_name) return null

  return {
    ...base,
    marital_status: type === 'spouse' ? 'Ameoa/Ameolewa' : null,
    registered_by: registeredBy,
  }
}

/*
 * Save one family person as a REAL residents row.
 * If the person already exists, reuse that row instead of creating
 * a duplicate. This is what makes the person appear in the list.
 */
async function ensureFamilyResident(person, type, parentId, registeredBy) {
  if (!person?.full_name) return null

  const payload = familyPersonPayload(person, type, parentId, registeredBy)
  if (!payload) return null

  const existing = await findDuplicateMember(payload, parentId)

  if (existing) {
    return existing
  }

  const { data, error: insertError } = await supabase
    .from('residents')
    .insert(payload)
    .select('*')
    .single()

  if (insertError) {
    throw new Error(`Imeshindikana kuongeza ${payload.full_name} kwenye Church Members: ${insertError.message}`)
  }

  return data
}

/*
 * Keep the family JSON on the parent connected to the actual resident id.
 */
async function updateParentFamilyLinks(parentId, spouse, children, familyMembers) {
  const updatePayload = {
    spouse: spouse || null,
    children: children || [],
    family_members: familyMembers || [],
  }

  const { error: updateError } = await supabase
    .from('residents')
    .update(updatePayload)
    .eq('id', parentId)

  if (updateError) {
    throw new Error(`Mshikamano wa taarifa za familia umeshindikana: ${updateError.message}`)
  }
}

/*
 * Sync all people entered under the main member into the residents list.
 */
async function syncFamilyResidents(parentId, payload, registeredBy) {
  let spouse = payload.spouse
  const children = []
  const familyMembers = []
  let addedCount = 0

  if (spouse?.full_name) {
    const spouseResident = await ensureFamilyResident(
      spouse,
      'spouse',
      parentId,
      registeredBy,
    )

    if (spouseResident) {
      spouse = cleanSpouse(spouse, true, spouseResident.id)
      addedCount++
    }
  } else {
    spouse = null
  }

  for (const child of payload.children || []) {
    if (!child.full_name) continue

    const childResident = await ensureFamilyResident(
      child,
      'child',
      parentId,
      registeredBy,
    )

    if (childResident) {
      children.push(cleanChild(child, childResident.id))
      addedCount++
    }
  }

  for (const member of payload.family_members || []) {
    if (!member.full_name) continue

    const memberResident = await ensureFamilyResident(
      member,
      'family_member',
      parentId,
      registeredBy,
    )

    if (memberResident) {
      const cleaned = cleanFamilyMembers([member])[0]
      familyMembers.push({
        ...cleaned,
        resident_id: memberResident.id,
      })
      addedCount++
    }
  }

  await updateParentFamilyLinks(parentId, spouse, children, familyMembers)

  return {
    spouse,
    children,
    familyMembers,
    addedCount,
  }
}

/* =========================================================
   IF A FAMILY PERSON ALREADY EXISTS AS A NESTED RECORD
   AND LATER REGISTERS PERSONALLY, UPDATE THAT SAME ROW.
   ========================================================= */

async function connectPersonalRegistrationToFamily(payload, existingResident) {
  const nested = findNestedFamilyPlaceholder(payload, existingResident?.id)
  if (!nested) return false

  const updatePayload = {
    ...payload,
  }

  const { data, error: updateError } = await supabase
    .from('residents')
    .update(updatePayload)
    .eq('id', existingResident.id)
    .select('*')
    .single()

  if (updateError) {
    throw new Error(`Taarifa za mshiriki wa familia hazikuweza kusasishwa: ${updateError.message}`)
  }

  await updateNestedFamilyPlaceholder(nested, data)
  return true
}

async function updateNestedFamilyPlaceholder(match, personalResident) {
  if (!match?.parent?.id || !personalResident?.id) return false

  const linked = {
    full_name: toUpper((personalResident.full_name || '').trim()),
    gender: personalResident.gender || null,
    date_of_birth: personalResident.date_of_birth || null,
    phone_number: personalResident.phone_number || null,
    email: personalResident.email || null,
    residence: toUpper((personalResident.residence || '').trim()) || null,
    is_baptized: !!personalResident.is_baptized,
    baptism_year: personalResident.baptism_year || null,
    baptism_place: personalResident.baptism_place || null,
    church_area: personalResident.church_area || null,
    ministry_group: personalResident.ministry_group || null,
    church_role: personalResident.church_role || null,
    special_needs: personalResident.special_needs || null,
    is_tucasa_member: !!personalResident.is_tucasa_member,
    institution_name: personalResident.institution_name || null,
    occupation: personalResident.occupation || null,
    skills: personalResident.skills || null,
    resident_id: personalResident.id,
  }

  if (match.type === 'family_member') {
    linked.relationship = match.person.relationship || null
  }

  const updatePayload = {}

  if (match.type === 'spouse') {
    updatePayload.spouse = linked
  }

  if (match.type === 'child') {
    const children = Array.isArray(match.parent.children)
      ? [...match.parent.children]
      : []
    children[match.index] = linked
    updatePayload.children = children
  }

  if (match.type === 'family_member') {
    const members = Array.isArray(match.parent.family_members)
      ? [...match.parent.family_members]
      : []
    members[match.index] = linked
    updatePayload.family_members = members
  }

  const { error: updateError } = await supabase
    .from('residents')
    .update(updatePayload)
    .eq('id', match.parent.id)

  if (updateError) {
    throw new Error(updateError.message)
  }

  return true
}

const childrenCountModel = computed({
  get: () => form.children.length,
  set: (value) => {
    const next = Math.max(0, Math.min(15, Number(value) || 0))

    if (next > form.children.length) {
      for (let i = form.children.length; i < next; i++) {
        form.children.push({
          full_name: '',
          gender: '',
          date_of_birth: '',
          phone_number: '',
          email: '',
          residence: '',
          is_baptized: false,
          baptism_year: '',
          baptism_place: '',
          church_area: '',
          ministry_group: '',
          church_role: '',
          special_needs: '',
          is_tucasa_member: false,
          institution_name: '',
          occupation: '',
          skills: '',
        })
      }
    } else {
      form.children.splice(next)
    }
  },
})

function removeChild(index) {
  form.children.splice(index, 1)
}

function addFamilyMember() {
  form.family_members.push({
    full_name: '',
    relationship: '',
    gender: '',
    date_of_birth: '',
    phone_number: '',
    email: '',
    residence: '',
    is_baptized: false,
    baptism_year: '',
    baptism_place: '',
    church_area: '',
    ministry_group: '',
    church_role: '',
    special_needs: '',
    is_tucasa_member: false,
    institution_name: '',
    occupation: '',
    skills: '',
  })
}

function removeFamilyMember(index) {
  form.family_members.splice(index, 1)
}

/* =========================================================
   FILTER / STATISTICS
   ========================================================= */

const filteredResidents = computed(() => {
  const q = search.value.trim().toLowerCase()

  if (!q) return residents.value

  return residents.value.filter((resident) => {
    const values = [
      resident.full_name,
      resident.gender,
      resident.phone_number,
      resident.email,
      resident.residence,
      resident.church_area,
      resident.ministry_group,
      resident.church_role,
      resident.marital_status,
      resident.occupation,
      resident.institution_name,
    ]

    return values
      .filter(Boolean)
      .some((value) => String(value).toLowerCase().includes(q))
  })
})

const menCount = computed(() =>
  residents.value.filter(resident => resident.gender === 'Mwanaume').length,
)

const womenCount = computed(() =>
  residents.value.filter(resident => resident.gender === 'Mwanamke').length,
)

const baptizedCount = computed(() =>
  residents.value.filter(resident => resident.is_baptized).length,
)

const tucasaCount = computed(() =>
  residents.value.filter(resident => resident.is_tucasa_member).length,
)

/* =========================================================
   LOAD MEMBERS
   ========================================================= */

onMounted(loadResidents)

async function loadResidents() {
  error.value = ''

  const { data, error: queryError } = await supabase
    .from('residents')
    .select('*')
    .order('created_at', { ascending: false })

  if (queryError) {
    error.value = queryError.message
    return
  }

  residents.value = data || []
}

/* =========================================================
   SAVE MEMBER
   ========================================================= */

async function saveResident() {
  error.value = ''
  message.value = ''
  saving.value = true

  try {
    const married = isMarried.value
    const baptized = !!form.is_baptized
    const student = !!form.is_tucasa_member

    const payload = {
      full_name: toUpper(form.full_name.trim()),
      gender: form.gender,
      date_of_birth: form.date_of_birth || null,
      marital_status: form.marital_status || null,
      phone_number: form.phone_number || null,
      email: form.email || null,
      residence: toUpper(form.residence || null),

      is_baptized: baptized,
      baptism_year: baptized && form.baptism_year ? Number(form.baptism_year) : null,
      baptism_place: baptized ? toUpper(form.baptism_place || null) : null,
      church_area: baptized ? (toUpper((form.church_area || '').trim()) || null) : null,
      ministry_group: toUpper(form.ministry_group || null),
      church_role: form.church_role || null,

      spouse: cleanSpouse(form.spouse, married),
      children: married ? form.children.map(child => cleanChild(child)).filter(child => child.full_name) : [],
      family_members: cleanFamilyMembers(form.family_members),
      emergency_contact_name: toUpper(form.emergency_contact_name || null),
      emergency_contact_phone: form.emergency_contact_phone || null,

      is_tucasa_member: student,
      institution_name: student ? toUpper(form.institution_name || null) : null,
      occupation: toUpper(form.occupation || null),
      skills: toUpper(form.skills || null),
      special_needs: toUpper(form.special_needs || null),
    }

    if (!payload.full_name || !payload.gender) {
      error.value = 'Jina kamili na jinsia ni lazima.'
      return
    }

    const excludeId = editing.value?.id || null
    const duplicate = await findDuplicateMember(payload, excludeId)

    /*
     * If the matching record is already a family person, promote/update
     * that SAME row instead of creating a second row.
     */
    if (duplicate && !editing.value) {
      const nestedMatch = findNestedFamilyPlaceholder(payload, duplicate.id)

      if (nestedMatch) {
        const linked = await connectPersonalRegistrationToFamily(payload, duplicate)

        if (linked) {
          message.value =
            `${payload.full_name} tayari alikuwa ameongezwa kama mwanafamilia. ` +
            `Taarifa zake zimeboreshwa kwenye Church Members bila kutengeneza duplicate.`

          await loadResidents()
          resetForm()
          return
        }
      }

      error.value =
        `Taarifa za ${duplicate.full_name} tayari zimesajiliwa. Mfumo umezuia duplicate hii.`
      return
    }

    const { data: userData, error: userError } = await supabase.auth.getUser()

    if (userError || !userData?.user) {
      error.value = userError?.message || 'Unable to identify the signed-in admin.'
      return
    }

    let savedResident

    if (editing.value) {
      const { data, error: updateError } = await supabase
        .from('residents')
        .update(payload)
        .eq('id', editing.value.id)
        .select('*')
        .single()

      if (updateError) {
        error.value = updateError.message
        return
      }

      savedResident = data
    } else {
      const { data, error: insertError } = await supabase
        .from('residents')
        .insert({
          ...payload,
          registered_by: userData.user.id,
        })
        .select('*')
        .single()

      if (insertError) {
        error.value = insertError.message
        return
      }

      savedResident = data
    }

    /*
     * THIS IS THE MAIN CHANGE:
     * Every spouse, child and other family member is now inserted into
     * residents as a normal row. The parent record is then updated so
     * its nested family data points to the real resident id.
     */
    const familyResult = await syncFamilyResidents(
      savedResident.id,
      payload,
      userData.user.id,
    )

    const totalFamilyPeople =
      (familyResult.spouse ? 1 : 0) +
      familyResult.children.length +
      familyResult.familyMembers.length

    if (editing.value) {
      message.value = totalFamilyPeople
        ? `Taarifa za ${payload.full_name} zimesasishwa. Wanafamilia ${totalFamilyPeople} pia wapo kwenye Church Members.`
        : 'Church member updated successfully.'
    } else {
      message.value = totalFamilyPeople
        ? `${payload.full_name} amesajiliwa. Wanafamilia ${totalFamilyPeople} pia wameongezwa kwenye Church Members.`
        : 'Church member registered successfully.'
    }

    resetForm()
    await loadResidents()

  } catch (err) {
    error.value = err?.message || 'Something went wrong.'
  } finally {
    saving.value = false
  }
}

/* =========================================================
   EDIT MEMBER
   ========================================================= */

function startEdit(resident) {
  editing.value = resident

  const children = Array.isArray(resident.children)
    ? resident.children.map((child) => ({
        full_name: child.full_name || child.name || '',
        gender: child.gender || '',
        date_of_birth: child.date_of_birth || '',
        phone_number: child.phone_number || '',
        email: child.email || '',
        residence: child.residence || '',
        is_baptized: !!child.is_baptized,
        baptism_year: child.baptism_year || '',
        baptism_place: child.baptism_place || '',
        church_area: child.church_area || '',
        ministry_group: child.ministry_group || '',
        church_role: child.church_role || '',
        special_needs: child.special_needs || '',
        is_tucasa_member: !!child.is_tucasa_member,
        institution_name: child.institution_name || '',
        occupation: child.occupation || '',
        skills: child.skills || '',
      }))
    : []

  const spouse = resident.spouse && typeof resident.spouse === 'object'
    ? {
        full_name: resident.spouse.full_name || '',
        gender: resident.spouse.gender || '',
        date_of_birth: resident.spouse.date_of_birth || '',
        phone_number: resident.spouse.phone_number || '',
        email: resident.spouse.email || '',
        is_baptized: !!resident.spouse.is_baptized,
        baptism_year: resident.spouse.baptism_year || '',
        baptism_place: resident.spouse.baptism_place || '',
        church_area: resident.spouse.church_area || '',
        ministry_group: resident.spouse.ministry_group || '',
        church_role: resident.spouse.church_role || '',
        special_needs: resident.spouse.special_needs || '',
        is_tucasa_member: !!resident.spouse.is_tucasa_member,
        institution_name: resident.spouse.institution_name || '',
        occupation: resident.spouse.occupation || '',
        skills: resident.spouse.skills || '',
      }
    : emptyForm().spouse

  const family_members = Array.isArray(resident.family_members)
    ? resident.family_members.map((member) => ({
        full_name: member.full_name || '',
        relationship: member.relationship || '',
        gender: member.gender || '',
        date_of_birth: member.date_of_birth || '',
        phone_number: member.phone_number || '',
        email: member.email || '',
        residence: member.residence || '',
        is_baptized: !!member.is_baptized,
        baptism_year: member.baptism_year || '',
        baptism_place: member.baptism_place || '',
        church_area: member.church_area || '',
        ministry_group: member.ministry_group || '',
        church_role: member.church_role || '',
        special_needs: member.special_needs || '',
        is_tucasa_member: !!member.is_tucasa_member,
        institution_name: member.institution_name || '',
        occupation: member.occupation || '',
        skills: member.skills || '',
      }))
    : []

  Object.assign(form, {
    full_name: resident.full_name || '',
    gender: resident.gender || '',
    date_of_birth: resident.date_of_birth || '',
    marital_status: resident.marital_status || '',
    phone_number: resident.phone_number || '',
    email: resident.email || '',
    residence: resident.residence || '',

    is_baptized: !!resident.is_baptized,
    baptism_year: resident.baptism_year || '',
    baptism_place: resident.baptism_place || '',
    church_area: resident.church_area || '',
    ministry_group: resident.ministry_group || '',
    church_role: resident.church_role || '',

    spouse,
    children,
    family_members,
    emergency_contact_name: resident.emergency_contact_name || '',
    emergency_contact_phone: resident.emergency_contact_phone || '',

    is_tucasa_member: !!resident.is_tucasa_member,
    institution_name: resident.institution_name || '',
    occupation: resident.occupation || '',
    skills: resident.skills || '',
    special_needs: resident.special_needs || '',
  })

  window.scrollTo({ top: 0, behavior: 'smooth' })
}

/* =========================================================
   DELETE MEMBER
   ========================================================= */

async function deleteResident(resident) {
  const confirmed = confirm(`Delete ${resident.full_name}? This cannot be undone.`)
  if (!confirmed) return

  error.value = ''

  const { error: deleteError } = await supabase
    .from('residents')
    .delete()
    .eq('id', resident.id)

  if (deleteError) {
    error.value = deleteError.message
    return
  }

  message.value = 'Church member deleted successfully.'
  await loadResidents()
}

function resetForm() {
  editing.value = null
  Object.assign(form, emptyForm())
}

function calculateAge(dateOfBirth) {
  if (!dateOfBirth) return '—'

  const birthDate = new Date(dateOfBirth)
  const today = new Date()

  let age = today.getFullYear() - birthDate.getFullYear()
  const monthDifference = today.getMonth() - birthDate.getMonth()

  if (
    monthDifference < 0 ||
    (monthDifference === 0 && today.getDate() < birthDate.getDate())
  ) {
    age--
  }

  if (age < 0) return '—'
  return `${age} yrs`
}

function formatDate(value) {
  if (!value) return '—'
  return new Intl.DateTimeFormat('sw-TZ', { dateStyle: 'medium' }).format(new Date(value))
}

function childrenToText(children) {
  if (!Array.isArray(children) || !children.length) return ''

  return children
    .map((child) => {
      const name = child.full_name || child.name || ''
      const age = child.date_of_birth
        ? calculateAge(child.date_of_birth)
        : (child.age !== null && child.age !== undefined && child.age !== ''
            ? `${child.age} yrs`
            : '')
      return age ? `${name} (${age})` : name
    })
    .filter(Boolean)
    .join('; ')
}

function familyMembersToText(members) {
  if (!Array.isArray(members) || !members.length) return ''

  return members
    .map((member) =>
      member.relationship
        ? `${member.full_name} (${member.relationship})`
        : member.full_name,
    )
    .join('; ')
}

function exportExcel() {
  const rows = residents.value.map((resident) => ({
    'Jina kamili': resident.full_name,
    'Jinsia': resident.gender,
    'Tarehe ya kuzaliwa': resident.date_of_birth || '',
    'Umri': calculateAge(resident.date_of_birth),
    'Hali ya ndoa': resident.marital_status || '',
    'Namba ya simu': resident.phone_number || '',
    'Email': resident.email || '',
    'Anwani/Makazi': resident.residence || '',

    'Umebatizwa?': resident.is_baptized ? 'Ndiyo' : 'Hapana',
    'Mwaka wa ubatizo': resident.baptism_year || '',
    'Kanisa ulipobatizwa': resident.baptism_place || '',
    'Ushirika ulipo': resident.church_area || '',
    'Idara/Kikundi': resident.ministry_group || '',
    'Wadhifa': resident.church_role || '',

    'Jina la Mwenzi': resident.spouse?.full_name || '',
    'Jinsia ya Mwenzi': resident.spouse?.gender || '',
    'Tarehe ya kuzaliwa (Mwenzi)': resident.spouse?.date_of_birth || '',
    'Simu ya Mwenzi': resident.spouse?.phone_number || '',
    'Amebatizwa (Mwenzi)': resident.spouse?.is_baptized ? 'Ndiyo' : (resident.spouse ? 'Hapana' : ''),
    'Mwaka wa ubatizo (Mwenzi)': resident.spouse?.baptism_year || '',
    'Mahali alipobatizwa (Mwenzi)': resident.spouse?.baptism_place || '',
    'Idara (Mwenzi)': resident.spouse?.ministry_group || '',
    'Wadhifa (Mwenzi)': resident.spouse?.church_role || '',
    'MwanaTUCASA (Mwenzi)': resident.spouse?.is_tucasa_member ? 'Ndiyo' : (resident.spouse ? 'Hapana' : ''),
    'Chuo (Mwenzi)': resident.spouse?.is_tucasa_member ? (resident.spouse?.institution_name || '') : '',
    'Elimu/Kazi (Mwenzi)': resident.spouse?.occupation || '',
    'Vipaji/Mahususi (Mwenzi)': resident.spouse?.skills || '',
    'Watoto': childrenToText(resident.children),
    'Wanafamilia Wengine': familyMembersToText(resident.family_members),
    'Mtu wa karibu wa kuwasiliana nae ikiwa sipatikani — Jina': resident.emergency_contact_name || '',
    'Mtu wa karibu wa kuwasiliana nae ikiwa sipatikani — Namba': resident.emergency_contact_phone || '',

    'MwanaTUCASA?': resident.is_tucasa_member ? 'Ndiyo' : 'Hapana',
    'Chuo': resident.institution_name || '',
    'Elimu/Kazi': resident.occupation || '',
    'Vipaji/Mahususi': resident.skills || '',
    'Mahitaji Maalum': resident.special_needs || '',

    'Watoto - Taarifa za Ziada': (resident.children || [])
      .map((child) =>
        `${child.full_name || child.name || ''}: TUCASA=${child.is_tucasa_member ? 'Ndiyo' : 'Hapana'}${child.is_tucasa_member && child.institution_name ? `, Chuo=${child.institution_name}` : ''}, Elimu/Kazi=${child.occupation || ''}, Vipaji=${child.skills || ''}`,
      )
      .filter(Boolean)
      .join('; '),

    'Wanafamilia - Taarifa za Ziada': (resident.family_members || [])
      .map((member) =>
        `${member.full_name || ''}: TUCASA=${member.is_tucasa_member ? 'Ndiyo' : 'Hapana'}${member.is_tucasa_member && member.institution_name ? `, Chuo=${member.institution_name}` : ''}, Elimu/Kazi=${member.occupation || ''}, Vipaji=${member.skills || ''}`,
      )
      .filter(Boolean)
      .join('; '),

    'Registered by': resident.registered_by || '',
    'Tarehe ya usajili': resident.created_at
      ? new Date(resident.created_at).toLocaleString('sw-TZ')
      : '',
  }))

  const worksheet = XLSX.utils.json_to_sheet(rows)
  const workbook = XLSX.utils.book_new()

  XLSX.utils.book_append_sheet(workbook, worksheet, 'Church Members')

  const columnWidths = [
    25, 13, 16, 8, 18, 16, 26, 26,
    12, 14, 22, 22, 20, 12,
    22, 16, 22, 16, 16, 18, 24, 18, 16, 16, 18, 22, 24,
    30, 30,
    20, 18,
    12, 18, 22, 26, 24,
    46, 46,
    38, 22,
  ]

  worksheet['!cols'] = columnWidths.map(width => ({ wch: width }))

  XLSX.writeFile(
    workbook,
    `golani-church-members-${new Date().toISOString().slice(0, 10)}.xlsx`,
  )
}

</script>


<style scoped>

@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700;800&display=swap');

/* =========================================================
   VARIABLES — church-blue brand system (white / #1a3f6f / dark text)
========================================================= */

.dashboard {
  --church-blue: #1a3f6f;
  --church-blue-dark: #12304f;
  --blue-tint: #eef3f9;
  --blue-tint-2: #e1eaf4;
  --blue-line: #cddbea;

  --text: #1c2b3d;
  --muted: #6b7785;

  --border: #e0e7ef;

  --white: #ffffff;

  --success: #147a4c;
  --success-bg: #e6f7ee;
  --danger: #c0392b;
  --danger-bg: #fdecea;

  font-family: 'Poppins', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  min-height: 100vh;
  padding: 30px 34px 65px;

  background:
    radial-gradient(circle at top right, rgba(26, 63, 111, 0.07), transparent 38%),
    linear-gradient(180deg, #f6f8fb 0%, #eef2f7 100%);

  color: var(--text);
}


/* =========================================================
   TOP BAR
========================================================= */

.topbar {
  max-width: 1450px;
  margin: 0 auto 26px;
  min-height: 100px;
  padding: 18px 26px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 25px;
  background: linear-gradient(135deg, var(--church-blue) 0%, var(--church-blue-dark) 100%);
  border-radius: 18px;
  box-shadow: 0 14px 34px rgba(18, 48, 79, 0.28);
  position: relative;
  overflow: hidden;
}

.topbar::after {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(circle at 85% -20%, rgba(255, 255, 255, 0.16), transparent 55%);
  pointer-events: none;
}


/* =========================================================
   BRAND
========================================================= */

.brand-area {
  display: flex;
  align-items: center;
  gap: 16px;
  min-width: 0;
  position: relative;
  z-index: 1;
}

.brand-logo {
  width: 64px;
  height: 64px;
  flex: 0 0 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.14);
  border: 1px solid rgba(255, 255, 255, 0.28);
  border-radius: 16px;
  overflow: hidden;
}

.brand-logo img {
  width: 46px;
  height: 46px;
  object-fit: contain;
}

.brand-text {
  min-width: 0;
}

.eyebrow {
  margin: 0 0 4px;
  color: var(--church-blue-dark);
  background: var(--white);
  display: inline-block;
  padding: 3px 10px;
  border-radius: 999px;
  font-size: 10px;
  font-weight: 800;
  letter-spacing: .07em;
}

.topbar h1 {
  margin: 6px 0 2px;
  color: var(--white);
  font-size: 22px;
  font-weight: 800;
  line-height: 1.15;
}

.brand-subtitle {
  margin: 0;
  color: rgba(255, 255, 255, 0.72);
  font-size: 12.5px;
}

.topbar-actions {
  display: flex;
  align-items: center;
  gap: 16px;
  position: relative;
  z-index: 1;
}

.admin-info {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
}

.admin-label {
  color: rgba(255, 255, 255, 0.65);
  font-size: 11px;
  font-weight: 600;
}

.admin-email {
  color: var(--white);
  font-size: 13px;
  font-weight: 700;
  max-width: 220px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.topbar-actions .ghost-button {
  color: var(--white);
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.35);
}

.topbar-actions .ghost-button:hover {
  background: rgba(255, 255, 255, 0.2);
  border-color: rgba(255, 255, 255, 0.55);
}


/* =========================================================
   BUTTONS
========================================================= */

.primary-button,
.secondary-button,
.ghost-button,
.small-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  min-height: 44px;
  padding: 0 18px;
  border-radius: 10px;
  border: none;
  font-family: inherit;
  font-size: 13.5px;
  font-weight: 700;
  cursor: pointer;
  transition: all .16s ease;
}

.primary-button {
  color: var(--white);
  background: var(--church-blue);
  box-shadow: 0 6px 16px rgba(26, 63, 111, 0.28);
}

.primary-button:hover:not(:disabled) {
  background: var(--church-blue-dark);
  transform: translateY(-1px);
  box-shadow: 0 10px 20px rgba(26, 63, 111, 0.32);
}

.primary-button:disabled {
  opacity: .6;
  cursor: not-allowed;
  box-shadow: none;
}

.secondary-button {
  color: var(--church-blue-dark);
  background: var(--blue-tint);
}

.secondary-button:hover:not(:disabled) {
  background: var(--blue-tint-2);
}

.secondary-button:disabled {
  opacity: .5;
  cursor: not-allowed;
}

.ghost-button {
  color: var(--church-blue-dark);
  background: var(--white);
  border: 1px solid var(--border);
}

.ghost-button:hover {
  border-color: var(--church-blue);
  color: var(--church-blue);
}


/* =========================================================
   STATISTICS
========================================================= */

.stats {
  max-width: 1450px;
  margin: 0 auto 26px;
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 15px;
}

.stat-card {
  display: flex;
  align-items: center;
  gap: 14px;
  min-height: 100px;
  padding: 18px 20px;
  background: var(--white);
  border: 1px solid var(--border);
  border-radius: 16px;
  box-shadow: 0 8px 22px rgba(26, 63, 111, 0.06);
  transition: transform .16s ease, box-shadow .16s ease;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 26px rgba(26, 63, 111, 0.1);
}

.stat-icon {
  width: 44px;
  height: 44px;
  flex: 0 0 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--blue-tint);
  color: var(--church-blue);
  border-radius: 12px;
  font-size: 18px;
}

.navy-icon {
  background: linear-gradient(135deg, var(--church-blue), var(--church-blue-dark));
  color: var(--white);
}

.stat-card span {
  display: block;
  color: var(--muted);
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: .03em;
}

.stat-card strong {
  display: block;
  margin-top: 3px;
  color: var(--church-blue-dark);
  font-size: 26px;
  font-weight: 800;
}


/* =========================================================
   PANEL
========================================================= */

.panel {
  max-width: 1450px;
  margin: 0 auto 26px;
  background: var(--white);
  border: 1px solid var(--border);
  border-radius: 16px;
  box-shadow: 0 8px 28px rgba(26, 63, 111, 0.05);
  overflow: hidden;
}

.panel-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  padding: 21px 24px;
  background: linear-gradient(90deg, var(--blue-tint), transparent);
  border-bottom: 1px solid var(--border);
}

.section-title {
  display: flex;
  align-items: center;
  gap: 12px;
}

.section-title-icon {
  width: 39px;
  height: 39px;
  flex: 0 0 39px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--white);
  background: linear-gradient(135deg, var(--church-blue), var(--church-blue-dark));
  border-radius: 10px;
  font-size: 20px;
  font-weight: 700;
}

.people-icon {
  font-size: 18px;
}

.panel-heading h2 {
  margin: 0;
  color: var(--church-blue-dark);
  font-size: 18px;
  line-height: 1.2;
  font-weight: 800;
}

.panel-heading p {
  margin: 5px 0 0;
  color: var(--muted);
  font-size: 12px;
}

.panel-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}


/* =========================================================
   SEARCH
========================================================= */

.search-wrapper {
  position: relative;
  width: 280px;
}

.search-icon {
  position: absolute;
  left: 13px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--muted);
  font-size: 15px;
}

.search-input {
  width: 100%;
  min-height: 42px;
  padding: 0 14px 0 34px;
  border: 1px solid var(--border);
  border-radius: 9px;
  font-family: inherit;
  font-size: 13px;
  outline: none;
  transition: border-color .16s ease, box-shadow .16s ease;
}

.search-input:focus {
  border-color: var(--church-blue);
  box-shadow: 0 0 0 3px rgba(26, 63, 111, .1);
}


/* =========================================================
   FORM
========================================================= */

.resident-form {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 18px;
  padding: 26px 24px;
}

.span-2 {
  grid-column: 1 / -1;
}

.resident-form label {
  display: flex;
  flex-direction: column;
  gap: 7px;
  color: var(--church-blue-dark);
  font-size: 13px;
  font-weight: 700;
}

.resident-form label > span {
  display: block;
}

.resident-form label b {
  color: var(--church-blue);
}

.resident-form input,
.resident-form select {
  width: 100%;
  min-height: 46px;
  padding: 0 13px;
  color: var(--text);
  background: var(--white);
  border: 1px solid var(--border);
  border-radius: 9px;
  outline: none;
  font-family: inherit;
  font-size: 14px;
  transition: border-color .18s ease, box-shadow .18s ease;
}

.resident-form input::placeholder {
  color: #a3adba;
}

.resident-form input:hover,
.resident-form select:hover {
  border-color: #a9b8c9;
}

.resident-form input:focus,
.resident-form select:focus {
  border-color: var(--church-blue);
  box-shadow: 0 0 0 3px rgba(26, 63, 111, .1);
}

.resident-form select {
  cursor: pointer;
}

.resident-form select:disabled {
  cursor: not-allowed;
  opacity: .8;
  background: var(--blue-tint);
  color: var(--church-blue-dark);
}


/* =========================================================
   FORM SECTION HEADERS
========================================================= */

.form-section {
  grid-column: 1 / -1;
  display: flex;
  align-items: baseline;
  gap: 10px;
  margin-top: 6px;
  padding-bottom: 9px;
  border-bottom: 2px solid var(--blue-tint-2);
}

.form-section:first-of-type {
  margin-top: 0;
}

.form-section-number {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 22px;
  height: 22px;
  background: var(--church-blue);
  color: var(--white);
  border-radius: 50%;
  font-size: 11px;
  font-weight: 800;
}

.form-section h3 {
  margin: 0;
  color: var(--church-blue-dark);
  font-size: 14px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: .03em;
}

.form-section-hint {
  margin-left: auto;
  color: var(--muted);
  font-size: 11px;
  font-weight: 600;
}


/* =========================================================
   FIELD HINT
========================================================= */

.field-hint {
  display: block;
  margin-top: -2px;
  color: var(--muted);
  font-size: 10.5px;
  font-weight: 500;
  line-height: 1.45;
}

/* =========================================================
   CONDITIONAL PANELS (baptism year/place, children list)
========================================================= */

.conditional-panel {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 18px;
  padding: 16px;
  background: var(--blue-tint);
  border: 1px dashed var(--blue-line);
  border-radius: 10px;
}

.children-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 14px;
  background: var(--blue-tint);
  border: 1px dashed var(--blue-line);
  border-radius: 10px;
}

.child-row {
  display: grid;
  grid-template-columns: 2fr 1fr auto;
  gap: 10px;
  align-items: center;
}

.child-row input {
  min-height: 42px;
}

.child-remove {
  width: 34px;
  height: 34px;
  border: 1px solid #f1c5c1;
  background: var(--white);
  color: var(--danger);
  border-radius: 8px;
  cursor: pointer;
  font-size: 13px;
  transition: all .16s ease;
}

.child-remove:hover {
  background: var(--danger);
  color: var(--white);
  border-color: var(--danger);
}

.children-view {
  margin: 4px 0 0;
  padding-left: 18px;
  color: var(--church-blue-dark);
  font-weight: 600;
  font-size: 13px;
}


/* =========================================================
   SUBSECTION LABELS (splits Section 3 into Mwenzi / Watoto / Wanafamilia)
========================================================= */

.subsection-label {
  margin: 2px 0 -6px;
  color: var(--church-blue);
  font-size: 11.5px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: .04em;
}


/* =========================================================
   OTHER FAMILY MEMBERS (not children, not the spouse)
========================================================= */

.family-members-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

/* Wrapper for the child/family-member cards inside the member-detail
   modal (3b/3c). Used in the template but had no rule at all before —
   same spacing pattern as .family-members-list above. */
.children-details,
.family-details-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.family-member-card {
  padding: 14px;
  background: var(--blue-tint);
  border: 1px dashed var(--blue-line);
  border-radius: 10px;
}

.family-member-card-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}

.family-member-card-head span {
  color: var(--church-blue-dark);
  font-size: 11.5px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: .03em;
}

.family-member-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
}

.family-member-grid input,
.family-member-grid select {
  min-height: 42px;
}

.add-family-btn {
  justify-self: start;
}


/* =========================================================
   AUTOMATIC INFO
========================================================= */

.automatic-info {
  grid-column: 1 / -1;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 13px 15px;
  background: var(--blue-tint);
  border: 1px solid var(--blue-tint-2);
  border-radius: 9px;
}

.automatic-icon {
  width: 32px;
  height: 32px;
  flex: 0 0 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--white);
  background: var(--church-blue);
  border-radius: 8px;
  font-size: 14px;
}

.automatic-info strong {
  display: block;
  color: var(--church-blue-dark);
  font-size: 12.5px;
}

.automatic-info p {
  margin: 2px 0 0;
  color: var(--muted);
  font-size: 11.5px;
}


/* =========================================================
   FORM ACTIONS
========================================================= */

.form-actions {
  grid-column: 1 / -1;
  display: flex;
  align-items: center;
  gap: 10px;
}


/* =========================================================
   TABLE
========================================================= */

.table-wrap {
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12.5px;
}

thead th {
  padding: 12px 14px;
  text-align: left;
  color: var(--muted);
  background: var(--blue-tint);
  border-bottom: 1px solid var(--border);
  font-size: 10.5px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: .03em;
  white-space: nowrap;
}

tbody td {
  padding: 12px 14px;
  border-bottom: 1px solid #eef1f5;
  color: var(--text);
  white-space: nowrap;
}

tbody tr:hover {
  background: rgba(26, 63, 111, .035);
}

td strong {
  color: var(--church-blue-dark);
  font-weight: 800;
}


/* =========================================================
   STATUS
========================================================= */

.status-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 52px;
  padding: 4px 8px;
  border-radius: 999px;
  font-size: 10px;
  font-weight: 800;
}

.status-yes {
  color: var(--success);
  background: var(--success-bg);
}

.status-no {
  color: var(--muted);
  background: var(--blue-tint-2);
}


/* =========================================================
   ACTIONS
========================================================= */

.actions {
  display: flex;
  align-items: center;
  gap: 6px;
}

.small-button {
  min-height: 32px;
  padding: 0 10px;
  color: var(--church-blue-dark);
  background: var(--white);
  border: 1px solid var(--border);
  border-radius: 7px;
  font-size: 11px;
}

.small-button:hover {
  color: var(--white);
  background: var(--church-blue);
  border-color: var(--church-blue);
}

.small-button.danger {
  color: var(--danger);
  border-color: #f1c5c1;
}

.small-button.danger:hover {
  color: var(--white);
  background: var(--danger);
  border-color: var(--danger);
}


/* =========================================================
   MESSAGES
========================================================= */

.success,
.error {
  grid-column: 1 / -1;
  margin: 0;
  padding: 11px 13px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 700;
}

.success {
  color: var(--success);
  background: var(--success-bg);
  border: 1px solid #b8e8cd;
}

.error {
  color: var(--danger);
  background: var(--danger-bg);
  border: 1px solid #f7c9c2;
}


/* =========================================================
   EMPTY
========================================================= */

.empty {
  padding: 48px 20px !important;
  text-align: center;
}

.empty-state {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-direction: column;
  gap: 5px;
}

.empty-state strong {
  color: var(--church-blue-dark);
  font-size: 14px;
}

.empty-state span {
  color: #98a2b3;
  font-size: 12px;
}

.empty-icon {
  width: 42px;
  height: 42px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 5px;
  color: var(--church-blue);
  background: var(--blue-tint);
  border-radius: 11px;
  font-size: 19px;
}


/* =========================================================
   DETAILS MODAL
========================================================= */

.modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 60;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding: 40px 20px;
  overflow-y: auto;
  background: rgba(11, 30, 52, .58);
}

.modal-card {
  width: 100%;
  max-width: 720px;
  background: var(--white);
  border-radius: 16px;
  padding: 26px;
  box-shadow: 0 20px 60px rgba(11, 30, 52, .35);
}

.modal-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  padding-bottom: 16px;
  margin-bottom: 16px;
  border-bottom: 2px solid var(--blue-tint-2);
}

.modal-head h2 {
  margin: 0;
  color: var(--church-blue-dark);
  font-size: 19px;
  font-weight: 800;
}

.modal-head p {
  margin: 4px 0 0;
  color: var(--muted);
  font-size: 12px;
}

.detail-section {
  margin-bottom: 18px;
}

.detail-section:last-child {
  margin-bottom: 0;
}

.detail-section h4 {
  margin: 0 0 10px;
  color: var(--church-blue-dark);
  font-size: 12px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: .04em;
}

.detail-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.detail-grid > div {
  display: flex;
  flex-direction: column;
  gap: 3px;
  padding: 10px 12px;
  background: var(--blue-tint);
  border-radius: 8px;
}

.detail-grid span {
  color: var(--muted);
  font-size: 10.5px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: .02em;
}

.detail-grid strong {
  color: var(--church-blue-dark);
  font-size: 13.5px;
  font-weight: 700;
}

.detail-subheading {
  background: transparent !important;
  padding: 8px 2px 2px !important;
  color: var(--church-blue-dark) !important;
  font-size: 12px !important;
  font-weight: 800 !important;
  text-transform: uppercase;
  letter-spacing: .03em;
  border-radius: 0 !important;
}

.family-detail-card {
  padding: 14px;
  margin-bottom: 14px;
  border: 1px solid var(--blue-line);
  border-radius: 12px;
  background: var(--white);
}

.family-detail-card > strong {
  display: block;
  margin-bottom: 10px;
  color: var(--church-blue-dark);
  font-size: 14px;
}


/* =========================================================
   TABLET
========================================================= */

@media (max-width: 1100px) {

  .dashboard {
    padding: 22px 20px 50px;
  }

  .stats {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

}


/* =========================================================
   SMALL TABLET
========================================================= */

@media (max-width: 820px) {

  .topbar {
    align-items: flex-start;
    flex-direction: column;
  }

  .topbar-actions {
    width: 100%;
    justify-content: space-between;
  }

  .admin-info {
    align-items: flex-start;
  }

  .panel-heading {
    align-items: flex-start;
    flex-direction: column;
  }

  .panel-actions {
    width: 100%;
  }

  .search-wrapper {
    width: 100%;
  }

  .resident-form,
  .conditional-panel,
  .detail-grid {
    grid-template-columns: 1fr;
  }

  .family-member-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .automatic-info,
  .form-actions,
  .success,
  .error {
    grid-column: auto;
  }

}


/* =========================================================
   MOBILE
========================================================= */

@media (max-width: 560px) {

  .dashboard {
    padding: 12px 10px 35px;
  }

  .topbar {
    padding: 18px;
    border-radius: 13px;
  }

  .brand-area {
    width: 100%;
  }

  .brand-logo {
    width: 52px;
    height: 52px;
    flex-basis: 52px;
    border-radius: 12px;
  }

  .brand-logo img {
    width: 38px;
    height: 38px;
  }

  .topbar h1 {
    font-size: 19px;
  }

  .brand-subtitle {
    display: none;
  }

  .topbar-actions {
    align-items: stretch;
    flex-direction: column;
  }

  .admin-info {
    align-items: flex-start;
  }

  .admin-email {
    max-width: 100%;
  }

  .topbar-actions .ghost-button {
    width: 100%;
  }

  .stats {
    grid-template-columns: 1fr 1fr;
    gap: 9px;
  }

  .stat-card {
    min-height: 90px;
    padding: 14px 12px;
    gap: 10px;
  }

  .stat-icon {
    width: 38px;
    height: 38px;
    flex-basis: 38px;
    font-size: 16px;
  }

  .stat-card span {
    font-size: 9px;
  }

  .stat-card strong {
    font-size: 23px;
  }

  .panel {
    border-radius: 13px;
  }

  .panel-heading {
    padding: 17px;
  }

  .section-title-icon {
    width: 34px;
    height: 34px;
    flex-basis: 34px;
  }

  .panel-heading h2 {
    font-size: 16px;
  }

  .panel-actions {
    align-items: stretch;
    flex-direction: column;
  }

  .panel-actions button {
    width: 100%;
  }

  .resident-form {
    padding: 19px 17px;
  }

  .form-actions {
    align-items: stretch;
    flex-direction: column;
  }

  .form-actions button {
    width: 100%;
  }

  .automatic-info {
    align-items: flex-start;
  }

  .modal-card {
    padding: 18px;
  }

  .child-row {
    grid-template-columns: 1fr;
  }

  .family-member-grid {
    grid-template-columns: 1fr;
  }

  .add-family-btn {
    width: 100%;
    justify-self: stretch;
  }

}

</style>
