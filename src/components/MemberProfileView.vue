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

      <form class="resident-form" @submit.prevent="saveProfile">

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
            Sawa — jaza namba yako ya simu na barua pepe uliyotumia mara ya kwanza hapa chini,
            ili mfumo ukupatie taarifa zako za awali badala ya kutengeneza taarifa mpya.
          </p>
        </div>

        <label>
          <span>Jinsia yangu <b>*</b></span>
          <select v-model="form.gender" required>
            <option disabled value="">Chagua jinsia yangu</option>
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
            <option value="">Chagua ya ndoa</option>
            <!-- value = thamani inayokubalika na database, label = nafsi ya kwanza -->
            <option value="Hajaoa/Hajaolewa">Sijaoa/Sijaolewa</option>
            <option value="Ameoa/Ameolewa">Nimeoa/Nimeolewa</option>
            <option value="Mjane">Nimefiwa (Mjane)</option>
            <option value="Mjane wa kiume">Nimefiwa (Mgane)</option>
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
                placeholder="Mfano: 2018"
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
            Taarifa za mwenzi wangu na watoto zitaonekana ikiwa Nimeoa/Nimeolewa
          </span>
        </div>

        <template v-if="isMarried">

          <!-- ---------- Mwenzi Wangu: Taarifa Binafsi ---------- -->
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

          <!-- ---------- Mwenzi Wangu: Taarifa za Kiroho / Kanisa ---------- -->
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

          <!-- ---------- Mwenzi Wangu: Taarifa za Ziada ---------- -->
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

          <!-- ---------- Watoto Wangu ---------- -->
          <div class="subsection-label span-2">Watoto Wangu</div>

          <label>
            <span>Idadi ya watoto wangu</span>
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
                    placeholder="7XXXXXXXX (hiari)"
                  />
                </div>
                <input v-model.trim="child.email" type="email" placeholder="Barua pepe (hiari)" />
                <input v-model.trim="child.residence" placeholder="Anwani/Makazi" @blur="upperize(child, 'residence')" />
                <div class="subsection-label span-2">Taarifa za Kiroho / Kanisa za Mtoto</div>
                <label><span>Amebatizwa?</span><select v-model="child.is_baptized"><option :value="false">Hapana</option><option :value="true">Ndiyo</option></select></label>
                <template v-if="child.is_baptized">
                  <label><span>Mwaka wa ubatizo</span><input v-model="child.baptism_year" type="number" min="1900" :max="currentYear" /></label>
                  <label><span>Kanisa alikobatiziwa</span><input v-model.trim="child.baptism_place" @blur="upperize(child, 'baptism_place')" /></label>
                  <label><span>Ushirika ulipo</span><input v-model.trim="child.church_area" @blur="upperize(child, 'church_area')" /></label>
                </template>
                <label><span>Idara/Kikundi</span><input v-model.trim="child.ministry_group" list="ministry-group-options" @blur="upperize(child, 'ministry_group')" /></label>
                <label><span>Wadhifa</span><select v-model="child.church_role"><option value="">Chagua wadhifa</option><option value="Mshiriki">Mshiriki</option><option value="Kiongozi">Kiongozi</option></select></label>
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

        <!-- ---------- Wanafamilia Wangu Wengine (siyo mtoto) ---------- -->
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
            {{ saving ? 'Inahifadhi…' : (myResidentId ? 'Sasisha Taarifa Zangu' : 'Hifadhi Taarifa Zangu') }}
          </button>
        </div>

      </form>
    </section>

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

// Onyo la "jina linalofanana tayari limesajiliwa" (guest mode)
const nameDuplicateInfo = ref(null) // { exists, count, phone_hint } kutoka check_name_duplicate()
const nameDuplicateDismissed = ref(false)
const nameConfirmedSelf = ref(false)
const nameCheckedFor = ref('') // jina lililoangaliwa mara ya mwisho, huzuia maombi ya server kwa jina lilelile

const currentYear = new Date().getFullYear()

function toUpper(value) {
  return typeof value === 'string' && value ? value.toUpperCase() : value
}

function upperize(target, key) {
  if (typeof target[key] === 'string' && target[key]) {
    target[key] = target[key].toUpperCase()
  }
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

onMounted(loadMyProfile)

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
   HIFADHI TAARIFA ZANGU
   ========================================================= */

async function saveProfile() {
  error.value = ''
  message.value = ''
  saving.value = true

  try {
    const married = isMarried.value
    const student = form.is_tucasa_member
    const baptized = form.is_baptized

    const payload = {
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
      children: married ? form.children.map(cleanChild).filter((child) => child.full_name) : [],
      family_members: cleanFamilyMembers(form.family_members),
      emergency_contact_name: toUpper((form.emergency_contact_name || '').trim()) || null,
      emergency_contact_phone: form.emergency_contact_phone || null,

      is_tucasa_member: student,
      institution_name: student ? (toUpper((form.institution_name || '').trim()) || null) : null,
      occupation: toUpper((form.occupation || '').trim()) || null,
      skills: toUpper((form.skills || '').trim()) || null,
      special_needs: toUpper((form.special_needs || '').trim()) || null,
    }

    if (!payload.full_name || !payload.gender) {
      error.value = 'Jina langu kamili na jinsia yangu ni lazima.'
      return
    }

    const phoneOk = validatePhone()
    const emailOk = validateEmail()
    const residenceOk = validateResidence()
    const emergencyPhoneOk = validateEmergencyPhone()
    const spousePhoneOk = validateSpousePhone()
    const spouseEmailOk = validateSpouseEmail()

    if (!phoneOk || !emailOk || !residenceOk || !emergencyPhoneOk || !spousePhoneOk || !spouseEmailOk) {
      error.value = 'Tafadhali nisahihishe taarifa zilizoangaziwa kwa nyekundu kabla ya kuendelea.'
      return
    }

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
        ? 'Taarifa zako zimesasishwa kwa mafanikio.'
        : 'Hongera! Taarifa zako zimehifadhiwa kwa mafanikio.'
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
    }
  } catch (err) {
    error.value = err?.message || 'Hitilafu imetokea. Jaribu tena.'
  } finally {
    saving.value = false
  }
}

</script>

<style scoped>
/* Mtindo huu unafanana na AdminDashboard.vue ili muonekano
   ubaki sawa kati ya panel ya admin na hii ya mshiriki. */

.dashboard {
  min-height: 100vh;
  padding: 28px 32px 60px;
  background: #f5f7fa;
  color: #0d2137;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 16px;

  padding-bottom: 20px;
  margin-bottom: 24px;

  border-bottom: 1px solid rgba(13, 33, 55, 0.1);
}

.brand-area {
  display: flex;
  align-items: center;
  gap: 14px;
}

.brand-logo {
  width: 52px;
  height: 52px;
  border-radius: 50%;
  background: #0d2137;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.brand-logo img {
  width: 40px;
  height: 40px;
  object-fit: contain;
}

.eyebrow {
  margin: 0 0 2px;
  color: #667085;
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.14em;
  text-transform: uppercase;
}

.topbar h1 {
  margin: 0;
  font-size: 20px;
  font-weight: 800;
}

.brand-subtitle {
  margin: 2px 0 0;
  color: #667085;
  font-size: 13px;
}

.topbar-actions {
  display: flex;
  align-items: center;
  gap: 14px;
}

.admin-info {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  font-size: 12px;
}

.admin-label {
  color: #98a2b3;
}

.admin-email {
  font-weight: 700;
}

.ghost-button {
  background: transparent;
  border: 1px solid rgba(13, 33, 55, 0.2);
  color: #0d2137;
  padding: 9px 16px;
  border-radius: 8px;
  font-weight: 700;
  font-size: 13px;
  cursor: pointer;
}

.ghost-button:hover {
  background: rgba(13, 33, 55, 0.06);
}

.primary-button,
.secondary-button {
  padding: 12px 20px;
  border-radius: 10px;
  font-weight: 800;
  font-size: 14px;
  cursor: pointer;
  border: 1px solid transparent;
}

.primary-button {
  background: #0d2137;
  border-color: #0d2137;
  color: #fff;
}

.primary-button:hover:not(:disabled) {
  background: #16324a;
}

.primary-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.secondary-button {
  background: #fff;
  border-color: #d5dce5;
  color: #0d2137;
}

.secondary-button:hover:not(:disabled) {
  border-color: #9aa9b8;
}

.panel {
  background: #fff;
  border: 1px solid rgba(13, 33, 55, 0.08);
  border-radius: 16px;
  padding: 28px;
  box-shadow: 0 12px 30px rgba(13, 33, 55, 0.06);
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
  margin-bottom: 20px;
}

.section-title {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.section-title-icon {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background: #0d2137;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  flex: 0 0 auto;
}

.panel-heading h2 {
  margin: 0 0 4px;
  font-size: 18px;
  font-weight: 800;
}

.panel-heading p {
  margin: 0;
  color: #667085;
  font-size: 13px;
}

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
  padding: 0 12px;
  border: 1px solid #d5dce5;
  border-radius: 9px;
  font-size: 14px;
  color: #0d2137;
  background: #fff;
  outline: none;
}

.resident-form input:focus,
.resident-form select:focus {
  border-color: #0d2137;
  box-shadow: 0 0 0 3px rgba(13, 33, 55, 0.09);
}

.resident-form select:disabled {
  background: #f2f4f7;
  color: #98a2b3;
}

.form-section {
  grid-column: span 2;
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 18px;
  padding-top: 18px;
  border-top: 1px solid rgba(13, 33, 55, 0.08);
}

.form-section:first-of-type {
  margin-top: 0;
  padding-top: 0;
  border-top: none;
}

.form-section-number {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #0d2137;
  color: #fff;
  font-size: 12px;
  font-weight: 800;
  display: flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
}

.form-section h3 {
  margin: 0;
  font-size: 15px;
  font-weight: 800;
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

.phone-input-group {
  display: flex;
  align-items: center;
  border: 1px solid #d5dce5;
  border-radius: 9px;
  overflow: hidden;
  height: 44px;
}

.phone-input-group:focus-within {
  border-color: #0d2137;
  box-shadow: 0 0 0 3px rgba(13, 33, 55, 0.09);
}

.phone-prefix {
  padding: 0 10px;
  background: #f2f4f7;
  color: #667085;
  font-size: 13px;
  font-weight: 700;
  height: 100%;
  display: flex;
  align-items: center;
  border-right: 1px solid #d5dce5;
}

.phone-input-group input {
  border: none;
  height: 100%;
  flex: 1;
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

.conditional-panel {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 14px;
  background: #f9fafb;
  border: 1px dashed #d5dce5;
  border-radius: 10px;
  padding: 14px;
}

.subsection-label {
  grid-column: span 2;
  font-size: 12px;
  font-weight: 800;
  color: #0d2137;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  margin-top: 6px;
}

.children-list,
.family-members-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.family-member-card {
  border: 1px solid #d5dce5;
  border-radius: 12px;
  padding: 14px;
  background: #f9fafb;
}

.family-member-card-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-weight: 800;
  font-size: 13px;
  margin-bottom: 10px;
}

.child-remove {
  border: none;
  background: #fef3f2;
  color: #b42318;
  width: 26px;
  height: 26px;
  border-radius: 50%;
  cursor: pointer;
  font-weight: 800;
}

.child-remove:hover {
  background: #fecdca;
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
  border: 1px solid #d5dce5;
  border-radius: 8px;
  font-size: 13px;
}

.add-family-btn {
  justify-self: start;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 8px;
}

.success,
.error {
  margin: 0 0 16px;
  padding: 10px 14px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
}

.success {
  color: #027a48;
  background: #ecfdf3;
  border: 1px solid #abefc6;
}

.error {
  color: #b42318;
  background: #fef3f2;
  border: 1px solid #fecdca;
}

.name-duplicate-banner {
  padding: 14px;
  border-radius: 10px;
  background: #fffaeb;
  border: 1px dashed #fedf89;
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
</style>