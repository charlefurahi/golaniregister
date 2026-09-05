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
          <p class="eyebrow">KANISA LA WAADVENTISTA WA SABATO GOLANI</p>
          <h1>Karibu sana na ujaze taarifa zako kwa usahihi</h1>
          <p class="brand-subtitle"></p>
        </div>
      </div>

      <div class="topbar-actions">
        <div class="admin-info">
          <span class="admin-label">Nimeingia kama</span>
          <span class="admin-email">{{ guestMode ? 'Mtumiaji wa kawaida' : session?.user?.email }}</span>
        </div>
        <button class="ghost-button" type="button" @click="$emit('logged-out')">
          Toka
        </button>
      </div>
    </header>


    <!-- =====================================================
         LOADING
    ====================================================== -->
    <section v-if="loading" class="panel">
      <p class="muted-line">Inapakia taarifa zangu…</p>
    </section>


    <!-- =====================================================
         AHSANTE (baada ya kuwasilisha kwa mafanikio)
    ====================================================== -->
    <section v-else-if="submittedSuccess" class="panel">
      <div class="panel-heading">
        <div class="section-title">
          <div class="section-title-icon">✓</div>
          <div>
            <h2>Ahsante kwa ushirikiano</h2>
            <p>{{ message || 'Taarifa zako zimehifadhiwa kwa mafanikio.' }}</p>
          </div>
        </div>
      </div>

      <div class="form-actions" style="justify-content: flex-start; gap: 12px;">
        <button type="button" class="secondary-button" @click="$emit('logged-out')">
          Toka
        </button>
        <button type="button" class="primary-button" @click="startNewRegistration">
          Usajili Mpya
        </button>
      </div>
    </section>


    <!-- =====================================================
         FORM
    ====================================================== -->
    <section v-else class="panel">

      <div class="panel-heading">
        <div class="section-title">
          <div class="section-title-icon">✎</div>
          <div>
            <h2>{{ myResidentId ? 'Hariri Taarifa Zangu' : 'Jaza Taarifa Zangu' }}</h2>
            <p>
              {{
                myResidentId
                  ? 'Sasisha taarifa zangu binafsi hapa chini.'
                  : '.'
              }}
            </p>
          </div>
        </div>
      </div>

      <p v-if="message" class="success" role="status">{{ message }}</p>
      <p v-if="error" class="error" role="alert">{{ error }}</p>

      <div v-if="draftRestored" class="draft-restore-actions">
        <button type="button" class="secondary-button" @click="discardDraftAndReset">
          Futa Nilichokuwa Nikijaza, Anza Upya
        </button>
      </div>

      <form class="resident-form" @submit.prevent="openReviewModal">

        <!-- ================= SEHEMU 1: TAARIFA ZANGU BINAFSI ================= -->
        <div class="form-section">
          <span class="form-section-number">1</span>
          <h3>Taarifa Zangu Binafsi</h3>
          <span class="form-section-hint">Lazima</span>
        </div>

        <label>
          <span>Jina langu kamili <b>*</b></span>
          <input v-model.trim="form.full_name" required placeholder="Andika jina lako kamili" @blur="() => { upperize(form, 'full_name'); checkNameDuplicate() }" />
        </label>

        <div
          v-if="guestMode && nameDuplicateInfo && !nameDuplicateDismissed && !myResidentId"
          class="name-duplicate-banner span-2"
          role="alert"
        >
          <template v-if="!nameConfirmedSelf">
            <p>{{ nameDuplicateMessage }}</p>
            <div class="name-duplicate-actions">
              <button type="button" class="secondary-button" @click="nameConfirmedSelf = true">Ndiyo, ni mimi</button>
              <button type="button" class="secondary-button" @click="dismissNameDuplicate">Hapana, ni mtu tofauti</button>
            </div>
          </template>
          <p v-else>
            Sawa — jaza taarifa zako kwa usahihi sasa
          </p>
        </div>

        <label>
          <span>Jinsia yangu <b>*</b></span>
          <select v-model="form.gender" required>
            <option disabled value="">Chagua jinsia</option>
            <option value="Mwanaume">Mwanaume</option>
            <option value="Mwanamke">Mwanamke</option>
          </select>
        </label>

        <label>
          <span>Tarehe yangu ya kuzaliwa</span>
          <input v-model="form.date_of_birth" type="date" required />
        </label>

        <label>
          <span>Hali yangu ya ndoa</span>
          <select v-model="form.marital_status" required>
            <option value="">Chagua Hali ya ndoa</option>
            <!-- value = thamani inayokubalika na database (CHECK constraint), label = nafsi ya kwanza -->
            <option value="Hajaoa/Hajaolewa">Sijaoa/Sijaolewa</option>
            <option value="Ameoa/Ameolewa">Nimeoa/Nimeolewa</option>
            <option value="Mjane">Nimefiwa (Mjane)</option>
            <option value="Mgane">Nimefiwa (Mgane)</option>
            <option value="Talaka">Nimeachika (Talaka)</option>
          </select>
        </label>

        <label>
          <span>Namba yangu ya simu <b>*</b></span>
          <div class="phone-input-group">
            <span class="phone-prefix">+255</span>
            <input
              :value="extractPhoneDigits(form.phone_number)"
              @input="updatePhoneField(form, 'phone_number', $event.target.value)"
              type="tel"
              inputmode="numeric"
              maxlength="9"
              required
              placeholder="7XXXXXXXX"
              @blur="validatePhone"
            />
          </div>
          <small v-if="phoneError" class="field-error">{{ phoneError }}</small>
        </label>

        <label>
          <span>Barua pepe yangu (Email) <b>*</b></span>
          <input
            v-model.trim="form.email"
            type="email"
            required
            placeholder="jina@mfano.com"
            @blur="validateEmail"
          />
          <small v-if="emailError" class="field-error">{{ emailError }}</small>
        </label>

        <label class="span-2">
          <span>Anwani/Makazi yangu <b>*</b></span>
          <input
            v-model.trim="form.residence"
            required
            placeholder="Mtaa, Kata, Jiji — Mfano: Miono, Msata, Dodoma"
            @blur="() => { upperize(form, 'residence'); validateResidence() }"
          />
          <small v-if="residenceError" class="field-error">{{ residenceError }}</small>
        </label>


        <!-- ================= SEHEMU 2: TAARIFA ZANGU ZA KIROHO / KANISA ================= -->
        <div class="form-section">
          <span class="form-section-number">2</span>
          <h3>Taarifa Zangu za Kiroho / Kanisa</h3>
        </div>

        <label>
          <span>Nimebatizwa?</span>
          <select v-model="form.is_baptized">
            <option :value="false">Hapana</option>
            <option :value="true">Ndiyo</option>
          </select>
        </label>

        <div></div>

        <template v-if="form.is_baptized">
          <div class="conditional-panel span-2">
            <label>
              <span>Mwaka wangu wa ubatizo</span>
              <input
                v-model="form.baptism_year"
                type="number"
                min="1900"
                :max="currentYear"
                placeholder="Mfano: 2014"
              />
            </label>
            <label>
              <span>Kanisa nilipobatizwa</span>
              <input v-model.trim="form.baptism_place" placeholder="Mfano: Golani SDA Church" @blur="upperize(form, 'baptism_place')" />
            </label>
            <label>
              <span>Ushirika wangu ulipo</span>
              <input v-model.trim="form.church_area" placeholder="Mfano: Golani SDA" @blur="upperize(form, 'church_area')" />
            </label>
          </div>
        </template>

        <label>
          <span>Idara/Kikundi nilichopo</span>
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
          <span>Wadhifa wangu</span>
          <select v-model="form.church_role">
            <option value="">Chagua wadhifa </option>
            <option value="Muumini">Muumini</option>
            <option value="Mshiriki">Mshiriki</option>
            <option value="Kiongozi">Kiongozi</option>
            <option value="Mchungaji">Mchungaji</option>
            <option value="Mzee">Mzee</option>
          </select>
        </label>


        <!-- ================= SEHEMU 3: TAARIFA ZA FAMILIA YANGU ================= -->
        <div class="form-section">
          <span class="form-section-number">3</span>
          <h3>Taarifa za Familia Yangu</h3>
          <span v-if="!isMarried" class="form-section-hint">
            Taarifa za mwenzi wangu zitaonekana ikiwa Nimeoa/Nimeolewa.
          </span>
        </div>

        <!-- ---------- Mwenzi Wangu: ipo tu kwa waliooa/waliolewa ---------- -->
        <template v-if="isMarried">

          <div class="subsection-label span-2">Taarifa Binafsi za Mwenzi Wangu</div>

          <label>
            <span>Jina kamili la mwenzi wangu</span>
            <input v-model.trim="form.spouse.full_name" placeholder="Jina kamili la mwenzi wangu" @blur="upperize(form.spouse, 'full_name')" />
          </label>

          <label>
            <span>Jinsia</span>
            <select v-model="form.spouse.gender" disabled>
              <option value="">Jinsia itawekwa moja kwa moja</option>
              <option value="Mwanaume">Mwanaume</option>
              <option value="Mwanamke">Mwanamke</option>
            </select>
            <small class="field-hint">
              Loaded automatically based on your maritual status
            </small>
          </label>

          <label>
            <span>Tarehe ya kuzaliwa (Mwenzi wangu)</span>
            <input v-model="form.spouse.date_of_birth" type="date" />
          </label>

          <label>
            <span>Namba ya simu (Mwenzi wangu) <b>*</b></span>
            <div class="phone-input-group">
              <span class="phone-prefix">+255</span>
              <input
                :value="extractPhoneDigits(form.spouse.phone_number)"
                @input="updatePhoneField(form.spouse, 'phone_number', $event.target.value)"
                type="tel"
                inputmode="numeric"
                maxlength="9"
                required
                placeholder="7XXXXXXXX"
                @blur="validateSpousePhone"
              />
            </div>
            <small v-if="spousePhoneError" class="field-error">{{ spousePhoneError }}</small>
          </label>

          <label class="span-2">
            <span>Barua pepe (Mwenzi wangu) <b>*</b></span>
            <input
              v-model.trim="form.spouse.email"
              type="email"
              required
              placeholder="johndoe@mfano.com"
              @blur="validateSpouseEmail"
            />
            <small v-if="spouseEmailError" class="field-error">{{ spouseEmailError }}</small>
          </label>

          <div class="subsection-label span-2">Taarifa za Kiroho / Kanisa za Mwenzi Wangu</div>

          <label>
            <span>Amebatizwa? (Mwenzi wangu)</span>
            <select v-model="form.spouse.is_baptized">
              <option :value="false">Hapana</option>
              <option :value="true">Ndiyo</option>
            </select>
          </label>

          <div></div>

          <template v-if="form.spouse.is_baptized">
            <div class="conditional-panel span-2">
              <label>
                <span>Mwaka wa ubatizo (Mwenzi wangu)</span>
                <input
                  v-model="form.spouse.baptism_year"
                  type="number"
                  min="1900"
                  :max="currentYear"
                  placeholder="Mfano: 2018"
                />
              </label>
              <label>
                <span>Mahali alipobatizwa (Mwenzi wangu)</span>
                <input v-model.trim="form.spouse.baptism_place" placeholder="Mfano: Golani SDA Church" @blur="upperize(form.spouse, 'baptism_place')" />
              </label>
              <label>
                <span>Ushirika ulipo (Mwenzi wangu)</span>
                <input v-model.trim="form.spouse.church_area" placeholder="Mfano: Golani SDA" @blur="upperize(form.spouse, 'church_area')" />
              </label>
            </div>
          </template>

          <label>
            <span>Idara/Kikundi (Mwenzi wangu)</span>
            <input v-model.trim="form.spouse.ministry_group" list="ministry-group-options" placeholder="Mfano: Kwaya, Vijana, Dorkas" @blur="upperize(form.spouse, 'ministry_group')" />
          </label>

          <label>
            <span>Wadhifa (Mwenzi wangu)</span>
            <select v-model="form.spouse.church_role">
              <option value="">Chagua wadhifa</option>
              <option value="Muumini">Muumini</option>
              <option value="Mshiriki">Mshiriki</option>
              <option value="Kiongozi">Kiongozi</option>
              <option value="Mchungaji">Mchungaji</option>
              <option value="Mzee">Mzee</option>
            </select>
          </label>

          <label>
            <span>Mahitaji Maalum (Mwenzi wangu)</span>
            <input v-model.trim="form.spouse.special_needs" placeholder="Mfano: Anahitaji msaada maalum" @blur="upperize(form.spouse, 'special_needs')" />
          </label>

          <div class="subsection-label span-2">Taarifa za Ziada za Mwenzi Wangu</div>

          <label>
            <span>Ni MwanaTUCASA? (Mwenzi wangu)</span>
            <select v-model="form.spouse.is_tucasa_member">
              <option :value="false">Hapana</option>
              <option :value="true">Ndiyo</option>
            </select>
          </label>

          <label v-if="form.spouse.is_tucasa_member">
            <span>Chuo anachosoma (Mwenzi wangu)</span>
            <input v-model.trim="form.spouse.institution_name" placeholder="Mfano: UDSM, NIT, SUA, MUHAS" @blur="upperize(form.spouse, 'institution_name')" />
          </label>
          <div v-else></div>

          <label>
            <span>Elimu/Kazi (Mwenzi wangu)</span>
            <input v-model.trim="form.spouse.occupation" placeholder="Mfano: Mwalimu, Mfanyabiashara" @blur="upperize(form.spouse, 'occupation')" />
          </label>

          <label>
            <span>Vipaji/Mahususi (Mwenzi wangu)</span>
            <input v-model.trim="form.spouse.skills" placeholder="Mfano: Muziki, Ufundishaji, Upishi" @blur="upperize(form.spouse, 'skills')" />
          </label>

        </template>

        <!-- ---------- Watoto Wangu: HIARI kwa waliooa/waliolewa, waliofiwa
             (Mjane/Mgane), na waliochika (Talaka). Si lazima kwa yeyote. ---------- -->
        <template v-if="canHaveChildren">

          <div class="subsection-label span-2">
            Watoto Wangu <small>(Hiari)</small>
          </div>

          <label>
            <span>Idadi ya watoto Kwenye familia</span>
            <input v-model="childrenCountModel" type="number" min="0" max="15" />
          </label>

          <div></div>

          <div v-if="form.children.length" class="children-list span-2">
            <div v-for="(child, index) in form.children" :key="index" class="family-member-card">
              <div class="family-member-card-head">
                <span>Mtoto wangu #{{ index + 1 }}</span>
                <button type="button" class="child-remove" title="Ondoa mtoto" @click="removeChild(index)">✕</button>
              </div>
              <div class="family-member-grid">
                <input v-model.trim="child.full_name" placeholder="Jina kamili *" @blur="upperize(child, 'full_name')" />
                <select v-model="child.gender"><option value="">Jinsia</option><option value="Mwanaume">Mwanaume</option><option value="Mwanamke">Mwanamke</option></select>
                <input v-model="child.date_of_birth" type="date" />
                <div class="phone-input-group phone-input-group-sm">
                  <span class="phone-prefix">+255</span>
                  <input
                    :value="extractPhoneDigits(child.phone_number)"
                    @input="updatePhoneField(child, 'phone_number', $event.target.value)"
                    type="tel"
                    inputmode="numeric"
                    maxlength="9"
                    placeholder="7XXXXXXXX (kama ipo)"
                  />
                </div>
                <input v-model.trim="child.email" type="email" placeholder="Barua pepe (hiari)" />
                <input v-model.trim="child.residence" placeholder="Anwani/Makazi" @blur="upperize(child, 'residence')" />
                <div class="subsection-label span-2">Taarifa za Kiroho / Kanisa za Mtoto</div>
                <label><span>Amebatizwa?</span><select v-model="child.is_baptized"><option :value="false">Hapana</option><option :value="true">Ndiyo</option></select></label>
                <template v-if="child.is_baptized">
                  <label><span>Mwaka wa ubatizo</span><input v-model="child.baptism_year" type="number" min="1900" :max="currentYear" /></label>
                  <label><span>Kanisa alikobatizwa</span><input v-model.trim="child.baptism_place" @blur="upperize(child, 'baptism_place')" /></label>
                  <label><span>Ushirika ulipo</span><input v-model.trim="child.church_area" @blur="upperize(child, 'church_area')" /></label>
                </template>
                <label><span>Idara/Kikundi</span><input v-model.trim="child.ministry_group" list="ministry-group-options" @blur="upperize(child, 'ministry_group')" /></label>
                <label><span>Wadhifa</span><select v-model="child.church_role"><option value="">Chagua wadhifa</option><option value="Muumini">Muumini</option><option value="Mshiriki">Mshiriki</option><option value="Kiongozi">Kiongozi</option></select></label>
                <label class="span-2"><span>Mahitaji Maalum</span><input v-model.trim="child.special_needs" placeholder="Mfano: Anahitaji msaada maalum" @blur="upperize(child, 'special_needs')" /></label>
                <div class="subsection-label span-2">Taarifa za Ziada za Mtoto</div>
                <label>
                  <span>Ni MwanaTUCASA?</span>
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

        <!-- ---------- Wanafamilia Wangu Wengine  ---------- -->
        <div class="subsection-label span-2">Wanafamilia Wangu Wengine (siyo mtoto)</div>

        <div v-if="form.family_members.length" class="family-members-list span-2">
          <div v-for="(member, index) in form.family_members" :key="index" class="family-member-card">
            <div class="family-member-card-head">
              <span>Mwanafamilia wangu #{{ index + 1 }}</span>
              <button type="button" class="child-remove" title="Ondoa mwanafamilia" @click="removeFamilyMember(index)">✕</button>
            </div>
            <div class="family-member-grid">
              <input v-model.trim="member.full_name" placeholder="Jina kamili *" @blur="upperize(member, 'full_name')" />
              <input v-model.trim="member.relationship" list="relationship-options" placeholder="Uhusiano na mimi — Mfano: Baba, Kaka" @blur="upperize(member, 'relationship')" />
              <select v-model="member.gender"><option value="">Jinsia</option><option value="Mwanaume">Mwanaume</option><option value="Mwanamke">Mwanamke</option></select>
              <input v-model="member.date_of_birth" type="date" />
              <div class="phone-input-group phone-input-group-sm">
                <span class="phone-prefix">+255</span>
                <input
                  :value="extractPhoneDigits(member.phone_number)"
                  @input="updatePhoneField(member, 'phone_number', $event.target.value)"
                  type="tel"
                  inputmode="numeric"
                  maxlength="9"
                  placeholder="7XXXXXXXX (hiari)"
                />
              </div>
              <input v-model.trim="member.email" type="email" placeholder="Barua pepe (hiari)" />
              <input v-model.trim="member.residence" placeholder="Anwani/Makazi" @blur="upperize(member, 'residence')" />
              <div class="subsection-label span-2">Taarifa za Kiroho / Kanisa za Mwanafamilia</div>
              <label><span>Amebatizwa?</span><select v-model="member.is_baptized"><option :value="false">Hapana</option><option :value="true">Ndiyo</option></select></label>
              <template v-if="member.is_baptized">
                <label><span>Mwaka wa ubatizo</span><input v-model="member.baptism_year" type="number" min="1900" :max="currentYear" /></label>
                <label><span>Kanisa alikobatiziwa</span><input v-model.trim="member.baptism_place" @blur="upperize(member, 'baptism_place')" /></label>
                <label><span>Ushirika ulipo</span><input v-model.trim="member.church_area" @blur="upperize(member, 'church_area')" /></label>
              </template>
              <label><span>Idara/Kikundi</span><input v-model.trim="member.ministry_group" list="ministry-group-options" @blur="upperize(member, 'ministry_group')" /></label>
              <label><span>Wadhifa</span><select v-model="member.church_role"><option value="">Chagua wadhifa</option><option value="Muumini">Muumini</option><option value="Mshiriki">Mshiriki</option><option value="Kiongozi">Kiongozi</option><option value="Mchungaji">Mchungaji</option><option value="Mzee">Mzee</option></select></label>
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
          <option value="Mtoto" />
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
          <span>Mtu wa karibu wa kuwasiliana naye ikiwa sipatikani — Jina</span>
          <input v-model.trim="form.emergency_contact_name" placeholder="Jina la mtu wa dharura" @blur="upperize(form, 'emergency_contact_name')" />
        </label>

        <label>
          <span>Namba ya dharura <b>*</b></span>
          <div class="phone-input-group">
            <span class="phone-prefix">+255</span>
            <input
              :value="extractPhoneDigits(form.emergency_contact_phone)"
              @input="updatePhoneField(form, 'emergency_contact_phone', $event.target.value)"
              type="tel"
              inputmode="numeric"
              maxlength="9"
              required
              placeholder="7XXXXXXXX"
              @blur="validateEmergencyPhone"
            />
          </div>
          <small v-if="emergencyPhoneError" class="field-error">{{ emergencyPhoneError }}</small>
        </label>


        <!-- ================= SEHEMU 4: TAARIFA ZANGU ZA ZIADA ================= -->
        <div class="form-section">
          <span class="form-section-number">4</span>
          <h3>Taarifa Zangu za Ziada</h3>
        </div>

        <label>
          <span>Mimi ni MwanaTUCASA?</span>
          <select v-model="form.is_tucasa_member">
            <option :value="false">Hapana</option>
            <option :value="true">Ndiyo</option>
          </select>
        </label>

        <label v-if="form.is_tucasa_member">
          <span>Chuo ninachosoma</span>
          <input v-model.trim="form.institution_name" placeholder="Mfano: UDSM, NIT, SUA, MUHAS" @blur="upperize(form, 'institution_name')" />
        </label>
        <div v-else></div>

        <label>
          <span>Elimu/Kazi yangu</span>
          <input v-model.trim="form.occupation" placeholder="Mfano: Mwalimu" @blur="upperize(form, 'occupation')" />
        </label>

        <label>
          <span>Vipaji/Mahususi yangu</span>
          <input v-model.trim="form.skills" placeholder="Mfano: Upigaji piano, Ufundishaji, Upishi" @blur="upperize(form, 'skills')" />
        </label>

        <label class="span-2">
          <span>Mahitaji Maalum Yangu</span>
          <input v-model.trim="form.special_needs" placeholder="Mfano: Ninahitaji msaada maalum" @blur="upperize(form, 'special_needs')" />
        </label>


        <!-- ================= ACTIONS ================= -->
        <div class="form-actions span-2">
          <button class="primary-button" type="submit" :disabled="saving">
            {{ myResidentId ? 'Hakiki na Usasishe Taarifa Zangu' : 'Hakiki Taarifa Zangu Kabla ya Kuwasilisha' }}
          </button>
        </div>

      </form>

    </section>

    <!-- =====================================================
         MODAL: HAKIKI TAARIFA ZANGU KABLA YA KUWASILISHA
         Inatokea baada ya fomu kuthibitishwa (validated), kabla
         taarifa halisi hazijatumwa kwenye database. Mtumiaji
         anaweza "Rudi Kuhariri" (bila kupoteza kilichojazwa) au
         "Thibitisha na Uwasilishe" ndipo saveProfile() halisi
         inapoitwa.
    ====================================================== -->
    <div
      v-if="showReviewModal"
      class="review-modal-overlay"
      role="dialog"
      aria-modal="true"
      aria-labelledby="review-modal-title"
    >
      <div class="review-modal">
        <div class="review-modal-header">
          <h2 id="review-modal-title">Hakiki Taarifa Zangu Kabla ya Kuwasilisha</h2>
          <p>Soma kwa makini kila sehemu hapa chini. Ukiona kosa lolote, bonyeza "Rudi Kuhariri" ili kurekebisha kabla ya kuwasilisha rasmi.</p>
        </div>

        <div class="review-modal-body">
          <div v-for="section in reviewSections" :key="section.title" class="review-section">
            <h3>{{ section.title }}</h3>
            <dl>
              <template v-for="row in section.rows" :key="row.label">
                <dt>{{ row.label }}</dt>
                <dd>{{ row.value }}</dd>
              </template>
            </dl>
          </div>
        </div>

        <div class="review-modal-actions">
          <button type="button" class="secondary-button" :disabled="saving" @click="closeReviewModal">
            Rudi Kuhariri
          </button>
          <button type="button" class="primary-button" :disabled="saving" @click="confirmAndSave">
            {{ saving ? 'Inahifadhi…' : 'Thibitisha na Uwasilishe' }}
          </button>
        </div>
      </div>
    </div>

  </main>
</template>


<script setup>

import {
  computed,
  onBeforeUnmount,
  onMounted,
  reactive,
  ref,
  watch,
} from 'vue'

import { supabase } from '../lib/supabase'
import logo from '../assets/logo.png'

const props = defineProps({
  session: { type: Object, default: null },
  guestMode: { type: Boolean, default: false },
})

defineEmits(['logged-out'])

const loading = ref(true)
const saving = ref(false)
const error = ref('')
const message = ref('')
const myResidentId = ref(null)
const guestLookupDone = ref(false) // huzuia lookup kurudiwa mara kwa mara guest anapoendelea kujaza

// Modal ya "Hakiki Taarifa Zangu Kabla ya Kuwasilisha"
const showReviewModal = ref(false)
const reviewPayload = ref(null) // payload iliyokwisha-safishwa (cleaned), tayari kutumwa saveProfile() ikithibitishwa

// Onyo la "jina linalofanana tayari limesajiliwa" (guest mode)
const nameDuplicateInfo = ref(null) // { exists, count, phone_hint } kutoka check_name_duplicate()
const nameDuplicateDismissed = ref(false)
const nameConfirmedSelf = ref(false)
const nameCheckedFor = ref('') // jina lililoangaliwa mara ya mwisho, huzuia maombi ya server kwa jina lilelile

// Inaonyesha ukurasa wa "Ahsante kwa ushirikiano" mara tu taarifa
// zinapohifadhiwa kwa mafanikio, badala ya fomu.
const submittedSuccess = ref(false)

// Inaonyesha kama fomu hii imejazwa upya kutoka kwa taarifa
// zilizohifadhiwa kwenye kifaa chake (draft), baada ya kufunga tab
// kwa bahati mbaya wakati alikuwa bado hajawasilisha.
const draftRestored = ref(false)

const currentYear = new Date().getFullYear()

const MARITAL_STATUS_LABELS = {
  'Hajaoa/Hajaolewa': 'Sijaoa/Sijaolewa',
  'Ameoa/Ameolewa': 'Nimeoa/Nimeolewa',
  Mjane: 'Nimefiwa (Mjane)',
  Mgane: 'Nimefiwa (Mgane)',
  Talaka: 'Nimeachika (Talaka)',
}

function toUpper(value) {
  return typeof value === 'string' && value ? value.toUpperCase() : value
}

function upperize(target, key) {
  if (typeof target[key] === 'string' && target[key]) {
    target[key] = target[key].toUpperCase()
  }
}

function yesNo(value) {
  return value ? 'Ndiyo' : 'Hapana'
}

const emptySpouse = () => ({
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
})

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
  spouse: emptySpouse(),
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

/* Mjane (bereaved, female), Mgane (bereaved, male) na Talaka (divorced)
   wote wanaweza kuwa na watoto tayari, hata kama hawana mwenzi kwa sasa.
   Hivyo sehemu ya "Watoto Wangu" inaonekana (kama HIARI) kwa hali zote
   hizi, si tu kwa walioolewa/walioa. */
const isWidowedOrDivorced = computed(() =>
  ['Mjane', 'Mgane', 'Talaka'].includes(form.marital_status),
)

const canHaveChildren = computed(() => isMarried.value || isWidowedOrDivorced.value)

const nameDuplicateMessage = computed(() => {
  if (!nameDuplicateInfo.value) return ''
  const hint = nameDuplicateInfo.value.phone_hint
  return hint
    ? `Tumeona kuna tayari mshiriki aliyesajiliwa kwa jina hili (namba ya simu inaishia na ${hint}). Je, huyu ni wewe?`
    : 'Tumeona kuna tayari mshiriki aliyesajiliwa kwa jina hili. Je, huyu ni wewe?'
})

// Jina likibadilika, onyo la awali halihitajiki tena — anza upya.
watch(() => form.full_name, (value, oldValue) => {
  if (value === oldValue) return
  nameDuplicateDismissed.value = false
  nameConfirmedSelf.value = false
})

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
)

/* =========================================================
   PHONE / EMAIL / RESIDENCE VALIDATION
   ========================================================= */

const PHONE_PREFIX = '+255'
const PHONE_REGEX = /^[67]\d{8}$/ // Tanzania: tarakimu 9, huanza na 6 au 7
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

const phoneError = ref('')
const emailError = ref('')
const residenceError = ref('')
const spousePhoneError = ref('')
const spouseEmailError = ref('')
const emergencyPhoneError = ref('')

function extractPhoneDigits(raw) {
  const value = raw || ''
  let digits = value.startsWith(PHONE_PREFIX)
    ? value.slice(PHONE_PREFIX.length)
    : value.replace(/\D/g, '')

  if (digits.startsWith('255')) digits = digits.slice(3)
  if (digits.startsWith('0')) digits = digits.slice(1)

  return digits.replace(/\D/g, '').slice(0, 9)
}

function formatPhoneFromDigits(digits) {
  const clean = String(digits || '').replace(/\D/g, '').slice(0, 9)
  return clean ? `${PHONE_PREFIX}${clean}` : ''
}

function updatePhoneField(target, key, rawValue) {
  target[key] = formatPhoneFromDigits(extractPhoneDigits(rawValue))
}

function isValidPhoneDigits(digits) {
  return PHONE_REGEX.test(digits || '')
}

function isValidEmail(value) {
  return EMAIL_REGEX.test((value || '').trim())
}

function validatePhone() {
  const digits = extractPhoneDigits(form.phone_number)

  if (!digits) {
    phoneError.value = 'Namba yangu ya simu inahitajika.'
    return false
  }

  if (!isValidPhoneDigits(digits)) {
    phoneError.value = 'Ingiza namba sahihi ya simu (tarakimu 9, mfano: 712345678).'
    return false
  }

  phoneError.value = ''
  return true
}

function validateSpousePhone() {
  if (!isMarried.value) {
    spousePhoneError.value = ''
    return true
  }

  const digits = extractPhoneDigits(form.spouse.phone_number)

  if (!digits) {
    spousePhoneError.value = 'Namba ya simu ya mwenzi wangu inahitajika.'
    return false
  }

  if (!isValidPhoneDigits(digits)) {
    spousePhoneError.value = 'Ingiza namba sahihi ya simu ya mwenzi wangu (tarakimu 9, mfano: 712345678).'
    return false
  }

  spousePhoneError.value = ''
  return true
}

function validateEmergencyPhone() {
  const digits = extractPhoneDigits(form.emergency_contact_phone)

  if (!digits) {
    emergencyPhoneError.value = 'Namba ya dharura ni lazima.'
    return false
  }

  if (!isValidPhoneDigits(digits)) {
    emergencyPhoneError.value = 'Ingiza namba sahihi ya dharura (tarakimu 9, mfano: 712345678).'
    return false
  }

  emergencyPhoneError.value = ''
  return true
}

function validateEmail() {
  const value = (form.email || '').trim()

  if (!value) {
    emailError.value = 'Barua pepe yangu inahitajika.'
    return false
  }

  if (!isValidEmail(value)) {
    emailError.value = 'Ingiza barua pepe sahihi (mfano: jina@mfano.com).'
    return false
  }

  emailError.value = ''
  tryLoadExistingGuestRecord()
  return true
}

function validateSpouseEmail() {
  if (!isMarried.value) {
    spouseEmailError.value = ''
    return true
  }

  const value = (form.spouse.email || '').trim()

  if (!value) {
    spouseEmailError.value = 'Barua pepe ya mwenzi wangu inahitajika.'
    return false
  }

  if (!isValidEmail(value)) {
    spouseEmailError.value = 'Ingiza barua pepe sahihi ya mwenzi wangu (mfano: jina@mfano.com).'
    return false
  }

  spouseEmailError.value = ''
  return true
}

function validateResidence() {
  const value = (form.residence || '').trim()

  if (!value) {
    residenceError.value = 'Mahali ninapoishi ni lazima.'
    return false
  }

  residenceError.value = ''
  return true
}

// Inaendesha uthibitisho (validation) wa nyanja zote muhimu kwa mara moja —
// inatumika kabla ya kufungua modal ya "Hakiki Taarifa Zangu".
function validateAllFields() {
  const phoneOk = validatePhone()
  const emailOk = validateEmail()
  const residenceOk = validateResidence()
  const emergencyPhoneOk = validateEmergencyPhone()
  const spousePhoneOk = validateSpousePhone()
  const spouseEmailOk = validateSpouseEmail()

  return phoneOk && emailOk && residenceOk && emergencyPhoneOk && spousePhoneOk && spouseEmailOk
}

/* =========================================================
   CLEAN HELPERS (bila kuunganisha kwenye rows nyingine —
   familia yangu inahifadhiwa kama JSON ndani ya rekodi yangu)
   ========================================================= */

function cleanChild(child) {
  const baptized = !!child.is_baptized

  return {
    full_name: toUpper((child.full_name || '').trim()),
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
  }
}

function cleanSpouse(spouse) {
  if (!spouse?.full_name) return null

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

/* =========================================================
   WATOTO / WANAFAMILIA HELPERS
   ========================================================= */

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
   PAKIA TAARIFA ZANGU ZILIZOPO (KAMA NIPO TAYARI NIMESAJILI)
   ========================================================= */

function fillForm(resident) {
  form.full_name = resident.full_name || ''
  form.gender = resident.gender || ''
  form.date_of_birth = resident.date_of_birth || ''
  form.marital_status = resident.marital_status || ''
  form.phone_number = resident.phone_number || ''
  form.email = resident.email || ''
  form.residence = resident.residence || ''
  form.is_baptized = !!resident.is_baptized
  form.baptism_year = resident.baptism_year || ''
  form.baptism_place = resident.baptism_place || ''
  form.church_area = resident.church_area || ''
  form.ministry_group = resident.ministry_group || ''
  form.church_role = resident.church_role || ''

  const spouse = resident.spouse && typeof resident.spouse === 'object'
    ? resident.spouse
    : {}

  form.spouse = {
    full_name: spouse.full_name || '',
    gender: spouse.gender || '',
    date_of_birth: spouse.date_of_birth || '',
    phone_number: spouse.phone_number || '',
    email: spouse.email || '',
    is_baptized: !!spouse.is_baptized,
    baptism_year: spouse.baptism_year || '',
    baptism_place: spouse.baptism_place || '',
    church_area: spouse.church_area || '',
    ministry_group: spouse.ministry_group || '',
    church_role: spouse.church_role || '',
    special_needs: spouse.special_needs || '',
    is_tucasa_member: !!spouse.is_tucasa_member,
    institution_name: spouse.institution_name || '',
    occupation: spouse.occupation || '',
    skills: spouse.skills || '',
  }

  form.children = Array.isArray(resident.children)
    ? resident.children.map((child) => ({
        full_name: child.full_name || '',
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

  form.family_members = Array.isArray(resident.family_members)
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

  form.emergency_contact_name = resident.emergency_contact_name || ''
  form.emergency_contact_phone = resident.emergency_contact_phone || ''
  form.is_tucasa_member = !!resident.is_tucasa_member
  form.institution_name = resident.institution_name || ''
  form.occupation = resident.occupation || ''
  form.skills = resident.skills || ''
  form.special_needs = resident.special_needs || ''
}

async function loadMyProfile() {
  if (props.guestMode || !props.session?.user?.id) {
    loading.value = false
    return
  }

  loading.value = true
  error.value = ''

  const { data, error: loadError } = await supabase
    .from('residents')
    .select('*')
    .eq('user_id', props.session.user.id)
    .maybeSingle()

  loading.value = false

  if (loadError) {
    error.value = loadError.message
    return
  }

  if (data) {
    myResidentId.value = data.id
    fillForm(data)
  } else if (!form.email) {
    // Akaunti mpya: anza na email aliyotumia kujisajili.
    form.email = props.session.user.email || ''
  }
}

/* =========================================================
   "DRAFT" YA MUDA (LOCAL, KWENYE KIFAA CHENYEWE) — KWA
   MSHIRIKI WA KAWAIDA (GUEST, BILA LOGIN) PEKEE.

   Kusudi: kama mtu amefunga tab kwa bahati mbaya wakati bado
   akijaza fomu (kabla ya kuwasilisha), taarifa alizokwisha jaza
   zisipotee — badala ya kuanza upya tangu mwanzo, tunamrudishia
   alichokuwa akijaza pale atakaporudi kwenye kivinjari kilekile.

   MUHIMU: hii HAIHIFADHI chochote kwenye database/seva — ni
   localStorage ya kivinjari chake tu, na inafutwa mara taarifa
   zikiwasilishwa kwa mafanikio, au akichagua "Usajili Mpya" /
   "Futa Nilichokuwa Nikijaza".
   ========================================================= */

const DRAFT_STORAGE_KEY = 'golani_member_profile_draft_v1'
const DRAFT_MAX_AGE_MS = 7 * 24 * 60 * 60 * 1000 // siku 7

function hasMeaningfulDraftData(source) {
  if (!source) return false
  return !!(
    (source.full_name && source.full_name.trim()) ||
    (source.phone_number && source.phone_number.trim()) ||
    (source.email && source.email.trim())
  )
}

function loadDraftFromStorage() {
  if (typeof window === 'undefined' || !window.localStorage) return null

  try {
    const raw = window.localStorage.getItem(DRAFT_STORAGE_KEY)
    if (!raw) return null

    const parsed = JSON.parse(raw)
    if (!parsed || typeof parsed !== 'object' || !parsed.form) return null

    if (parsed.savedAt && Date.now() - parsed.savedAt > DRAFT_MAX_AGE_MS) {
      window.localStorage.removeItem(DRAFT_STORAGE_KEY)
      return null
    }

    return parsed.form
  } catch (err) {
    console.error('Imeshindikana kusoma taarifa zilizohifadhiwa awali (draft):', err)
    return null
  }
}

function saveDraftToStorage() {
  if (!props.guestMode || submittedSuccess.value) return

  if (!hasMeaningfulDraftData(form)) {
    clearDraftFromStorage()
    return
  }

  if (typeof window === 'undefined' || !window.localStorage) return

  try {
    window.localStorage.setItem(
      DRAFT_STORAGE_KEY,
      JSON.stringify({ savedAt: Date.now(), form }),
    )
  } catch (err) {
    console.error('Imeshindikana kuhifadhi taarifa za muda (draft):', err)
  }
}

function clearDraftFromStorage() {
  if (typeof window === 'undefined' || !window.localStorage) return

  try {
    window.localStorage.removeItem(DRAFT_STORAGE_KEY)
  } catch (err) {
    // haina madhara kama kifaa hakiruhusu localStorage
  }
}

function restoreDraftIfAny() {
  if (!props.guestMode) return

  const draft = loadDraftFromStorage()
  if (!hasMeaningfulDraftData(draft)) return

  Object.assign(form, emptyForm(), draft)

  draftRestored.value = true
  message.value = 'Endelea Ulipoishia.'
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

function discardDraftAndReset() {
  clearDraftFromStorage()
  startNewRegistration()
}

let draftSaveTimer = null

// Kila mara fomu inapobadilika, tunahifadhi "draft" baada ya sekunde
// chache za utulivu (debounce) — si kwa kila herufi anayoandika.
watch(
  form,
  () => {
    if (!props.guestMode) return
    if (draftSaveTimer) clearTimeout(draftSaveTimer)
    draftSaveTimer = setTimeout(saveDraftToStorage, 600)
  },
  { deep: true },
)

onBeforeUnmount(() => {
  if (draftSaveTimer) clearTimeout(draftSaveTimer)
})

onMounted(() => {
  restoreDraftIfAny()
  loadMyProfile()
})

/* =========================================================
   MSHIRIKI WA KAWAIDA (GUEST, BILA LOGIN): TAFUTA TAARIFA
   ZANGU ZA AWALI KWA PHONE + EMAIL, ILI NISIJITENGENEZEE
   DUPLICATE NIKIJAZA TENA.
   ========================================================= */

async function tryLoadExistingGuestRecord() {
  if (!props.guestMode || guestLookupDone.value) return

  const phoneDigits = extractPhoneDigits(form.phone_number)
  if (!isValidPhoneDigits(phoneDigits) || !isValidEmail(form.email)) return

  guestLookupDone.value = true // jaribu mara moja tu kwa kikao hiki

  const { data, error: lookupError } = await supabase.rpc('lookup_public_member', {
    p_phone: form.phone_number,
    p_email: form.email,
  })

  if (lookupError) {
    console.error('Imeshindikana kuangalia taarifa zilizosajiliwa awali:', lookupError.message)
    return
  }

  if (data) {
    myResidentId.value = data.id
    fillForm(data)
    message.value = 'Tumekuta taarifa zako zilizosajiliwa awali — tumezijaza hapa chini. Hariri kinachohitaji kubadilika kisha ubonyeze "Sasisha Taarifa Zangu".'
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
}

/* =========================================================
   MSHIRIKI WA KAWAIDA (GUEST): ONYA KAMA JINA LINALOFANANA
   TAYARI LIMESAJILIWA.

   TOFAUTI NA tryLoadExistingGuestRecord() (juu): hii HAIPAKUI
   taarifa za mtu — jina peke yake si la kutosha/salama kutumika
   kama uthibitisho wa utambulisho (watu tofauti wanaweza kufanana
   majina, na jina ni rahisi kulijua/kulibashiri). Badala yake
   tunamwuliza tu "je, huyu ni wewe?" — akisema ndiyo, anaelekezwa
   kujaza namba+email yake ili tryLoadExistingGuestRecord() ndiyo
   ipakue taarifa zake halisi kwa njia salama iliyopo tayari.
   ========================================================= */

async function checkNameDuplicate() {
  if (!props.guestMode || myResidentId.value) return

  const name = (form.full_name || '').trim()
  if (name.length < 3 || name === nameCheckedFor.value) return

  nameCheckedFor.value = name

  const { data, error: checkError } = await supabase.rpc('check_name_duplicate', {
    p_full_name: name,
  })

  if (checkError) {
    console.error('Imeshindikana kuangalia jina linalofanana:', checkError.message)
    return
  }

  nameDuplicateInfo.value = data?.exists ? data : null
}

function dismissNameDuplicate() {
  nameDuplicateDismissed.value = true
}

/* =========================================================
   USAJILI MPYA — kutoka ukurasa wa "Ahsante kwa ushirikiano",
   inarudisha fomu kwenye hali yake ya awali (tupu) ili
   aweze kujaza taarifa za mtu mwingine.
   ========================================================= */

function startNewRegistration() {
  Object.assign(form, emptyForm())

  myResidentId.value = null
  guestLookupDone.value = false

  nameDuplicateInfo.value = null
  nameDuplicateDismissed.value = false
  nameConfirmedSelf.value = false
  nameCheckedFor.value = ''

  phoneError.value = ''
  emailError.value = ''
  residenceError.value = ''
  spousePhoneError.value = ''
  spouseEmailError.value = ''
  emergencyPhoneError.value = ''

  reviewPayload.value = null
  showReviewModal.value = false

  message.value = ''
  error.value = ''
  submittedSuccess.value = false

  draftRestored.value = false
  clearDraftFromStorage()
}

/* =========================================================
   TENGENEZA PAYLOAD (bila kuihifadhi) — inatumika kwenye
   hatua ya "Hakiki Taarifa Zangu" na pia kwenye kuwasilisha
   halisi, ili zote mbili zitumie chanzo kimoja cha ukweli.
   ========================================================= */

function buildPayload() {
  const married = isMarried.value
  const childrenAllowed = canHaveChildren.value
  const student = form.is_tucasa_member
  const baptized = form.is_baptized

  return {
    full_name: toUpper((form.full_name || '').trim()),
    gender: form.gender,
    date_of_birth: form.date_of_birth || null,
    marital_status: form.marital_status || null,
    phone_number: form.phone_number || null,
    email: (form.email || '').trim() || null,
    residence: toUpper((form.residence || '').trim()) || null,

    is_baptized: baptized,
    baptism_year: baptized && form.baptism_year ? Number(form.baptism_year) : null,
    baptism_place: baptized ? (toUpper((form.baptism_place || '').trim()) || null) : null,
    church_area: baptized ? (toUpper((form.church_area || '').trim()) || null) : null,
    ministry_group: toUpper((form.ministry_group || '').trim()) || null,
    church_role: form.church_role || null,

    spouse: married ? cleanSpouse(form.spouse) : null,
    children: childrenAllowed ? form.children.map(cleanChild).filter((child) => child.full_name) : [],
    family_members: cleanFamilyMembers(form.family_members),
    emergency_contact_name: toUpper((form.emergency_contact_name || '').trim()) || null,
    emergency_contact_phone: form.emergency_contact_phone || null,

    is_tucasa_member: student,
    institution_name: student ? (toUpper((form.institution_name || '').trim()) || null) : null,
    occupation: toUpper((form.occupation || '').trim()) || null,
    skills: toUpper((form.skills || '').trim()) || null,
    special_needs: toUpper((form.special_needs || '').trim()) || null,
  }
}

/* =========================================================
   HAKIKI TAARIFA ZANGU (modal) — hufunguliwa fomu ikiwasilishwa,
   BADALA ya kutuma taarifa moja kwa moja kwenye database.
   ========================================================= */

function openReviewModal() {
  error.value = ''
  message.value = ''

  const payload = buildPayload()

  if (!payload.full_name || !payload.gender) {
    error.value = 'Jina langu kamili na jinsia yangu ni lazima.'
    return
  }

  if (!validateAllFields()) {
    error.value = 'Tafadhali nisahihishe taarifa zilizoangaziwa kwa nyekundu kabla ya kuendelea.'
    return
  }

  reviewPayload.value = payload
  showReviewModal.value = true
}

function closeReviewModal() {
  showReviewModal.value = false
}

async function confirmAndSave() {
  if (!reviewPayload.value) return
  await saveProfile(reviewPayload.value)
}

// Muhtasari wa taarifa zinazoonyeshwa kwenye modal ya "Hakiki Taarifa
// Zangu" — huundwa kutoka kwa payload ile ile itakayotumwa, ili
// kinachoonekana ndicho hasa kitakachohifadhiwa. Nyanja tupu (null/'')
// huondolewa ili modal isijae mistari isiyo na maana.
const reviewSections = computed(() => {
  const p = reviewPayload.value
  if (!p) return []

  const sections = []

  sections.push({
    title: 'Taarifa Zangu Binafsi',
    rows: [
      { label: 'Jina langu kamili', value: p.full_name },
      { label: 'Jinsia yangu', value: p.gender },
      { label: 'Tarehe ya kuzaliwa', value: p.date_of_birth },
      { label: 'Hali yangu ya ndoa', value: MARITAL_STATUS_LABELS[p.marital_status] || p.marital_status },
      { label: 'Namba yangu ya simu', value: p.phone_number },
      { label: 'Barua pepe yangu', value: p.email },
      { label: 'Anwani/Makazi yangu', value: p.residence },
    ],
  })

  const spiritualRows = [{ label: 'Nimebatizwa?', value: yesNo(p.is_baptized) }]
  if (p.is_baptized) {
    spiritualRows.push(
      { label: 'Mwaka wangu wa ubatizo', value: p.baptism_year },
      { label: 'Kanisa nilipobatizwa', value: p.baptism_place },
      { label: 'Ushirika wangu ulipo', value: p.church_area },
    )
  }
  spiritualRows.push(
    { label: 'Idara/Kikundi nilichopo', value: p.ministry_group },
    { label: 'Wadhifa wangu', value: p.church_role },
  )
  sections.push({ title: 'Taarifa Zangu za Kiroho / Kanisa', rows: spiritualRows })

  if (p.spouse) {
    const s = p.spouse
    const spouseRows = [
      { label: 'Jina kamili', value: s.full_name },
      { label: 'Jinsia', value: s.gender },
      { label: 'Tarehe ya kuzaliwa', value: s.date_of_birth },
      { label: 'Namba ya simu', value: s.phone_number },
      { label: 'Barua pepe', value: s.email },
      { label: 'Amebatizwa?', value: yesNo(s.is_baptized) },
    ]
    if (s.is_baptized) {
      spouseRows.push(
        { label: 'Mwaka wa ubatizo', value: s.baptism_year },
        { label: 'Alipobatizwa', value: s.baptism_place },
        { label: 'Ushirika ulipo', value: s.church_area },
      )
    }
    spouseRows.push(
      { label: 'Idara/Kikundi', value: s.ministry_group },
      { label: 'Wadhifa', value: s.church_role },
      { label: 'Elimu/Kazi', value: s.occupation },
      { label: 'Vipaji/Mahususi', value: s.skills },
      { label: 'Mahitaji Maalum', value: s.special_needs },
    )
    sections.push({ title: 'Mwenzi Wangu', rows: spouseRows })
  }

  p.children.forEach((child, index) => {
    sections.push({
      title: `Mtoto wangu #${index + 1}`,
      rows: [
        { label: 'Jina', value: child.full_name },
        { label: 'Jinsia', value: child.gender },
        { label: 'Tarehe ya kuzaliwa', value: child.date_of_birth },
        { label: 'Namba ya simu', value: child.phone_number },
        { label: 'Amebatizwa?', value: yesNo(child.is_baptized) },
        { label: 'Mahitaji Maalum', value: child.special_needs },
      ],
    })
  })

  p.family_members.forEach((member, index) => {
    sections.push({
      title: `Mwanafamilia wangu #${index + 1}`,
      rows: [
        { label: 'Jina', value: member.full_name },
        { label: 'Uhusiano nami', value: member.relationship },
        { label: 'Jinsia', value: member.gender },
        { label: 'Namba ya simu', value: member.phone_number },
        { label: 'Mahitaji Maalum', value: member.special_needs },
      ],
    })
  })

  sections.push({
    title: 'Mawasiliano ya Dharura',
    rows: [
      { label: 'Jina la mtu wa dharura', value: p.emergency_contact_name },
      { label: 'Namba ya dharura', value: p.emergency_contact_phone },
    ],
  })

  sections.push({
    title: 'Taarifa Zangu za Ziada',
    rows: [
      { label: 'Ni MwanaTUCASA?', value: yesNo(p.is_tucasa_member) },
      { label: 'Chuo ninachosoma', value: p.is_tucasa_member ? p.institution_name : null },
      { label: 'Elimu/Kazi yangu', value: p.occupation },
      { label: 'Vipaji/Mahususi yangu', value: p.skills },
      { label: 'Mahitaji Maalum Yangu', value: p.special_needs },
    ],
  })

  return sections
    .map((section) => ({
      ...section,
      rows: section.rows.filter((row) => row.value !== null && row.value !== undefined && row.value !== ''),
    }))
    .filter((section) => section.rows.length)
})

/* =========================================================
   HIFADHI TAARIFA ZANGU (inaitwa TU baada ya "Thibitisha na
   Uwasilishe" kwenye modal ya hakiki)
   ========================================================= */

async function saveProfile(payload) {
  error.value = ''
  message.value = ''
  saving.value = true

  try {
    // Mshiriki wa kawaida (guest, bila akaunti): tunatumia function ya
    // Supabase register_public_member(), ambayo yenyewe hukagua kama
    // tayari kuna rekodi na phone+email hiyo hiyo — ikiwa ipo, inai-UPDATE
    // badala ya kuunda duplicate mpya.
    if (props.guestMode) {
      const { data, error: rpcError } = await supabase.rpc('register_public_member', {
        p: payload,
      })

      if (rpcError) {
        error.value = rpcError.message
        return
      }

      myResidentId.value = data.id
      message.value = data.was_update
        ? 'Taarifa zako zimesasishwa'
        : 'Hongera! Taarifa zako zimehifadhiwa.'

      submittedSuccess.value = true
      clearDraftFromStorage()
      window.scrollTo({ top: 0, behavior: 'smooth' })
      return
    }

    if (myResidentId.value) {
      const { error: updateError } = await supabase
        .from('residents')
        .update(payload)
        .eq('id', myResidentId.value)
        .eq('user_id', props.session.user.id)

      if (updateError) {
        error.value = updateError.message
        return
      }

      message.value = 'Taarifa zangu zimesasishwa.'
      submittedSuccess.value = true
    } else {
      const { data, error: insertError } = await supabase
        .from('residents')
        .insert({
          ...payload,
          user_id: props.session.user.id,
          registered_by: props.session.user.id,
        })
        .select('*')
        .single()

      if (insertError) {
        error.value = insertError.message
        return
      }

      myResidentId.value = data.id
      message.value = 'Taarifa zangu zimehifadhiwa.'
      submittedSuccess.value = true
    }
  } catch (err) {
    error.value = err?.message || 'Hitilafu imetokea. Jaribu tena.'
  } finally {
    saving.value = false
    showReviewModal.value = false
  }
}

</script>

<style scoped>
/* =========================================================
   THEME TOKENS — navy + gold, matched to the church site
   ========================================================= */
.dashboard {
  --navy-950: #071527;
  --navy-900: #0d2137;
  --navy-800: #16324a;
  --gold-500: #c9a227;
  --gold-400: #e0b93a;
  --gold-100: #fdf3d7;
  --border-soft: rgba(13, 33, 55, 0.09);
  --shadow-soft: 0 10px 30px rgba(13, 33, 55, 0.08);
  --shadow-lift: 0 18px 40px rgba(13, 33, 55, 0.16);

  min-height: 100vh;
  padding: 28px 32px 60px;
  background:
    radial-gradient(1100px 480px at 12% -10%, rgba(201, 162, 39, 0.10), transparent 60%),
    radial-gradient(900px 500px at 100% 0%, rgba(13, 33, 55, 0.08), transparent 55%),
    linear-gradient(180deg, #eef2f7 0%, #f5f7fb 40%, #f7f8fb 100%);
  color: #0d2137;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

/* =========================================================
   TOPBAR
   ========================================================= */
.topbar {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex-wrap: wrap;
  gap: 18px;
  padding: 26px 28px;
  margin-bottom: 28px;
  border-radius: 20px;
  position: relative;
  overflow: hidden;
  background: linear-gradient(135deg, #0a1c30 0%, #0d2137 45%, #123253 100%);
  box-shadow: var(--shadow-lift);
  border: 1px solid rgba(255, 255, 255, 0.06);
}

.topbar::before {
  content: '';
  position: absolute;
  inset: 0;
  background:
    radial-gradient(420px 220px at 15% 0%, rgba(201, 162, 39, 0.25), transparent 65%),
    radial-gradient(360px 220px at 100% 100%, rgba(255, 255, 255, 0.06), transparent 60%);
  pointer-events: none;
}

.brand-area {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  gap: 14px;
  position: relative;
  z-index: 1;
}

.brand-logo { width: 40px; height: 40px; border-radius: 50%; background: #0d2137; display: flex; align-items: center; justify-content: center; overflow: hidden; } .brand-logo img { width: 40px; height: 40px; object-fit: contain; }

.eyebrow {
  margin: 0 0 2px;
  background: linear-gradient(90deg, var(--gold-400), #f3d778 60%, var(--gold-400));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.topbar h1 {
  margin: 0;
  font-size: 21px;
  font-weight: 800;
  color: #fff;
  letter-spacing: -0.01em;
}

.brand-subtitle {
  margin: 2px 0 0;
  color: rgba(255, 255, 255, 0.75);
  font-size: 13px;
}

.topbar-actions {
  display: flex;
  align-items: center;
  align-self: flex-end;
  gap: 14px;
  position: relative;
  z-index: 1;
}

.admin-info {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  font-size: 12px;
}

.admin-label {
  color: rgba(255, 255, 255, 0.65);
}

.admin-email {
  font-weight: 700;
  color: #fff;
}

.ghost-button {
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.25);
  color: #fff;
  padding: 9px 18px;
  border-radius: 10px;
  font-weight: 700;
  font-size: 13px;
  cursor: pointer;
  backdrop-filter: blur(4px);
  transition: all 0.25s ease;
}

.ghost-button:hover {
  background: rgba(255, 255, 255, 0.16);
  border-color: rgba(255, 255, 255, 0.4);
  transform: translateY(-1px);
}

/* =========================================================
   BUTTONS
   ========================================================= */
.primary-button,
.secondary-button {
  padding: 12px 22px;
  border-radius: 12px;
  font-weight: 800;
  font-size: 14px;
  cursor: pointer;
  border: 1px solid transparent;
  transition: transform 0.2s ease, box-shadow 0.25s ease, background 0.25s ease, border-color 0.25s ease, color 0.25s ease;
}

.primary-button {
  background: linear-gradient(135deg, #123253 0%, #0d2137 55%, #071527 100%);
  border-color: #0d2137;
  color: #fff;
  box-shadow: 0 10px 22px rgba(13, 33, 55, 0.28);
}

.primary-button:hover:not(:disabled) {
  background: linear-gradient(135deg, #16324a 0%, #0d2137 55%, #071527 100%);
  transform: translateY(-2px);
  box-shadow: 0 16px 30px rgba(13, 33, 55, 0.34), 0 0 0 3px rgba(201, 162, 39, 0.18);
}

.primary-button:active:not(:disabled) {
  transform: translateY(0);
}

.primary-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  box-shadow: none;
}

.secondary-button {
  background: #fff;
  border-color: #d5dce5;
  color: #0d2137;
}

.secondary-button:hover:not(:disabled) {
  border-color: var(--gold-500);
  color: #0d2137;
  background: linear-gradient(0deg, #fffaf0, #ffffff);
  transform: translateY(-1px);
  box-shadow: 0 8px 18px rgba(201, 162, 39, 0.18);
}

/* =========================================================
   PANEL / CARD
   ========================================================= */
.panel {
  background: #fff;
  border: 1px solid var(--border-soft);
  border-radius: 20px;
  padding: 30px;
  box-shadow: var(--shadow-soft);
  transition: box-shadow 0.35s ease;
}

.panel:hover {
  box-shadow: var(--shadow-lift);
}

.muted-line {
  color: #667085;
  font-size: 14px;
}

.panel-heading {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 22px;
  padding-bottom: 18px;
  border-bottom: 1px solid var(--border-soft);
}

.section-title {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.section-title-icon {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  background: linear-gradient(135deg, #123253, #0d2137);
  color: var(--gold-400);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  flex: 0 0 auto;
  box-shadow: 0 6px 14px rgba(13, 33, 55, 0.28);
}

.panel-heading h2 {
  margin: 0 0 4px;
  font-size: 19px;
  font-weight: 800;
}

.panel-heading p {
  margin: 0;
  color: #667085;
  font-size: 13px;
}

/* =========================================================
   FORM GRID / FIELDS
   ========================================================= */
.resident-form {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 18px 20px;
}

.span-2 {
  grid-column: span 2;
}

.resident-form label {
  display: flex;
  flex-direction: column;
  gap: 7px;
  font-size: 13px;
  font-weight: 700;
  color: #0d2137;
}

.resident-form label b {
  color: #b42318;
}

.resident-form input,
.resident-form select {
  height: 44px;
  padding: 0 13px;
  border: 1.5px solid #dde3ec;
  border-radius: 10px;
  font-size: 14px;
  color: #0d2137;
  background: #fbfcfe;
  outline: none;
  transition: border-color 0.2s ease, box-shadow 0.2s ease, background 0.2s ease;
}

.resident-form input:hover,
.resident-form select:hover {
  border-color: #b9c3d1;
}

.resident-form input:focus,
.resident-form select:focus {
  border-color: var(--gold-500);
  background: #fff;
  box-shadow: 0 0 0 4px rgba(201, 162, 39, 0.16);
}

.resident-form select:disabled {
  background: #f2f4f7;
  color: #98a2b3;
}

/* =========================================================
   SECTION HEADERS
   ========================================================= */
.form-section {
  grid-column: span 2;
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px dashed rgba(13, 33, 55, 0.14);
}

.form-section:first-of-type {
  margin-top: 0;
  padding-top: 0;
  border-top: none;
}

.form-section-number {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--gold-400), var(--gold-500));
  color: #0d2137;
  font-size: 12px;
  font-weight: 900;
  display: flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
  box-shadow: 0 6px 14px rgba(201, 162, 39, 0.35);
}

.form-section h3 {
  margin: 0;
  font-size: 15px;
  font-weight: 800;
  background: linear-gradient(90deg, #0d2137, #16324a);
  -webkit-background-clip: text;
  background-clip: text;
}

.form-section-hint {
  margin-left: auto;
  font-size: 11px;
  font-weight: 700;
  color: #98a2b3;
  text-transform: uppercase;
}

.field-hint {
  color: #98a2b3;
  font-size: 11px;
}

/* =========================================================
   PHONE INPUT
   ========================================================= */
.phone-input-group {
  display: flex;
  align-items: center;
  border: 1.5px solid #dde3ec;
  border-radius: 10px;
  overflow: hidden;
  height: 44px;
  background: #fbfcfe;
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
}

.phone-input-group:hover {
  border-color: #b9c3d1;
}

.phone-input-group:focus-within {
  border-color: var(--gold-500);
  box-shadow: 0 0 0 4px rgba(201, 162, 39, 0.16);
}

.phone-prefix {
  padding: 0 11px;
  background: linear-gradient(135deg, #0d2137, #123253);
  color: var(--gold-400);
  font-size: 13px;
  font-weight: 800;
  height: 100%;
  display: flex;
  align-items: center;
  border-right: 1px solid #0d2137;
}

.phone-input-group input {
  border: none;
  height: 100%;
  flex: 1;
  background: transparent;
}

.phone-input-group input:focus {
  box-shadow: none;
}

.phone-input-group-sm {
  height: 40px;
}

.field-error {
  color: #b42318;
  font-size: 11px;
  font-weight: 600;
}

/* =========================================================
   CONDITIONAL / SUBSECTIONS
   ========================================================= */
.conditional-panel {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 14px;
  background: linear-gradient(180deg, #f9fafc, #f4f6f9);
  border: 1px dashed #cdd6e2;
  border-radius: 12px;
  padding: 16px;
}

.subsection-label {
  grid-column: span 2;
  font-size: 12px;
  font-weight: 800;
  color: var(--gold-500);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-top: 6px;
  padding-left: 10px;
  border-left: 3px solid var(--gold-500);
}

.subsection-label small {
  font-size: 10px;
  font-weight: 700;
  color: #98a2b3;
  text-transform: none;
  letter-spacing: normal;
  margin-left: 6px;
}

/* =========================================================
   FAMILY MEMBER CARDS
   ========================================================= */
.children-list,
.family-members-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.family-member-card {
  border: 1px solid #e1e6ee;
  border-radius: 14px;
  padding: 16px;
  background: linear-gradient(180deg, #ffffff, #f9fafc);
  box-shadow: 0 4px 12px rgba(13, 33, 55, 0.04);
  transition: transform 0.25s ease, box-shadow 0.25s ease, border-color 0.25s ease;
}

.family-member-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 14px 28px rgba(13, 33, 55, 0.1);
  border-color: rgba(201, 162, 39, 0.4);
}

.family-member-card-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-weight: 800;
  font-size: 13px;
  margin-bottom: 12px;
  color: #0d2137;
}

.child-remove {
  border: none;
  background: #fef3f2;
  color: #b42318;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  cursor: pointer;
  font-weight: 800;
  transition: all 0.2s ease;
}

.child-remove:hover {
  background: #b42318;
  color: #fff;
  transform: rotate(90deg) scale(1.05);
}

.family-member-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

.family-member-grid input,
.family-member-grid select {
  height: 40px;
  padding: 0 10px;
  border: 1.5px solid #dde3ec;
  border-radius: 9px;
  font-size: 13px;
  background: #fff;
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
}

.family-member-grid input:focus,
.family-member-grid select:focus {
  border-color: var(--gold-500);
  outline: none;
  box-shadow: 0 0 0 3px rgba(201, 162, 39, 0.14);
}

.add-family-btn {
  justify-self: start;
  border-style: dashed;
  border-width: 1.5px;
}

.add-family-btn:hover:not(:disabled) {
  border-style: solid;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 10px;
}

/* =========================================================
   ALERTS
   ========================================================= */
.success,
.error {
  margin: 0 0 16px;
  padding: 12px 16px;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  border-left-width: 4px;
  border-left-style: solid;
}

.success {
  color: #027a48;
  background: linear-gradient(90deg, #ecfdf3, #f4fffa);
  border: 1px solid #abefc6;
  border-left-color: #12b76a;
}

.error {
  color: #b42318;
  background: linear-gradient(90deg, #fef3f2, #fff6f6);
  border: 1px solid #fecdca;
  border-left-color: #d92d20;
}

.draft-restore-actions {
  display: flex;
  justify-content: flex-end;
  margin: -8px 0 16px;
}

.name-duplicate-banner {
  padding: 16px;
  border-radius: 12px;
  background: linear-gradient(135deg, #fffaeb, #fff6de);
  border: 1px dashed var(--gold-500);
}

.name-duplicate-banner p {
  margin: 0 0 10px;
  font-size: 13px;
  font-weight: 700;
  color: #93370d;
}

.name-duplicate-banner p:last-child {
  margin-bottom: 0;
}

.name-duplicate-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

/* =========================================================
   MODAL: HAKIKI TAARIFA ZANGU
   ========================================================= */
.review-modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(7, 21, 39, 0.62);
  backdrop-filter: blur(3px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  z-index: 1000;
  animation: fadeIn 0.2s ease;
}

.review-modal {
  background: #fff;
  border-radius: 18px;
  max-width: 640px;
  width: 100%;
  max-height: 88vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 24px 60px rgba(7, 21, 39, 0.35);
  overflow: hidden;
  animation: slideUp 0.25s ease;
}

.review-modal-header {
  padding: 26px 28px 16px;
  background: linear-gradient(135deg, #0a1c30, #0d2137 55%, #123253);
  border-bottom: 3px solid var(--gold-500);
}

.review-modal-header h2 {
  margin: 0 0 6px;
  font-size: 18px;
  font-weight: 800;
  color: #fff;
}

.review-modal-header p {
  margin: 0;
  font-size: 13px;
  color: rgba(255, 255, 255, 0.72);
}

.review-modal-body {
  padding: 16px 28px;
  overflow-y: auto;
  flex: 1;
}

.review-section {
  padding: 14px 0;
  border-bottom: 1px dashed rgba(13, 33, 55, 0.12);
}

.review-section:last-child {
  border-bottom: none;
}

.review-section h3 {
  margin: 0 0 10px;
  font-size: 13px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--gold-500);
}

.review-section dl {
  margin: 0;
  display: grid;
  grid-template-columns: 40% 60%;
  row-gap: 7px;
  column-gap: 10px;
}

.review-section dt {
  font-size: 13px;
  font-weight: 700;
  color: #667085;
}

.review-section dd {
  margin: 0;
  font-size: 13px;
  color: #0d2137;
  word-break: break-word;
  font-weight: 600;
}

.review-modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 18px 28px 26px;
  border-top: 1px solid var(--border-soft);
  background: #fafbfc;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slideUp {
  from { opacity: 0; transform: translateY(16px) scale(0.98); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}

@media (max-width: 780px) {
  .dashboard {
    padding: 18px 16px 40px;
  }

  .resident-form,
  .conditional-panel,
  .family-member-grid {
    grid-template-columns: 1fr;
  }

  .span-2,
  .subsection-label,
  .form-section {
    grid-column: span 1;
  }
}

@media (max-width: 560px) {
  .review-section dl {
    grid-template-columns: 1fr;
    row-gap: 2px;
  }

  .review-modal-actions {
    flex-direction: column-reverse;
  }

  .review-modal-actions button {
    width: 100%;
  }
}
</style>