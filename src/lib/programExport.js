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
  else if (ex.bars) suffix += ` [${ex.bars.name} ${ex.bars.weight_kg}kg]`
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
  lines.push('Mon programme est-il aligné avec mes objectifs et mes contraintes ? Identifie les éventuels trous (groupes musculaires sous-volume, déséquilibres, surcharge), les risques (blessures potentielles vu mon profil), et les opportunités d\'optimisation. Sois critique mais constructif.')
  lines.push('')

  return lines.join('\n')
}
