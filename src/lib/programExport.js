const DAY_NAMES = {
  1: 'Lundi',
  2: 'Mardi',
  3: 'Mercredi',
  4: 'Jeudi',
  5: 'Vendredi',
  6: 'Samedi',
  0: 'Dimanche',
}

const SECTION_LABELS = {
  rehab:    'Échauffement & rehab',
  main:     'Bloc principal',
  cooldown: 'Cooldown',
  mobility: 'Mobilité',
}

const SECTION_ORDER = ['rehab', 'main', 'cooldown', 'mobility']

function fmtSets(ex) {
  const sets = ex.sets_target
  const reps = ex.reps_target
  let suffix = ''
  if (ex.is_per_side) suffix = ' par côté'
  if (ex.is_bodyweight) suffix += ' [bodyweight]'
  else if (ex.bars) suffix += ` [équipement : ${ex.bars.name} (tare ${ex.bars.weight_kg}kg) + plaques chargées progressivement]`
  return `${sets}×${reps}${suffix}`
}

function exerciseLines(ex) {
  const out = [`- **${ex.name}** — ${fmtSets(ex)}`]
  if (ex.notes) out.push(`  - ${ex.notes}`)
  return out
}

function cardioLines(block) {
  const out = [`- **${block.name}** — ${block.duration_minutes} min`]
  if (block.notes) out.push(`  - ${block.notes}`)
  return out
}

export function buildMarkdownExport({ profileData, programDays, exercises, cardioBlocks, programName }) {
  const lines = []
  lines.push(`# Programme GymLog — analyse IA`)
  lines.push('')
  if (programName) {
    lines.push(`*Programme : ${programName}*`)
    lines.push('')
  }

  lines.push('## Profil')
  lines.push('')
  lines.push(profileData?.profil?.trim() || '_Non renseigné — à compléter dans les Réglages._')
  lines.push('')

  lines.push('## Objectifs')
  lines.push('')
  lines.push(profileData?.objectifs?.trim() || '_Non renseignés — à compléter dans les Réglages._')
  lines.push('')

  lines.push('## Note importante sur les charges et la progression')
  lines.push('')
  lines.push('**Les valeurs en kg listées à côté du matériel (ex: "Barre droite 10kg", "Haltère 2.5kg") correspondent uniquement à la *tare* — c\'est-à-dire le poids du matériel à vide.** Ce N\'EST PAS la charge de travail. Les disques sont chargés progressivement à chaque séance via une **règle de double progression** :')
  lines.push('')
  lines.push('- L\'utilisateur travaille en RIR 2-3 (2 à 3 reps en réserve avant l\'échec)')
  lines.push('- Quand il atteint le top de la plage de reps cible (ex: 12 sur 10-12) avec RIR ≥ 2, il ajoute **+2kg minimum** à la séance suivante')
  lines.push('- Disques disponibles : 20 / 15 / 10 / 5 / 2.5 / 1.25 / 1 kg')
  lines.push('')
  lines.push('Donc **ne juge pas l\'intensité du programme à partir de ces valeurs de tare** — la surcharge progressive réelle est appliquée. Concentre-toi sur la structure, le volume, la sélection des exercices, l\'équilibre push/pull, et la pertinence vis-à-vis du profil et des objectifs.')
  lines.push('')
  lines.push('## Programme hebdomadaire')
  lines.push('')

  const sortedDays = [...programDays].sort((a, b) => {
    const ka = a.day_of_week === 0 ? 7 : a.day_of_week
    const kb = b.day_of_week === 0 ? 7 : b.day_of_week
    return ka - kb
  })

  for (const day of sortedDays) {
    const dayName = DAY_NAMES[day.day_of_week] ?? '?'
    lines.push(`### ${dayName} — ${day.name} (${day.type})`)
    lines.push('')

    if (day.notes) {
      lines.push(`*${day.notes}*`)
      lines.push('')
    }

    if (day.type === 'rest' && !exercises.some(e => e.program_day_id === day.id)) {
      lines.push('_Repos complet._')
      lines.push('')
      continue
    }

    const dayExercises = exercises
      .filter(e => e.program_day_id === day.id)
      .sort((a, b) => a.order_index - b.order_index)

    for (const section of SECTION_ORDER) {
      const inSection = dayExercises.filter(e => e.section === section)
      if (!inSection.length) continue
      lines.push(`#### ${SECTION_LABELS[section] ?? section}`)
      for (const ex of inSection) {
        for (const l of exerciseLines(ex)) lines.push(l)
      }
      lines.push('')
    }

    const dayCardio = cardioBlocks
      .filter(b => b.program_day_id === day.id)
      .sort((a, b) => a.order_index - b.order_index)

    if (dayCardio.length) {
      lines.push(`#### Cardio`)
      for (const block of dayCardio) {
        for (const l of cardioLines(block)) lines.push(l)
      }
      lines.push('')
    }
  }

  lines.push('## Question pour l\'IA')
  lines.push('')
  lines.push('Avis **objectif et scientifique** sur ce programme par rapport à mon profil et mes objectifs.')
  lines.push('')
  lines.push('**Posture attendue : coach S&C exigeant, pas copain qui rassure.** Zéro complaisance. Pas de "globalement c\'est bien mais…", pas de compliments de politesse, pas d\'enrobage. Si une partie du programme est mal foutue, sous-optimale, ou carrément contre-indiquée pour mon profil — **dis-le franchement**. Je préfère encaisser une critique nette maintenant que découvrir une blessure ou 6 mois de stagnation après. Tes patients/athlètes les plus avancés ont gagné parce qu\'on leur a dit la vérité, pas parce qu\'on les a flattés.')
  lines.push('')
  lines.push('Réponse efficace, dense, actionnable. Pas de paragraphes d\'introduction ni de conclusion motivationnelle.')
  lines.push('')
  lines.push('À couvrir :')
  lines.push('- **Contre-indications** éventuelles vu mon profil (épaule, lombaires, poids, récup…) — ce qui est dangereux pour MOI spécifiquement')
  lines.push('- **Trous** : groupes musculaires sous-volume, déséquilibres push/pull, surcharge')
  lines.push('- **Améliorations** classées par impact attendu (high / medium / low)')
  lines.push('- Identifie explicitement les **3 changements à plus fort effet de levier**, avec justification scientifique courte (étude / méca physiologique)')
  lines.push('')
  lines.push('Contrainte : le programme doit rester faisable — je n\'ai pas toute la journée à consacrer à l\'entraînement, donc pas de "ajoute 2 séances par semaine" ou "double le volume". Suggestions à coût horaire ≈ constant.')
  lines.push('')

  return lines.join('\n')
}
