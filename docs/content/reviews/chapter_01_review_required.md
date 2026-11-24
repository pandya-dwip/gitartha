# Chapter 1 — Human Review Required

Everything in `chapter_01.json` is a **draft**. The items below need a person: some must be
checked against a printed edition, some need a fluent Hindi reader, and some are decisions
only the content owner can make. Nothing listed here was silently changed in the JSON.

Priority: **A** = the scripture text itself (resolve before any approval) · **B** = translation
fidelity · **C** = generated content to verify · **D** = removed or unmapped text ·
**E** = conventions to confirm.

---

## A. Sanskrit source text

### A1. 1.30 / 1.31: the same half-verse appears twice

- **Field:** `sanskrit_text` (and therefore `transliteration`, `hindi_meaning`,
  `english_meaning`)
- **Original 1.30:** `न च शक्नोम्यवस्थातुं भ्रमतीव च मे मनः। / निमित्तानि च पश्यामि विपरीतानि केशव॥ १.३०॥`
- **Original 1.31:** `निमित्तानि च पश्यामि विपरीतानि केशव। / न च श्रेयोऽनुपश्यामि हत्वा स्वजनमाहवे॥ १.३१॥`
- **Problem:** "निमित्तानि च पश्यामि विपरीतानि केशव" is in both verses. A pada cannot
  belong to two verses.
- **Verify:** the correct text and division of 1.29–1.31 in your chosen edition (see A2).

### A2. 1.29 / 1.30: shifted by half a verse; one half-verse missing

- **Field:** `sanskrit_text` (+ dependent fields)
- **Original 1.29:** `वेपथुश्च शरीरे मे रोमहर्षश्च जायते। / गाण्डीवं स्रंसते हस्तात्त्वक्चैव परिदह्यते॥ १.२९॥`
- **Problem:** the rest of the document (1.28, 1.31–1.41) follows the common numbering.
  In that numbering, 1.29 is "सीदन्ति मम गात्राणि मुखं च परिशुष्यति। वेपथुश्च शरीरे मे
  रोमहर्षश्च जायते॥", and 1.30 is "गाण्डीवं स्रंसते … । न च शक्नोम्यवस्थातुं भ्रमतीव च मे
  मनः॥".
  - **The half-verse "सीदन्ति मम गात्राणि मुखं च परिशुष्यति" ("my limbs give way and my
    mouth is parched") is not in the document at all.**
  - The document's 1.29–1.30 match the grouping used by some other editions, which number
    1.28 differently, so the document mixes two numbering systems.
- **Verify:** pick one edition. Correct 1.29–1.31 from it, including the English
  meanings, context and life lessons, which currently follow the document's division.
  Record that edition in `sources.json` and attribute it.

### A3. 1.21: first half missing

- **Field:** `sanskrit_text`
- **Original:** `अर्जुन उवाच। / सेनयोरुभयोर्मध्ये रथं स्थापय मेऽच्युत॥ १.२१॥`
- **Problem:** standard editions read "हृषीकेशं तदा वाक्यमिदमाह महीपते। अर्जुन उवाच।
  सेनयोरुभयोर्मध्ये रथं स्थापय मेऽच्युत॥". The narrator's half ("then, O King, he spoke
  these words to Hrishikesha") is missing. It was **not** reconstructed.
- **Verify:** against the source edition; then add it to the Sanskrit, the
  transliteration and both meanings.

### A4. 1.22 and 1.28: no verse-end number

- **Field:** `sanskrit_text`
- **Original endings:** 1.22 `…रणसमुद्यमे॥`. 1.28 `…युयुत्सुं समुपस्थितम्॥`
- **Problem:** every other verse ends `॥ १.N॥`. Guidelines §2 expect the number.
- **Verify:** add `१.२२` and `१.२८` once the text is confirmed against the source.

### A5. All verses: the Sanskrit has no recorded source

- **Field:** `sanskrit_text`, `source_attributions`
- **Problem:** the document does not say which edition the Sanskrit comes from, and
  `sources.json` is empty. Guidelines §2 require the verse to be copied from a recorded
  source and checked character by character.
- **Verify:** check all 41 verses against one edition, add it to `sources.json`, and
  attribute `sanskrit_text`. Orthographic variants to look at during that check:
  - 1.2 `उपसंगम्य` (many editions use `उपसङ्गम्य`)
  - 1.20 `धार्तराष्ट्रान् कपिध्वजः`, written with a space
  - 1.22 `अस्मिन् रणसमुद्यमे`, written with a space

---

## B. Translation fidelity

The document's English meanings were kept, apart from format normalization. These are
places where the English differs from the Sanskrit and should be reviewed.

| Ref | Field | Original (document) | Concern | Verify / suggestion |
|---|---|---|---|---|
| 1.1 | english_meaning | "Gathered at Kurukshetra, ready for battle, …" | *dharma-kṣetre* ("on the field of dharma") is not translated | Consider "on the field of dharma, Kurukshetra" |
| 1.3 | english_meaning | "arranged so skilfully by your intelligent student" | "so skilfully" is not in the Sanskrit (*vyūḍhām* = arrayed) | Consider "arrayed for battle" |
| 1.8 | english_meaning | "…Kripacharya, Ashwatthama…" | *samitiñjayaḥ* ("victorious in battle", describing Kripa) is omitted | Consider "Kripa, ever victorious in battle" |
| 1.11 | english_meaning | "Therefore, … must protect Bhishma from every side" | "Therefore" and "from every side" are interpretive; see also *ayaneṣu* in C3 | Confirm the wording |
| 1.17 | english_meaning | "…were also present among the Pandava warriors" | The Sanskrit sentence continues into 1.18: they **blew their conches**. The Hindi follows the Sanskrit, so English and Hindi now differ | Consider "…also blew their conches (continued in 1.18)" |
| 1.26 | english_meaning | "standing in both armies" | "in both armies" comes from 1.27 (*senayor ubhayor api*), not 1.26 | Acceptable carried-over context, or move it |
| 1.32 | english_meaning | "O Krishna, I desire neither victory…" | The second vocative *Govinda* is omitted (the Hindi includes it) | Consider "…O Govinda, what is the use…" |
| 1.35 | english_meaning | "even if they attack me" | *ghnato 'pi* is usually "even if they kill me" | Confirm |

---

## C. Generated content to verify

### C1. Hindi meaning: 1.1–1.35 (35 verses)

- **Field:** `hindi_meaning`
- **Original:** none. The document has no Hindi before 1.36.
- **What was done:** translated from the document's Sanskrit, in the style of 1.36–1.41.
  This is **AI-generated**: not checked by a Hindi speaker, not compared with any
  published translation, and not attributed.
- **Verify:** accuracy against the Sanskrit, grammar, natural phrasing and consistent
  terminology, for every verse. Pay particular attention to:
  - **1.17 and 1.18:** the verb is supplied in parentheses in 1.17.
  - **1.22:** "(रथ को वहाँ तब तक खड़ा रखिए,)" is added, because *yāvat* links back to
    1.21.
  - **1.27 and 1.28:** they end with an ellipsis, because the sentence continues.
  - **1.29–1.31:** these will change once A1 and A2 are resolved.

### C2. New wording notes: 1.10, 1.26

- **Field:** `hindi_meaning_note`
- **1.10:** explains the two readings of *aparyāptam / paryāptam*. The point comes from
  the document's own context paragraph ("there are different interpretations…").
- **1.26:** explains *pitṝn* as father-generation elders. "Generally understood" is a
  claim about the commentary tradition.
- **Verify:** that both are accurate and worth keeping. The notes are in English, like
  1.41's finalized note. Decide whether notes should be English or Hindi.

### C3. Ambiguous terms (rendering chosen; confirm)

| Ref | Term | Chosen rendering | Alternative |
|---|---|---|---|
| 1.9 | *tyakta-jīvitāḥ* | "जीवन का मोह त्याग देने वाले" | "have already given up their lives" |
| 1.11 | *ayaneṣu* | "मोर्चों पर" / "divisions" | "at the entrances / strategic points of the formation" |
| 1.13 | *paṇava, ānaka, gomukha* | "पणव, आनक (ढोल जैसे वाद्य), गोमुख (नरसिंघे)" | exact instruments uncertain |
| 1.18 | *sarvaśaḥ* | "सब ओर से" | "all together" |
| 1.20 | *kapi-dhvajaḥ* | "जिनके रथ की ध्वजा पर हनुमान का चिह्न है" | literally "monkey-bannered"; Hanuman is the traditional identification |
| 1.33 | *prāṇāṁs tyaktvā* | "प्राणों … का मोह त्यागकर" | "having given up their lives" |
| 1.35 | *ghnato 'pi* | "मुझे मार भी डालें" | "even though they are killing (us)" |

### C4. Index title and summary: all verses

- **Fields:** `index_title` (1.1–1.40), `index_summary` (1.1–1.41)
- **Original:** none. The document has no index text. 1.41's title was already in the
  repository and is unchanged.
- **Verify:** that each title and summary describes only what the verse says.

### C5. IAST transliteration: 1.1–1.35

- **Field:** `transliteration`
- **Original:** ASCII, e.g. 1.1 "Dhritarashtra uvacha: / Dharma-kshetre kuru-kshetre
  samaveta yuyutsavah, / Mamakah pandavash chaiva kim akurvata Sanjaya."
- **What was done:** rewritten in IAST, keeping the document's word division. It was
  mechanically checked against the Sanskrit and matches character for character.
- **Verify:** word division, and the capitalisation rules in E2. If the Sanskrit changes
  under A1–A4, the transliteration must change with it.

---

## D. Removed or unmapped text

| Ref | Field | Original text | Why not stored | Decide |
|---|---|---|---|---|
| 1.1 | reflection_question | "That's the kind of human tendency this opening shloka invites us to reflect on." | Not a question. The guidelines require exactly one open question | Drop, or fold into `life_lesson` |
| 1.2 | reflection_question | "If yes, you may understand the kind of situation this shloka introduces." | Not a question; it also presupposes an answer | Drop, or fold into `context` |
| 1.3 | reflection_question | "Recognizing that feeling honestly is the first step toward overcoming it." | Not a question; it reads as a lesson | Consider appending to `life_lesson` |
| chapter | (none) | Subtitle "The Yoga of Arjuna's Despair" | No field for a subtitle. `english_name` is "Arjuna Vishada Yoga" | Choose which form `english_name` should hold |

---

## E. Conventions to confirm

1. **Anusvara: `ṁ` or `ṃ`.** Guidelines §3 list `ṃ`, but finalized 1.36–1.41 use `ṁ`. The
   chapter follows the finalized verses. Decide once for all chapters.
2. **Transliteration capitalisation.**
   - Line starts, personal names and one-person epithets are capitalised: Kṛṣṇa,
     Keśava, Pāṇḍavaḥ (= Arjuna), Kaunteyaḥ.
   - Plural patronymics are not: dhārtarāṣṭrāḥ, pāṇḍavāḥ, draupadeyāḥ.
   - Speaker lines are written `X uvāca:`.
   - 1.28 ends its first line with "." because the speaker line follows.
3. **Emphasis on English phrases.** The .docx italicises two English phrases: 1.3 "*his
   own student*" and the finalized 1.37 "*my family, my relatives, my people*". They are
   kept as `*…*`, but guidelines §10 reserve `*…*` for Sanskrit and technical terms.
   Separately, the app's reader currently shows `*` characters literally; Milestone 6
   does not render emphasis. That is an app issue to fix independently.
4. **Depth.** The context, life lessons and spiritual meanings of 1.1–1.35 are the
   document's own, shorter than 1.36–1.41, and were deliberately not padded (guidelines
   §9). Decide whether they should be expanded by a human author.
5. **Chapter metadata.** `sanskrit_name`, `hindi_name`, introduction, overview, central
   theme, key topics, summary and conclusion are empty, because the document has none.
   They are needed before the chapter can be approved.
6. **Sources.** Add the Sanskrit edition, and the origin of the English and Hindi
   meanings, to `sources.json` with licences. Then attribute `sanskrit_text`,
   `english_meaning` and `hindi_meaning` on every verse (guidelines §11). The 35
   generated Hindi meanings need a source entry for the Gitartha editorial translation,
   if that is how you choose to publish them.
7. **Verses 1.42–1.47** are not in the document. They still need to be authored.
