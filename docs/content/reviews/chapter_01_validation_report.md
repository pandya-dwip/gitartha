# Chapter 1 — Conversion and Validation Report

- **Source:** `Chapter 1.docx` (project root), converted on 24 Nov 2026.
- **Output:** `assets/data/bhagavad_gita/chapters/chapter_01.json`. No other chapter file
  was changed. Nothing was published to Supabase or imported into SQLite.
- **Status:** every verse is `review_status: "draft"`. The content is machine-assisted
  and has **not** been verified by a person or against a printed edition (guidelines
  §12).

Items that need a human decision are listed in
[`chapter_01_review_required.md`](chapter_01_review_required.md).

## 1. Totals

| | |
|---|---|
| Verses extracted | **41** (1.1–1.41) |
| Verses expected in Chapter 1 | 47 |
| Verse numbers found | 1–41, contiguous |
| Missing verse numbers | **42, 43, 44, 45, 46, 47.** They are not in the document |
| Duplicate references | none (each verse heading occurs once; ids and references are unique) |

The document uses three heading layouts. Each was mapped to the same JSON fields:

| Verses | Document layout | Mapped as |
|---|---|---|
| 1–14 | Original Sanskrit / Pronunciation / Simple meaning / What does it mean? / Life lesson / Spiritual meaning / Think about this | sanskrit_text / transliteration / english_meaning / context / life_lesson / spiritual_meaning / reflection_question |
| 15–35 | Sanskrit / Pronunciation / Simple meaning / Context / Life lesson / Spiritual meaning / A question to reflect on | the same |
| 36–41 (finalized) | Sanskrit / Pronunciation / Hindi Meaning / English Meaning / Context — What is happening here? / Life Lesson / Spiritual Meaning / Reflection Question | the same, plus hindi_meaning (and, in 1.41, hindi_meaning_note) |

## 2. Missing Sanskrit or transliteration

None is missing. Every verse has both. The suspected issues in 1.21 and 1.29–1.31 (§8)
were reviewed by the owner, who kept the text as given. The missing verse-end numbers of
1.22 and 1.28 were added on the owner's confirmation.

The Sanskrit was copied from the document **programmatically**, never retyped. Two
checks confirm it:

- Every Sanskrit line in the JSON occurs verbatim in an independent extraction of the
  .docx.
- No invisible characters (zero-width joiners or non-joiners, BOM, non-breaking spaces)
  are present, and the text is already Unicode NFC.

Lines are separated by `\n`, as in the document's layout. Speaker lines
(e.g. `धृतराष्ट्र उवाच।`) are their own line.

| Ref | Lines | Starts | Ends | In docx verbatim |
|---|---|---|---|---|
| 1.1 | 3 | धृतराष्ट्र उवाच। … | …वत सञ्जय॥ १.१॥ | yes |
| 1.2 | 3 | सञ्जय उवाच। … | …मब्रवीत्॥ १.२॥ | yes |
| 1.3 | 2 | पश्यैतां पाण्डुपुत्राणामाचार्य … | …ेण धीमता॥ १.३॥ | yes |
| 1.4 | 2 | अत्र शूरा … | …च महारथः॥ १.४॥ | yes |
| 1.5 | 2 | धृष्टकेतुश्चेकितानः काशिराजश्च … | …रपुङ्गवः॥ १.५॥ | yes |
| 1.6 | 2 | युधामन्युश्च विक्रान्त … | … महारथाः॥ १.६॥ | yes |
| 1.7 | 2 | अस्माकं तु … | …रवीमि ते॥ १.७॥ | yes |
| 1.8 | 2 | भवान्भीष्मश्च कर्णश्च … | …स्तथैव च॥ १.८॥ | yes |
| 1.9 | 2 | अन्ये च … | …विशारदाः॥ १.९॥ | yes |
| 1.10 | 2 | अपर्याप्तं तदस्माकं … | …क्षितम्॥ १.१०॥ | yes |
| 1.11 | 2 | अयनेषु च … | …व एव हि॥ १.११॥ | yes |
| 1.12 | 2 | तस्य सञ्जनयन्हर्षं … | …तापवान्॥ १.१२॥ | yes |
| 1.13 | 2 | ततः शङ्खाश्च … | …लोऽभवत्॥ १.१३॥ | yes |
| 1.14 | 2 | ततः श्वेतैर्हयैर्युक्ते … | …दध्मतुः॥ १.१४॥ | yes |
| 1.15 | 2 | पाञ्चजन्यं हृषीकेशो … | …वृकोदरः॥ १.१५॥ | yes |
| 1.16 | 2 | अनन्तविजयं राजा … | …पुष्पकौ॥ १.१६॥ | yes |
| 1.17 | 2 | काश्यश्च परमेष्वासः … | …पराजितः॥ १.१७॥ | yes |
| 1.18 | 2 | द्रुपदो द्रौपदेयाश्च … | …क्पृथक्॥ १.१८॥ | yes |
| 1.19 | 2 | स घोषो … | …ुनादयन्॥ १.१९॥ | yes |
| 1.20 | 2 | अथ व्यवस्थितान्दृष्ट्वा … | …पाण्डवः॥ १.२०॥ | yes |
| 1.21 | 2 | अर्जुन उवाच। … | …ेऽच्युत॥ १.२१॥ | yes |
| 1.22 | 2 | यावदेतान्निरीक्षेऽहं योद्धुकामानवस्थितान्। … | …न् रणसमुद्यमे॥ | yes |
| 1.23 | 2 | योत्स्यमानानवेक्षेऽहं य … | …कीर्षवः॥ १.२३॥ | yes |
| 1.24 | 3 | सञ्जय उवाच। … | …ोत्तमम्॥ १.२४॥ | yes |
| 1.25 | 2 | भीष्मद्रोणप्रमुखतः सर्वेषां … | …ुरूनिति॥ १.२५॥ | yes |
| 1.26 | 2 | तत्रापश्यत्स्थितान्पार्थः पितॄनथ … | …ींस्तथा॥ १.२६॥ | yes |
| 1.27 | 2 | श्वशुरान्सुहृदश्चैव सेनयोरुभयोरपि। … | …्थितान्॥ १.२७॥ | yes |
| 1.28 | 3 | कृपया परयाविष्टो … | …ं समुपस्थितम्॥ | yes |
| 1.29 | 2 | वेपथुश्च शरीरे … | …िदह्यते॥ १.२९॥ | yes |
| 1.30 | 2 | न च … | …नि केशव॥ १.३०॥ | yes |
| 1.31 | 2 | निमित्तानि च … | …जनमाहवे॥ १.३१॥ | yes |
| 1.32 | 2 | न काङ्क्षे … | …ितेन वा॥ १.३२॥ | yes |
| 1.33 | 2 | येषामर्थे काङ्क्षितं … | …धनानि च॥ १.३३॥ | yes |
| 1.34 | 2 | आचार्याः पितरः … | …िनस्तथा॥ १.३४॥ | yes |
| 1.35 | 2 | एतान्न हन्तुमिच्छामि … | …महीकृते॥ १.३५॥ | yes |
| 1.36 | 2 | निहत्य धार्तराष्ट्रान्नः … | …ततायिनः॥ १.३६॥ | yes |
| 1.37 | 2 | तस्मान्नार्हा वयं … | …ाम माधव॥ १.३७॥ | yes |
| 1.38 | 2 | यद्यप्येते न … | … पातकम्॥ १.३८॥ | yes |
| 1.39 | 2 | कथं न … | …जनार्दन॥ १.३९॥ | yes |
| 1.40 | 2 | कुलक्षये प्रणश्यन्ति … | …भवत्युत॥ १.४०॥ | yes |
| 1.41 | 2 | अधर्माभिभवात्कृष्ण प्रदुष्यन्ति … | …णसङ्करः॥ १.४१॥ | yes |

### Transliteration

- **1.36–1.41:** copied from the document unchanged.
- **1.1–1.35:** the document has simplified ASCII spellings ("Dhritarashtra uvacha",
  "pandavash chaiva"). Guidelines §3 require IAST, and the finalized verses use it, so
  these were **rewritten in IAST**. The document's own word division and hyphenation
  were kept, in the finalized style: `ṁ` for anusvara, `'` for avagraha, a comma after the
  first half-verse, a full stop at the end. Speaker lines are written `Dhṛtarāṣṭra uvāca:`.
- **Mechanical check:** a Devanagari→IAST converter compared each transliteration with
  its Sanskrit, ignoring spaces, hyphens, case and punctuation. **All 41 match,
  character for character.** The converter was first calibrated on the finalized 1.36
  and 1.40.

## 3. Missing content fields

None. In draft mode the validator reports **41/41 verses complete**: every required text
field is non-empty, and `hindi_meaning_note` is optional. Fields that were **not** in the
document and were written during conversion:

| Field | Verses | Origin |
|---|---|---|
| `hindi_meaning` | 1.1–1.35 | generated (see §4) |
| `index_title` | 1.1–1.40 | generated. 1.41's title already existed in the repository and is kept |
| `index_summary` | 1.1–1.41 | generated |
| `hindi_meaning_note` | 1.10, 1.26 | generated. 1.41's note is from the document |
| `transliteration` (IAST form) | 1.1–1.35 | normalized from the document's ASCII (§2) |

**Chapter metadata.** `english_name` = "Arjuna Vishada Yoga" (from the document heading).
The document's subtitle, "The Yoga of Arjuna's Despair", has no dedicated field and was
not stored. `sanskrit_name`, `hindi_name`, `introduction`, `overview`, `central_theme`,
`key_topics`, `summary` and `conclusion` are **empty**, because the document does not
contain them. The validator warns `INCOMPLETE_CONTENT` for the chapter.

## 4. Hindi meanings generated during conversion

**35 verses: 1.1–1.35.** The document has no Hindi for these.

They were translated from the document's Sanskrit, verse by verse, in the style of
1.36–1.41:

- the vocative comes first, with the epithet explained in parentheses
  ("हे केशव (श्रीकृष्ण)!");
- individual terms are glossed in parentheses ("आततायियों (आक्रमण करने वालों)");
- `X ने कहा:` is used where the Sanskrit has an *uvāca* line;
- an ellipsis is used where the sentence runs on into the next verse (1.27, 1.28), as in
  the English of 1.38.

They are **AI-generated and unverified**. No published translation was copied, and none
is credited.

Terminology is kept the same across the chapter: श्रीकृष्ण, पाण्डु के पुत्र / पाण्डव,
धृतराष्ट्र के पुत्र, महारथी, स्वजन, विपरीत (अशुभ) लक्षण. Where the Sanskrit expresses a
word that is only implied in Hindi, the addition is in parentheses: 1.5, 1.8, 1.17,
1.22, 1.25, 1.26, 1.28, 1.30, 1.34.

Grammar and readability were checked while writing, but a fluent Hindi reviewer must
still approve every line.

## 5. Hindi meanings already present in the document

**6 verses: 1.36–1.41.** Copied unchanged. 1.41's wording note is also from the document
(the prefix "A note on the wording:" was dropped, because the app supplies that heading).

## 6. Ambiguous Sanskrit interpretations

| Ref | Term | Readings | Rendered as |
|---|---|---|---|
| 1.9 | *tyakta-jīvitāḥ* | "who have given up their lives" / "ready to risk their lives" | "जीवन का मोह त्याग देने वाले"; English "prepared to sacrifice their lives" |
| 1.10 | *aparyāptam / paryāptam* | "unlimited / limited", or "insufficient / sufficient" | the document's "unlimited / limited". Both readings explained in a new wording note |
| 1.11 | *ayaneṣu* | "at the entrances / strategic points" or "in the divisions" of the formation | "मोर्चों पर"; English "divisions" |
| 1.13 | *paṇava, ānaka, gomukha* | exact instruments uncertain (drums, tabors, cow-horn trumpets) | named with approximate glosses |
| 1.18 | *sarvaśaḥ* | "all together" / "on all sides" | "सब ओर से" |
| 1.20 | *kapi-dhvajaḥ* | literally "monkey-bannered". The identification with Hanuman is traditional, not literal | kept as in the document, with a gloss |
| 1.26 | *pitṝn* | "fathers", generally understood as father-generation elders | "पिता-तुल्य बड़ों (ताऊ-चाचाओं)", with a new wording note |
| 1.33 | *prāṇāṁs tyaktvā* | "having given up their lives" / "risking their lives" | "प्राणों … का मोह त्यागकर" |
| 1.35 | *ghnato 'pi* | "even if they kill (me)" / "even though they are killing" | Hindi "मुझे मार भी डालें"; the English keeps the document's "even if they attack me" |

## 7. Normalization of verses 1.1–1.35 to the finalized format

| Change | Where |
|---|---|
| Narrator framing and quotation marks removed from the English meaning ("Duryodhana says: \"…\""). Kept as `X said:` only where the Sanskrit has an *uvāca* line (1.1, 1.2, 1.21, 1.24, 1.28) | 1.1–1.35 |
| Vocative epithets written as in 36–41: "O Keshava (Krishna)" (the document has "O Krishna"), "O Bharata (Dhritarashtra)", "O Partha (Arjuna)" | 1.24, 1.25, 1.30, 1.31 |
| British spelling, as in 1.15–1.41: recognise, emphasise, paralyse, skilfully | 1.3–1.11 (16 replacements) |
| "dharma" written `*Dharma*`, as in 36–41 | 1.1, 1.9, 1.12 |
| Sanskrit terms in prose given diacritics: *aparyāptam*, *paryāptam* | 1.10 |
| Sentences after the reflection question that were not questions were removed. **The text is recorded in the review list, not discarded silently** | 1.1, 1.2, 1.3 |
| Paragraphs joined with a blank line; italic terms from the .docx marked as `*term*` | all |

Context, life lesson, spiritual meaning and reflection text is otherwise the document's
own wording. No new explanations were written for these fields.

The English meanings before and after normalization:

| Ref | Document ("Simple meaning") | JSON `english_meaning` |
|---|---|---|
| 1.1 | King Dhritarashtra asks Sanjaya: "Gathered at Kurukshetra, ready for battle, what did my sons and the sons of Pandu do, Sanjaya?" | Dhritarashtra said: O Sanjaya, gathered at Kurukshetra, ready for battle, what did my sons and the sons of Pandu do? |
| 1.2 | Sanjaya says: "Seeing the Pandava army arranged for battle, King Duryodhana approached his teacher, Dronacharya, and spoke to him." | Sanjaya said: Seeing the Pandava army arranged for battle, King Duryodhana approached his teacher, Dronacharya, and spoke to him. |
| 1.3 | Duryodhana says to his teacher, Dronacharya: "Teacher, look at this mighty army of the sons of Pandu, arranged so skillfully by your intelligent student, the son of Drupada." | O teacher, look at this mighty army of the sons of Pandu, arranged so skilfully by your intelligent student, the son of Drupada. |
| 1.4 | Duryodhana says: "Here are mighty warriors, skilled with their bows and as formidable in battle as Bhima and Arjuna — including Yuyudhana, Virata, and the great warrior Drupada." | Here are mighty warriors, skilled with their bows and as formidable in battle as Bhima and Arjuna — including Yuyudhana, Virata, and the great warrior Drupada. |
| 1.5 | Duryodhana continues listing the Pandavas' warriors: "Among them are Dhrishtaketu, Chekitana, the powerful King of Kashi, Purujit, Kuntibhoja, and Shaibya, the finest among men." | Among them are Dhrishtaketu, Chekitana, the powerful King of Kashi, Purujit, Kuntibhoja, and Shaibya, the finest among men. |
| 1.6 | Duryodhana continues: "Also present are the brave Yudhamanyu, the powerful Uttamauja, Abhimanyu (Subhadra's son), and the sons of Draupadi. All of them are great warriors." | Also present are the brave Yudhamanyu, the powerful Uttamauja, Abhimanyu (Subhadra's son), and the sons of Draupadi. All of them are great warriors. |
| 1.7 | Duryodhana says to Dronacharya: "O best among Brahmanas, let me now tell you about the distinguished warriors on our side, the leaders of my army, so that you may know them." | O best among Brahmanas, let me now tell you about the distinguished warriors on our side, the leaders of my army, so that you may know them. |
| 1.8 | Duryodhana says: "Yourself (Dronacharya), Bhishma, Karna, Kripacharya, Ashwatthama, Vikarna, and the son of Somadatta (Bhurishrava) are among our great warriors." | Yourself (Dronacharya), Bhishma, Karna, Kripacharya, Ashwatthama, Vikarna, and the son of Somadatta (Bhurishrava) are among our great warriors. |
| 1.9 | Duryodhana says: "There are many other brave warriors who are prepared to sacrifice their lives for my sake. They are equipped with different weapons and are all highly skilled in warfare." | There are many other brave warriors who are prepared to sacrifice their lives for my sake. They are equipped with different weapons and are all highly skilled in warfare. |
| 1.10 | Duryodhana says: "Our army, protected by Bhishma, is unlimited, whereas the army of the Pandavas, protected by Bhima, is limited." | Our army, protected by Bhishma, is unlimited, whereas the army of the Pandavas, protected by Bhima, is limited. |
| 1.11 | Duryodhana tells his warriors: "Therefore, all of you, positioned at your respective places in the different divisions of the army, must protect Bhishma from every side." | Therefore, all of you, positioned at your respective places in the different divisions of the army, must protect Bhishma from every side. |
| 1.12 | "Then the mighty grandsire Bhishma, the oldest and most respected member of the Kuru family, blew his conch loudly like a lion's roar, bringing joy to Duryodhana." | Then the mighty grandsire Bhishma, the oldest and most respected member of the Kuru family, blew his conch loudly like a lion's roar, bringing joy to Duryodhana. |
| 1.13 | "After that, conches, drums, trumpets and other musical instruments were suddenly sounded together, creating a tremendous noise." | After that, conches, drums, trumpets and other musical instruments were suddenly sounded together, creating a tremendous noise. |
| 1.14 | "Then Madhava (Lord Krishna) and Arjuna, seated in their magnificent chariot drawn by white horses, blew their divine conches." | Then Madhava (Lord Krishna) and Arjuna, seated in their magnificent chariot drawn by white horses, blew their divine conches. |
| 1.15 | Krishna (Hrishikesha) blew his conch named Panchajanya, Arjuna (Dhananjaya) blew Devadatta, and Bhima (Vrikodara), known for his mighty deeds, blew his great conch named Paundra. | (unchanged) |
| 1.16 | King Yudhishthira, the son of Kunti, blew his conch named Anantavijaya. Nakula and Sahadeva blew their conches named Sughosha and Manipushpaka. | (unchanged) |
| 1.17 | The great archer King of Kashi, the mighty warrior Shikhandi, Dhrishtadyumna, King Virata, and the undefeated Satyaki were also present among the Pandava warriors. | (unchanged) |
| 1.18 | O King, Drupada, the sons of Draupadi, and the mighty-armed son of Subhadra (Abhimanyu) all blew their respective conches. | (unchanged) |
| 1.19 | The tremendous sound of the Pandavas' conches echoed through the sky and across the earth, piercing the hearts of Dhritarashtra's sons with fear. | (unchanged) |
| 1.20 | Then, seeing the sons of Dhritarashtra standing ready for battle, Arjuna, whose chariot bore the emblem of Hanuman, lifted his bow as the battle was about to begin. | (unchanged) |
| 1.21 | Arjuna said: O Achyuta (Krishna), please place my chariot between the two armies. | (unchanged) |
| 1.22 | Arjuna says: Let me observe those who are standing here, eager to fight. I want to see who I will have to fight against in this battle. | Let me observe those who are standing here, eager to fight. I want to see who I will have to fight against in this battle. |
| 1.23 | Arjuna says: I wish to observe those who have gathered here to fight, wishing to please the evil-minded son of Dhritarashtra (Duryodhana). | I wish to observe those who have gathered here to fight, wishing to please the evil-minded son of Dhritarashtra (Duryodhana). |
| 1.24 | Sanjaya said: O Dhritarashtra, having been addressed in this way by Arjuna (Gudakesha), Krishna (Hrishikesha) placed the magnificent chariot between the two armies. | Sanjaya said: O Bharata (Dhritarashtra), having been addressed in this way by Arjuna (Gudakesha), Krishna (Hrishikesha) placed the magnificent chariot between the two armies. |
| 1.25 | In the presence of Bhishma, Drona, and all the other kings, Krishna said: "Partha, look at all these Kurus gathered here." | In the presence of Bhishma, Drona, and all the other kings, Krishna said: O Partha (Arjuna), look at all these Kurus gathered here. |
| 1.26 | There, Arjuna saw fathers, grandfathers, teachers, maternal uncles, brothers, sons, grandsons, and friends standing in both armies. | (unchanged) |
| 1.27 | Arjuna, the son of Kunti, saw his fathers-in-law, well-wishers, and all his relatives standing in both armies. | (unchanged) |
| 1.28 | Overcome by deep compassion and sorrow, Arjuna said: "Krishna, seeing my own people gathered here, eager to fight..." | Overcome by deep compassion and sorrow, Arjuna said: O Krishna, seeing my own people gathered here, eager to fight... |
| 1.29 | Arjuna says: "My body is trembling, my hair is standing on end, my bow Gandiva is slipping from my hand, and my skin is burning." | My body is trembling, my hair is standing on end, my bow Gandiva is slipping from my hand, and my skin is burning. |
| 1.30 | Arjuna says: "I am unable to remain steady. My mind seems to be spinning, and I see only negative or unfavourable signs, O Krishna." | I am unable to remain steady. My mind seems to be spinning, and I see only negative or unfavourable signs, O Keshava (Krishna). |
| 1.31 | Arjuna says: "O Krishna, I see unfavourable signs, and I cannot see any good coming from killing my own relatives in this battle." | O Keshava (Krishna), I see unfavourable signs, and I cannot see any good coming from killing my own relatives in this battle. |
| 1.32 | Arjuna says: "O Krishna, I desire neither victory, nor kingdom, nor pleasures. What is the use of a kingdom, enjoyment, or even life itself?" | O Krishna, I desire neither victory, nor kingdom, nor pleasures. What is the use of a kingdom, enjoyment, or even life itself? |
| 1.33 | Arjuna says: "Those for whose sake we desire kingdom, enjoyment, and happiness are standing here on the battlefield, ready to sacrifice their lives and wealth." | Those for whose sake we desire kingdom, enjoyment, and happiness are standing here on the battlefield, ready to sacrifice their lives and wealth. |
| 1.34 | Arjuna says: "Teachers, fathers, sons, grandfathers, maternal uncles, fathers-in-law, grandsons, brothers-in-law, and other relatives are all standing here." | Teachers, fathers, sons, grandfathers, maternal uncles, fathers-in-law, grandsons, brothers-in-law, and other relatives are all standing here. |
| 1.35 | Arjuna says: "O Madhusudana (Krishna), I do not wish to kill these people, even if they attack me. Not even for the sovereignty of all three worlds, let alone for an earthly kingdom." | O Madhusudana (Krishna), I do not wish to kill these people, even if they attack me. Not even for the sovereignty of all three worlds, let alone for an earthly kingdom. |

## 8. Suspected extraction or source errors

The extraction is clean: the parser found every heading, and nothing was dropped
between paragraphs. The issues below are **in the document itself**. None was corrected
in the JSON.

1. **1.30 / 1.31 — duplicated half-verse.** "निमित्तानि च पश्यामि विपरीतानि केशव" is the
   second line of 1.30 *and* the first line of 1.31. This is objective: it can be seen
   in the document alone.
2. **1.29 / 1.30 — shifted by half a verse.** 1.28 and 1.31–1.41 follow the common
   (Gita Press-style) numbering. Under that numbering, 1.29 would be "सीदन्ति मम गात्राणि
   मुखं च परिशुष्यति। वेपथुश्च शरीरे मे रोमहर्षश्च जायते॥", and the document's 1.29/1.30
   are each half a verse later. The half-verse **"सीदन्ति मम गात्राणि मुखं च परिशुष्यति"
   appears nowhere in the document.** This finding comes from knowledge of standard
   editions, not from the document. Verify it against the edition you intend to cite.
3. **1.21 — first half missing.** Standard editions begin 1.21 with "हृषीकेशं तदा
   वाक्यमिदमाह महीपते।" before "अर्जुन उवाच।". The document has only the speaker line
   and the second half. Verify.
4. **1.22 and 1.28 — no verse-end number in the .docx.** Resolved: `॥ १.२२॥` and
   `॥ १.२८॥` were added after the owner confirmed them.

**Owner review (24 Nov 2026):** items 1–3 were kept as given. Open notes for the source
check are in the review list (A1–A3).
5. **1.17 — English meaning.** The document says "…were also present among the Pandava
   warriors", but the sentence continues into 1.18, where they *blow their conches*.
   The Hindi follows the Sanskrit ("…ने भी (अपने-अपने शंख बजाए)"), so the English and
   Hindi of 1.17 differ. The English was not changed.
6. **Finalized verses 1.36–1.41:** no extraction error found. 1.41 is identical to the
   repository's existing entry. Cosmetic only: 1.36's heading and Hindi label are in
   Hindi, where the other verses use English.

## 9. Source attribution issues

- `sources/sources.json` is **empty**, and the document names no source for its
  Sanskrit, transliteration, translations or commentary. **All 41 verses therefore have
  `source_attributions: []`.** Nothing was invented.
- Under guidelines §11, no verse can be approved until `sanskrit_text`, `hindi_meaning`
  and `english_meaning` are attributed to recorded sources with verified licences.
- The 35 generated Hindi meanings are **not** from any external translator, and must
  not be attributed to one. Guidelines §4 suggests recording the team's own translation
  as a source (e.g. a "Gitartha editorial translation" entry, with author and licence).
  That entry was not created, because its author and licence are the owner's decision.

## 10. JSON Schema and validator results

| Check | Result |
|---|---|
| JSON parses (UTF-8, no BOM, 2-space indent, real Devanagari, no `\u` escapes) | ✅ |
| `dart run tool/validate_gita_content.dart --chapter=1` (JSON Schema Draft 2020-12 + semantic checks), draft mode | ✅ **VALID**. 41/41 complete. 1 warning (chapter metadata incomplete), 1 info (6 of 47 verses missing) |
| Same, **strict** mode | ❌ 44 errors, all expected for unreviewed content: 42 × `NOT_APPROVED`, `MISSING_VERSES`, chapter `INCOMPLETE_CONTENT` |
| Ids `chapter_01_verse_001` … `041`, references `1.1` … `1.41` | ✅ consistent with `verse_number` |
| `source_attributions` structure | ✅ (empty arrays) |
| No extra properties; all required keys present; no leading or trailing whitespace | ✅ |
| `flutter test` (the whole project) | ✅ 341 passed. Four content tests that pinned the old one-verse snapshot were updated to the new contents |

## 11. Comparison with the finalized format (1.36–1.41)

| Aspect | 1.1–1.35 after conversion | Same as 36–41? |
|---|---|---|
| Field set and order | identical keys and order | ✅ |
| Sanskrit layout | half-verses on separate lines, `॥ १.N॥` ending on every verse | ✅ |
| Transliteration | IAST, same punctuation and casing rules | ✅ |
| Hindi meaning | vocative first, epithets and terms glossed in parentheses | ✅ (generated) |
| English meaning | direct translation, no narrator framing | ✅ |
| Context / life lesson / spiritual meaning | document wording; paragraphs, emphasis and spelling aligned | ✅ in format. **Shorter than 36–41** (typically 1–3 paragraphs against 4–6). Not padded (guidelines §9) |
| Reflection question | one question, specific to the verse | ✅ (one of 1.34's adds a follow-up "For example…" question) |
| Life lessons and spiritual meanings verse-specific | yes, in the document. None repeated | ✅ |

Not changed: 1.36–1.41 are byte-for-byte the document's text. The only additions are
`index_title` (1.36–1.40) and `index_summary` (1.36–1.41).
